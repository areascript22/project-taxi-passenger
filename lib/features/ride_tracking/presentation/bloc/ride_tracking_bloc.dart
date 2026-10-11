import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:meta/meta.dart';
import 'package:passenger_app/core/error/errors.dart';
import '../../domain/entity/ride_entity.dart';
import '../../domain/repository/ride_tracking_repository.dart';

part 'ride_tracking_event.dart';
part 'ride_tracking_state.dart';

// Debajo de este umbral se considera "llegó" para efectos de distancia/ETA/
// progreso, aunque el status todavía no haya cambiado a driverArrived (el
// conductor lo confirma manualmente con un botón en su app).
const _kArrivalThresholdMeters = 50.0;
// Referencia de progreso mientras la carrera no trae driverInitialDistanceMeters.
// La distancia inicial la fija el SERVIDOR al asignar el conductor (junto con
// su ubicación), así que esto solo cubre una carrera sin ese dato -- evita una
// barra en 0/1 incorrecta.
const _kFallbackInitialDistanceMeters = 5000.0;
// Piso del denominador al calcular progreso, para no dividir por (casi) 0
// en el caso borde de que el conductor ya estuviera pegado al punto de
// recogida en el momento de aceptar.
const _kMinInitialDistanceMeters = 10.0;
// Velocidad urbana asumida para estimar el tiempo de llegada a partir de la
// distancia en línea recta (no hay ruteo real por calles/tráfico).
const _kAverageSpeedKmh = 25.0;

// Statuses en los que, según el conductor, ya llegó -- fuerza progress a 0
// sin importar ruido del GPS.
const _arrivedStatuses = {
  RideTrackingStatus.driverArrived,
  RideTrackingStatus.tripStarted,
};

class RideTrackingBloc extends Bloc<RideTrackingEvent, RideTrackingState> {
  final RideTrackingRepository repository;
  StreamSubscription<RideEntity>? _subscription;

  RideTrackingBloc({required this.repository})
    : super(const RideTrackingState()) {
    on<StartRideTracking>(_onStart);
    on<RideUpdated>(_onRideUpdated);
    on<StopRideTracking>(_onStop);
    on<CancelRideRequested>(_onCancelRequested);
    on<ConfirmOnTheWayRequested>(_onConfirmOnTheWayRequested);
  }

  Future<void> _onStart(
    StartRideTracking event,
    Emitter<RideTrackingState> emit,
  ) async {
    debugPrint(
      'ChatFlowDebug | RideTrackingBloc._onStart -> passengerId=${event.passengerId}',
    );
    emit(state.copyWith(status: RideTrackingStatus.connecting));

    await _subscription?.cancel();

    _subscription = repository
        .watchRideTrack(passengerId: event.passengerId)
        .listen((ride) {
          add(RideUpdated(ride));
        });
  }

  void _onRideUpdated(
    RideUpdated event,
    Emitter<RideTrackingState> emit,
  ) {
    final ride = event.ride;
    debugPrint("Ride update event called ; ${ride}");
    debugPrint(
      'ChatFlowDebug | RideTrackingBloc._onRideUpdated -> '
      'rideId=${ride.rideId} status=${ride.rideStatus}',
    );

    final distanceMeters = _distanceToPickup(ride);
    final progress = _computeProgress(ride: ride, distanceMeters: distanceMeters);
    final etaMinutes = _computeEtaMinutes(distanceMeters);

    emit(
      state.copyWith(
        status: ride.rideStatus,
        ride: ride,
        distanceMeters: distanceMeters,
        etaMinutes: etaMinutes,
        progress: progress,
      ),
    );
  }

  Future<void> _onStop(StopRideTracking event, Emitter<RideTrackingState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = null;
    emit(const RideTrackingState());
  }

  Future<void> _onCancelRequested(
    CancelRideRequested event,
    Emitter<RideTrackingState> emit,
  ) async {
    emit(state.copyWith(isCancelling: true));

    final result = await repository.cancelRide(passengerId: event.passengerId);

    result.fold(
      (failure) => emit(
        state.copyWith(isCancelling: false, errorCode: failure.code),
      ),
      // El stream de watchRideTrack ya recibirá status == cancelled y
      // actualizará el estado; aquí solo apagamos el loading.
      (_) => emit(state.copyWith(isCancelling: false)),
    );
  }

  Future<void> _onConfirmOnTheWayRequested(
    ConfirmOnTheWayRequested event,
    Emitter<RideTrackingState> emit,
  ) async {
    final result = await repository.confirmOnTheWay(
      passengerId: event.passengerId,
    );

    result.fold(
      (failure) => emit(state.copyWith(errorCode: failure.code)),
      // El stream de watchRideTrack ya recibirá status == tripStarted.
      (_) {},
    );
  }

  // Distancia en línea recta (metros) entre la ubicación actual del
  // conductor y el punto de recogida elegido por el pasajero. Null si
  // todavía no se conoce alguno de los dos puntos.
  double? _distanceToPickup(RideEntity ride) {
    final driverLat = ride.driver.latitude;
    final driverLng = ride.driver.longitude;
    final pickupLat = ride.pickupLatitude;
    final pickupLng = ride.pickupLongitude;

    if (driverLat == null ||
        driverLng == null ||
        pickupLat == null ||
        pickupLng == null) {
      return null;
    }

    return Geolocator.distanceBetween(driverLat, driverLng, pickupLat, pickupLng);
  }

  // 1 = conductor recién asignado, 0 = llegó. Siempre acotado a [0, 1] --
  // si el conductor se aleja (desvío, tráfico) el valor nunca se sale de
  // rango, solo se topa en 1.
  double? _computeProgress({
    required RideEntity ride,
    required double? distanceMeters,
  }) {
    if (distanceMeters == null) return null;

    if (_arrivedStatuses.contains(ride.rideStatus)) return 0.0;
    if (distanceMeters <= _kArrivalThresholdMeters) return 0.0;

    final initialDistance =
        ride.driverInitialDistanceMeters ?? _kFallbackInitialDistanceMeters;
    final safeInitialDistance =
        initialDistance < _kMinInitialDistanceMeters
            ? _kMinInitialDistanceMeters
            : initialDistance;

    return (distanceMeters / safeInitialDistance).clamp(0.0, 1.0);
  }

  // Estimación simple por velocidad promedio urbana (no hay ruteo real por
  // calles/tráfico). Mínimo 1 minuto mientras no haya llegado.
  int? _computeEtaMinutes(double? distanceMeters) {
    if (distanceMeters == null) return null;
    if (distanceMeters <= _kArrivalThresholdMeters) return 0;

    final distanceKm = distanceMeters / 1000;
    final etaMinutes = (distanceKm / _kAverageSpeedKmh * 60).ceil();
    return etaMinutes < 1 ? 1 : etaMinutes;
  }
}

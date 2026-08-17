import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:meta/meta.dart';
import '../../domain/entity/ride_entity.dart';
import '../../domain/repository/ride_tracking_repository.dart';

part 'ride_tracking_event.dart';
part 'ride_tracking_state.dart';

// Debajo de este umbral se considera "llegó" para efectos de distancia/ETA/
// progreso, aunque el status todavía no haya cambiado a driverArrived (el
// conductor lo confirma manualmente con un botón en su app).
const _kArrivalThresholdMeters = 50.0;
// Referencia de progreso mientras driverInitialDistanceMeters todavía no se
// terminó de escribir en Firebase (ventana de milisegundos entre el primer
// RideUpdated y que se confirme la transacción) -- evita una barra en 0/1
// incorrecta por un instante.
const _kFallbackInitialDistanceMeters = 5000.0;
// Piso del denominador al calcular progreso, para no dividir por (casi) 0
// en el caso borde de que el conductor ya estuviera pegado al punto de
// recogida en el momento de aceptar.
const _kMinInitialDistanceMeters = 10.0;
// Velocidad urbana asumida para estimar el tiempo de llegada a partir de la
// distancia en línea recta (no hay ruteo real por calles/tráfico).
const _kAverageSpeedKmh = 25.0;

// Statuses en los que todavía tiene sentido capturar la distancia inicial
// del conductor (antes de que llegue).
const _capturableInitialDistanceStatuses = {
  RideTrackingStatus.driverAssigned,
  RideTrackingStatus.driverArriving,
};

// Statuses en los que, según el conductor, ya llegó -- fuerza progress a 0
// sin importar ruido del GPS.
const _arrivedStatuses = {
  RideTrackingStatus.driverArrived,
  RideTrackingStatus.tripStarted,
};

class RideTrackingBloc extends Bloc<RideTrackingEvent, RideTrackingState> {
  final RideTrackingRepository repository;
  StreamSubscription<RideEntity>? _subscription;
  String? _passengerId;

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
    emit(state.copyWith(status: RideTrackingStatus.connecting));

    await _subscription?.cancel();
    _passengerId = event.passengerId;

    _subscription = repository
        .watchRideTrack(passengerId: event.passengerId)
        .listen((ride) {
          add(RideUpdated(ride));
        });
  }

  Future<void> _onRideUpdated(
    RideUpdated event,
    Emitter<RideTrackingState> emit,
  ) async {
    final ride = event.ride;
    debugPrint("Ride update event called ; ${ride}");

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

    await _maybeRecordInitialDistance(ride: ride, distanceMeters: distanceMeters);
  }

  Future<void> _onStop(StopRideTracking event, Emitter<RideTrackingState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = null;
    _passengerId = null;
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
        state.copyWith(isCancelling: false, errorMessage: failure.message),
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
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
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

  // Escribe driverInitialDistanceMeters en Firebase la primera vez que se
  // detecta (solo si todavía no existe) -- referencia fija que sobrevive a
  // que el pasajero cierre y reabra la app (ver RideTrackingRepository).
  Future<void> _maybeRecordInitialDistance({
    required RideEntity ride,
    required double? distanceMeters,
  }) async {
    final passengerId = _passengerId;
    if (passengerId == null || distanceMeters == null) return;
    if (ride.driverInitialDistanceMeters != null) return;
    if (!_capturableInitialDistanceStatuses.contains(ride.rideStatus)) return;

    // No hace falta manejar el resultado acá: si falla, el próximo
    // RideUpdated (5s después, con la siguiente ubicación del conductor) lo
    // vuelve a intentar solo porque driverInitialDistanceMeters sigue null.
    await repository.recordInitialDriverDistance(
      passengerId: passengerId,
      distanceMeters: distanceMeters,
    );
  }
}

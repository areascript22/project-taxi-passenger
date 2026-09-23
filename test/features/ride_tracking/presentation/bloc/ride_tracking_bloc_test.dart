import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/core/error/errors.dart';
import 'package:passenger_app/features/ride_tracking/domain/entity/ride_entity.dart';
import 'package:passenger_app/features/ride_tracking/domain/repository/ride_tracking_repository.dart';
import 'package:passenger_app/features/ride_tracking/presentation/bloc/ride_tracking_bloc.dart';

class _MockRideTrackingRepository extends Mock
    implements RideTrackingRepository {}

RideEntity _ride({
  required RideTrackingStatus status,
  double? driverLat,
  double? driverLng,
  double? pickupLat,
  double? pickupLng,
  double? initialDistance,
}) {
  return RideEntity(
    driver: DriverEntity(
      name: 'Juan',
      photo: '',
      latitude: driverLat,
      longitude: driverLng,
    ),
    rideStatus: status,
    pickupLatitude: pickupLat,
    pickupLongitude: pickupLng,
    driverInitialDistanceMeters: initialDistance,
  );
}

void main() {
  late _MockRideTrackingRepository repository;

  setUp(() {
    repository = _MockRideTrackingRepository();
  });

  RideTrackingBloc buildBloc() => RideTrackingBloc(repository: repository);

  test('el estado inicial es RideTrackingStatus.initial', () {
    expect(buildBloc().state.status, RideTrackingStatus.initial);
  });

  group('StartRideTracking', () {
    blocTest<RideTrackingBloc, RideTrackingState>(
      'emite connecting y luego procesa cada evento del stream como RideUpdated',
      build: () {
        when(
          () => repository.watchRideTrack(
            passengerId: any(named: 'passengerId'),
          ),
        ).thenAnswer(
          (_) => Stream.value(
            _ride(status: RideTrackingStatus.driverAssigned),
          ),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(StartRideTracking(passengerId: 'p1')),
      expect: () => [
        isA<RideTrackingState>().having(
          (s) => s.status,
          'status',
          RideTrackingStatus.connecting,
        ),
        isA<RideTrackingState>().having(
          (s) => s.status,
          'status',
          RideTrackingStatus.driverAssigned,
        ),
      ],
    );

    blocTest<RideTrackingBloc, RideTrackingState>(
      'cancela la suscripción anterior si se inicia de nuevo con otro passengerId',
      build: () {
        when(
          () => repository.watchRideTrack(passengerId: 'p1'),
        ).thenAnswer((_) => const Stream.empty());
        when(
          () => repository.watchRideTrack(passengerId: 'p2'),
        ).thenAnswer(
          (_) => Stream.value(
            _ride(status: RideTrackingStatus.driverAssigned),
          ),
        );
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(StartRideTracking(passengerId: 'p1'));
        await Future.delayed(Duration.zero);
        bloc.add(StartRideTracking(passengerId: 'p2'));
      },
      verify: (_) {
        verify(() => repository.watchRideTrack(passengerId: 'p1')).called(1);
        verify(() => repository.watchRideTrack(passengerId: 'p2')).called(1);
      },
    );
  });

  group('RideUpdated: distancia, progreso y ETA', () {
    blocTest<RideTrackingBloc, RideTrackingState>(
      'distancia/progreso/ETA quedan null si falta alguna coordenada',
      build: buildBloc,
      act: (bloc) => bloc.add(
        RideUpdated(_ride(status: RideTrackingStatus.driverAssigned)),
      ),
      expect: () => [
        isA<RideTrackingState>()
            .having((s) => s.distanceMeters, 'distanceMeters', isNull)
            .having((s) => s.progress, 'progress', isNull)
            .having((s) => s.etaMinutes, 'etaMinutes', isNull),
      ],
    );

    blocTest<RideTrackingBloc, RideTrackingState>(
      'calcula distancia/progreso/ETA cuando ambas coordenadas están presentes',
      build: () {
        when(
          () => repository.recordInitialDriverDistance(
            passengerId: any(named: 'passengerId'),
            distanceMeters: any(named: 'distanceMeters'),
          ),
        ).thenAnswer((_) async => const Right(unit));
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        RideUpdated(
          _ride(
            status: RideTrackingStatus.driverAssigned,
            driverLat: 0,
            driverLng: 0,
            pickupLat: 0,
            pickupLng: 0.1,
            initialDistance: 11000,
          ),
        ),
      ),
      expect: () => [
        isA<RideTrackingState>()
            .having(
              (s) => s.distanceMeters! > 0,
              'distanceMeters > 0',
              isTrue,
            )
            .having((s) => s.progress, 'progress', isNotNull)
            .having((s) => s.etaMinutes! >= 1, 'etaMinutes >= 1', isTrue),
      ],
    );

    blocTest<RideTrackingBloc, RideTrackingState>(
      'progreso y ETA son 0 cuando la distancia está bajo el umbral de llegada (50m)',
      build: buildBloc,
      act: (bloc) => bloc.add(
        RideUpdated(
          _ride(
            status: RideTrackingStatus.driverArriving,
            driverLat: 0,
            driverLng: 0,
            pickupLat: 0,
            pickupLng: 0.0001, // ~11m
          ),
        ),
      ),
      expect: () => [
        isA<RideTrackingState>()
            .having((s) => s.progress, 'progress', 0.0)
            .having((s) => s.etaMinutes, 'etaMinutes', 0),
      ],
    );

    blocTest<RideTrackingBloc, RideTrackingState>(
      'progreso fuerza a 0 si el status ya es driverArrived, sin importar la distancia',
      build: buildBloc,
      act: (bloc) => bloc.add(
        RideUpdated(
          _ride(
            status: RideTrackingStatus.driverArrived,
            driverLat: 0,
            driverLng: 0,
            pickupLat: 0,
            pickupLng: 5,
          ),
        ),
      ),
      expect: () => [
        isA<RideTrackingState>().having((s) => s.progress, 'progress', 0.0),
      ],
    );

    blocTest<RideTrackingBloc, RideTrackingState>(
      'progreso queda acotado a 1.0 aunque la distancia inicial sea menor al piso mínimo (10m)',
      build: buildBloc,
      act: (bloc) => bloc.add(
        RideUpdated(
          _ride(
            status: RideTrackingStatus.driverAssigned,
            driverLat: 0,
            driverLng: 0,
            pickupLat: 0,
            pickupLng: 0.01, // ~1113m, mayor al umbral de llegada
            initialDistance: 5, // por debajo de _kMinInitialDistanceMeters
          ),
        ),
      ),
      expect: () => [
        isA<RideTrackingState>().having((s) => s.progress, 'progress', 1.0),
      ],
    );

    blocTest<RideTrackingBloc, RideTrackingState>(
      'graba la distancia inicial solo la primera vez (driverInitialDistanceMeters null)',
      build: () {
        when(
          () => repository.watchRideTrack(
            passengerId: any(named: 'passengerId'),
          ),
        ).thenAnswer((_) => const Stream.empty());
        when(
          () => repository.recordInitialDriverDistance(
            passengerId: any(named: 'passengerId'),
            distanceMeters: any(named: 'distanceMeters'),
          ),
        ).thenAnswer((_) async => const Right(unit));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(StartRideTracking(passengerId: 'p1'));
        bloc.add(
          RideUpdated(
            _ride(
              status: RideTrackingStatus.driverAssigned,
              driverLat: 0,
              driverLng: 0,
              pickupLat: 0,
              pickupLng: 1,
            ),
          ),
        );
      },
      verify: (_) {
        verify(
          () => repository.recordInitialDriverDistance(
            passengerId: 'p1',
            distanceMeters: any(named: 'distanceMeters'),
          ),
        ).called(1);
      },
    );

    blocTest<RideTrackingBloc, RideTrackingState>(
      'no vuelve a grabar la distancia inicial si el ride ya trae una',
      build: () {
        when(
          () => repository.watchRideTrack(
            passengerId: any(named: 'passengerId'),
          ),
        ).thenAnswer((_) => const Stream.empty());
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(StartRideTracking(passengerId: 'p1'));
        bloc.add(
          RideUpdated(
            _ride(
              status: RideTrackingStatus.driverAssigned,
              driverLat: 0,
              driverLng: 0,
              pickupLat: 0,
              pickupLng: 1,
              initialDistance: 5000,
            ),
          ),
        );
      },
      verify: (_) {
        verifyNever(
          () => repository.recordInitialDriverDistance(
            passengerId: any(named: 'passengerId'),
            distanceMeters: any(named: 'distanceMeters'),
          ),
        );
      },
    );

    blocTest<RideTrackingBloc, RideTrackingState>(
      'no graba distancia inicial en estados no capturables (ej. tripStarted)',
      build: () {
        when(
          () => repository.watchRideTrack(
            passengerId: any(named: 'passengerId'),
          ),
        ).thenAnswer((_) => const Stream.empty());
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(StartRideTracking(passengerId: 'p1'));
        bloc.add(
          RideUpdated(
            _ride(
              status: RideTrackingStatus.tripStarted,
              driverLat: 0,
              driverLng: 0,
              pickupLat: 0,
              pickupLng: 1,
            ),
          ),
        );
      },
      verify: (_) {
        verifyNever(
          () => repository.recordInitialDriverDistance(
            passengerId: any(named: 'passengerId'),
            distanceMeters: any(named: 'distanceMeters'),
          ),
        );
      },
    );
  });

  group('StopRideTracking', () {
    blocTest<RideTrackingBloc, RideTrackingState>(
      'cancela la suscripción y resetea el estado a RideTrackingState() por defecto',
      build: () {
        final controller = StreamController<RideEntity>();
        addTearDown(controller.close);
        when(
          () => repository.watchRideTrack(
            passengerId: any(named: 'passengerId'),
          ),
        ).thenAnswer((_) => controller.stream);
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(StartRideTracking(passengerId: 'p1'));
        await Future.delayed(Duration.zero);
        bloc.add(StopRideTracking());
      },
      skip: 1,
      expect: () => [
        predicate<RideTrackingState>(
          (s) => s.status == RideTrackingStatus.initial && s.ride == null,
        ),
      ],
    );
  });

  group('CancelRideRequested', () {
    blocTest<RideTrackingBloc, RideTrackingState>(
      'emite isCancelling true y luego false al confirmar la cancelación',
      build: () {
        when(
          () => repository.cancelRide(passengerId: any(named: 'passengerId')),
        ).thenAnswer((_) async => const Right(unit));
        return buildBloc();
      },
      act: (bloc) => bloc.add(CancelRideRequested(passengerId: 'p1')),
      expect: () => [
        isA<RideTrackingState>().having(
          (s) => s.isCancelling,
          'isCancelling',
          isTrue,
        ),
        isA<RideTrackingState>().having(
          (s) => s.isCancelling,
          'isCancelling',
          isFalse,
        ),
      ],
    );

    blocTest<RideTrackingBloc, RideTrackingState>(
      'emite errorMessage y apaga isCancelling si el repo falla',
      build: () {
        when(
          () => repository.cancelRide(passengerId: any(named: 'passengerId')),
        ).thenAnswer((_) async => Left(Failure(message: 'no se pudo cancelar')));
        return buildBloc();
      },
      act: (bloc) => bloc.add(CancelRideRequested(passengerId: 'p1')),
      expect: () => [
        isA<RideTrackingState>().having(
          (s) => s.isCancelling,
          'isCancelling',
          isTrue,
        ),
        isA<RideTrackingState>()
            .having((s) => s.isCancelling, 'isCancelling', isFalse)
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              'no se pudo cancelar',
            ),
      ],
    );
  });

  group('ConfirmOnTheWayRequested', () {
    blocTest<RideTrackingBloc, RideTrackingState>(
      'no emite nada adicional si el repo confirma exitosamente',
      build: () {
        when(
          () => repository.confirmOnTheWay(
            passengerId: any(named: 'passengerId'),
          ),
        ).thenAnswer((_) async => const Right(unit));
        return buildBloc();
      },
      act: (bloc) => bloc.add(ConfirmOnTheWayRequested(passengerId: 'p1')),
      expect: () => <RideTrackingState>[],
    );

    blocTest<RideTrackingBloc, RideTrackingState>(
      'emite errorMessage si el repo falla',
      build: () {
        when(
          () => repository.confirmOnTheWay(
            passengerId: any(named: 'passengerId'),
          ),
        ).thenAnswer((_) async => Left(Failure(message: 'error de red')));
        return buildBloc();
      },
      act: (bloc) => bloc.add(ConfirmOnTheWayRequested(passengerId: 'p1')),
      expect: () => [
        isA<RideTrackingState>().having(
          (s) => s.errorMessage,
          'errorMessage',
          'error de red',
        ),
      ],
    );
  });
}

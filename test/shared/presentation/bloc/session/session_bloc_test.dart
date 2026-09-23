import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/core/error/errors.dart';
import 'package:passenger_app/features/passenger_profile/domain/entity/passenger_entity.dart';
import 'package:passenger_app/features/passenger_profile/domain/repository/passenger_profile_repository.dart';
import 'package:passenger_app/features/ride_tracking/domain/entity/ride_entity.dart';
import 'package:passenger_app/features/ride_tracking/domain/repository/ride_tracking_repository.dart';
import 'package:passenger_app/features/ride_tracking/presentation/bloc/ride_tracking_bloc.dart';
import 'package:passenger_app/shared/domain/entity/user_entity.dart';
import 'package:passenger_app/shared/domain/repository/session_repository.dart';
import 'package:passenger_app/shared/notifications/service/push_notifications_service.dart';
import 'package:passenger_app/shared/presentation/bloc/session/session_bloc.dart';

class _MockSessionRepository extends Mock implements SessionRepository {}

class _MockRideTrackingRepository extends Mock
    implements RideTrackingRepository {}

class _MockPassengerProfileRepository extends Mock
    implements PassengerProfileRepository {}

class _MockPushNotificationsService extends Mock
    implements PushNotificationsService {}

void main() {
  late _MockSessionRepository sessionRepository;
  late _MockRideTrackingRepository rideTrackingRepository;
  late _MockPassengerProfileRepository passengerProfileRepository;
  late _MockPushNotificationsService pushNotificationsService;
  final user = UserEntity(id: 'u1', email: 'a@a.com');
  final passenger = PassengerEntity(
    id: 'u1',
    firstName: 'Ana',
    lastName: 'G',
    email: 'a@a.com',
  );

  setUp(() {
    sessionRepository = _MockSessionRepository();
    rideTrackingRepository = _MockRideTrackingRepository();
    passengerProfileRepository = _MockPassengerProfileRepository();
    pushNotificationsService = _MockPushNotificationsService();

    // Comportamiento por defecto del registro de push token
    // (fire-and-forget en _onCheckRequested) para no romper tests que no
    // lo verifican explícitamente.
    when(
      () => pushNotificationsService.getToken(),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => pushNotificationsService.onTokenRefresh,
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => passengerProfileRepository.updateFcmToken(
        passengerId: any(named: 'passengerId'),
        token: any(named: 'token'),
      ),
    ).thenAnswer((_) async => const Right(unit));
  });

  SessionBloc buildBloc() => SessionBloc(
    sessionRepository: sessionRepository,
    rideTrackingRepository: rideTrackingRepository,
    passengerProfileRepository: passengerProfileRepository,
    pushNotificationsService: pushNotificationsService,
  );

  test('el estado inicial es SessionUnknown', () {
    expect(buildBloc().state, isA<SessionUnknown>());
  });

  group('SessionCheckRequested', () {
    blocTest<SessionBloc, SessionState>(
      'emite SessionUnauthenticated si no hay usuario autenticado',
      build: () {
        when(() => sessionRepository.isUserAuthenticated()).thenAnswer(
          (_) async => Left(Failure(message: 'no session')),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(SessionCheckRequested()),
      expect: () => [isA<SessionUnauthenticated>()],
      verify: (_) {
        verifyNever(
          () => passengerProfileRepository.getPassenger(
            passengerId: any(named: 'passengerId'),
          ),
        );
      },
    );

    blocTest<SessionBloc, SessionState>(
      'emite SessionCheckFailed si falla la consulta de pasajero',
      build: () {
        when(
          () => sessionRepository.isUserAuthenticated(),
        ).thenAnswer((_) async => Right(user));
        when(
          () => passengerProfileRepository.getPassenger(
            passengerId: any(named: 'passengerId'),
          ),
        ).thenAnswer((_) async => Left(Failure(message: 'network')));
        return buildBloc();
      },
      act: (bloc) => bloc.add(SessionCheckRequested()),
      expect: () => [
        isA<SessionCheckFailed>().having((s) => s.user, 'user', user),
      ],
    );

    blocTest<SessionBloc, SessionState>(
      'emite SessionOnboardingRequired si el usuario no tiene datos de pasajero (Right(null))',
      build: () {
        when(
          () => sessionRepository.isUserAuthenticated(),
        ).thenAnswer((_) async => Right(user));
        when(
          () => passengerProfileRepository.getPassenger(
            passengerId: any(named: 'passengerId'),
          ),
        ).thenAnswer((_) async => const Right(null));
        return buildBloc();
      },
      act: (bloc) => bloc.add(SessionCheckRequested()),
      expect: () => [
        isA<SessionOnboardingRequired>().having((s) => s.user, 'user', user),
      ],
    );

    blocTest<SessionBloc, SessionState>(
      'emite SessionAuthenticated con activeRide null si no hay viaje activo',
      build: () {
        when(
          () => sessionRepository.isUserAuthenticated(),
        ).thenAnswer((_) async => Right(user));
        when(
          () => passengerProfileRepository.getPassenger(
            passengerId: any(named: 'passengerId'),
          ),
        ).thenAnswer((_) async => Right(passenger));
        when(
          () => rideTrackingRepository.getActiveRide(),
        ).thenAnswer((_) async => const Right(null));
        return buildBloc();
      },
      act: (bloc) => bloc.add(SessionCheckRequested()),
      expect: () => [
        isA<SessionAuthenticated>()
            .having((s) => s.user, 'user', user)
            .having((s) => s.activeRide, 'activeRide', isNull),
      ],
    );

    blocTest<SessionBloc, SessionState>(
      'emite SessionAuthenticated con el activeRide devuelto por el repo',
      build: () {
        final ride = RideEntity(
          driver: DriverEntity(name: 'Juan', photo: ''),
          rideStatus: RideTrackingStatus.driverAssigned,
        );
        when(
          () => sessionRepository.isUserAuthenticated(),
        ).thenAnswer((_) async => Right(user));
        when(
          () => passengerProfileRepository.getPassenger(
            passengerId: any(named: 'passengerId'),
          ),
        ).thenAnswer((_) async => Right(passenger));
        when(
          () => rideTrackingRepository.getActiveRide(),
        ).thenAnswer((_) async => Right(ride));
        return buildBloc();
      },
      act: (bloc) => bloc.add(SessionCheckRequested()),
      expect: () => [
        isA<SessionAuthenticated>().having(
          (s) => s.activeRide?.rideStatus,
          'activeRide.status',
          RideTrackingStatus.driverAssigned,
        ),
      ],
    );

    blocTest<SessionBloc, SessionState>(
      'activeRide null cuando el repo de ride falla (fold a null)',
      build: () {
        when(
          () => sessionRepository.isUserAuthenticated(),
        ).thenAnswer((_) async => Right(user));
        when(
          () => passengerProfileRepository.getPassenger(
            passengerId: any(named: 'passengerId'),
          ),
        ).thenAnswer((_) async => Right(passenger));
        when(() => rideTrackingRepository.getActiveRide()).thenAnswer(
          (_) async => Left(Failure(message: 'error')),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(SessionCheckRequested()),
      expect: () => [
        isA<SessionAuthenticated>().having(
          (s) => s.activeRide,
          'activeRide',
          isNull,
        ),
      ],
    );

    blocTest<SessionBloc, SessionState>(
      'registra el token FCM (fire-and-forget) tras autenticar exitosamente',
      build: () {
        when(
          () => sessionRepository.isUserAuthenticated(),
        ).thenAnswer((_) async => Right(user));
        when(
          () => passengerProfileRepository.getPassenger(
            passengerId: any(named: 'passengerId'),
          ),
        ).thenAnswer((_) async => Right(passenger));
        when(
          () => rideTrackingRepository.getActiveRide(),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => pushNotificationsService.getToken(),
        ).thenAnswer((_) async => const Right('token-123'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(SessionCheckRequested()),
      wait: const Duration(milliseconds: 10),
      expect: () => [isA<SessionAuthenticated>()],
      verify: (_) {
        verify(
          () => passengerProfileRepository.updateFcmToken(
            passengerId: user.id,
            token: 'token-123',
          ),
        ).called(1);
      },
    );

    blocTest<SessionBloc, SessionState>(
      'no intenta guardar token si getToken devuelve Right(null)',
      build: () {
        when(
          () => sessionRepository.isUserAuthenticated(),
        ).thenAnswer((_) async => Right(user));
        when(
          () => passengerProfileRepository.getPassenger(
            passengerId: any(named: 'passengerId'),
          ),
        ).thenAnswer((_) async => Right(passenger));
        when(
          () => rideTrackingRepository.getActiveRide(),
        ).thenAnswer((_) async => const Right(null));
        return buildBloc();
      },
      act: (bloc) => bloc.add(SessionCheckRequested()),
      wait: const Duration(milliseconds: 10),
      expect: () => [isA<SessionAuthenticated>()],
      verify: (_) {
        verifyNever(
          () => passengerProfileRepository.updateFcmToken(
            passengerId: any(named: 'passengerId'),
            token: any(named: 'token'),
          ),
        );
      },
    );

    blocTest<SessionBloc, SessionState>(
      'un refresh de token posterior también actualiza el token FCM',
      build: () {
        final tokenRefreshController = StreamController<String>();
        addTearDown(tokenRefreshController.close);
        when(
          () => sessionRepository.isUserAuthenticated(),
        ).thenAnswer((_) async => Right(user));
        when(
          () => passengerProfileRepository.getPassenger(
            passengerId: any(named: 'passengerId'),
          ),
        ).thenAnswer((_) async => Right(passenger));
        when(
          () => rideTrackingRepository.getActiveRide(),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => pushNotificationsService.onTokenRefresh,
        ).thenAnswer((_) => tokenRefreshController.stream);
        // usamos una referencia externa vía closure para emitir luego
        Timer(const Duration(milliseconds: 5), () {
          tokenRefreshController.add('nuevo-token');
        });
        return buildBloc();
      },
      act: (bloc) => bloc.add(SessionCheckRequested()),
      wait: const Duration(milliseconds: 30),
      expect: () => [isA<SessionAuthenticated>()],
      verify: (_) {
        verify(
          () => passengerProfileRepository.updateFcmToken(
            passengerId: user.id,
            token: 'nuevo-token',
          ),
        ).called(1);
      },
    );
  });

  group('SessionLogoutRequested', () {
    blocTest<SessionBloc, SessionState>(
      'emite SessionUnauthenticated cuando el sign out es exitoso',
      build: () {
        when(
          () => sessionRepository.signOut(),
        ).thenAnswer((_) async => const Right(unit));
        return buildBloc();
      },
      act: (bloc) => bloc.add(SessionLogoutRequested()),
      expect: () => [isA<SessionUnauthenticated>()],
    );

    blocTest<SessionBloc, SessionState>(
      'no emite nada nuevo si el sign out falla (solo hace debugPrint del error)',
      build: () {
        when(
          () => sessionRepository.signOut(),
        ).thenAnswer((_) async => Left(Failure(message: 'error')));
        return buildBloc();
      },
      seed: () => SessionAuthenticated(user: user),
      act: (bloc) => bloc.add(SessionLogoutRequested()),
      expect: () => <SessionState>[],
      verify: (bloc) {
        expect(bloc.state, isA<SessionAuthenticated>());
      },
    );
  });
}

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/core/error/errors.dart';
import 'package:passenger_app/shared/domain/entity/user_location.dart';
import 'package:passenger_app/shared/geolocator/location/location_bloc.dart';
import 'package:passenger_app/shared/geolocator/service/geolocator/geolocator_service.dart';

class _MockGeolocatorService extends Mock implements GeolocatorService {}

void main() {
  late _MockGeolocatorService locationService;

  setUp(() {
    locationService = _MockGeolocatorService();
  });

  LocationBloc buildBloc() => LocationBloc(locationService: locationService);

  test('el estado inicial tiene locationProcess.initial', () {
    expect(buildBloc().state.locationProcess, LocationProcess.initial);
  });

  group('CheckAndRequestPermissionEvent', () {
    blocTest<LocationBloc, LocationState>(
      'emite checkingPermissions y luego permissionsReady con el permiso otorgado',
      build: () {
        when(() => locationService.checkAndRequestPermission()).thenAnswer(
          (_) async => const Right(LocationPermission.whileInUse),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(CheckAndRequestPermissionEvent()),
      expect: () => [
        isA<LocationState>().having(
          (s) => s.locationProcess,
          'locationProcess',
          LocationProcess.checkingPermissions,
        ),
        isA<LocationState>()
            .having(
              (s) => s.locationProcess,
              'locationProcess',
              LocationProcess.permissionsReady,
            )
            .having(
              (s) => s.permissionStatus,
              'permissionStatus',
              LocationPermission.whileInUse,
            ),
      ],
    );

    blocTest<LocationBloc, LocationState>(
      'emite permissionsError cuando el servicio falla',
      build: () {
        when(() => locationService.checkAndRequestPermission()).thenAnswer(
          (_) async => Left(Failure(message: 'denegado por el usuario')),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(CheckAndRequestPermissionEvent()),
      expect: () => [
        isA<LocationState>().having(
          (s) => s.locationProcess,
          'locationProcess',
          LocationProcess.checkingPermissions,
        ),
        isA<LocationState>()
            .having(
              (s) => s.locationProcess,
              'locationProcess',
              LocationProcess.permissionsError,
            )
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              'denegado por el usuario',
            ),
      ],
    );

    blocTest<LocationBloc, LocationState>(
      'limpia un error previo cuando el nuevo chequeo de permisos es exitoso',
      build: () {
        when(() => locationService.checkAndRequestPermission()).thenAnswer(
          (_) async => const Right(LocationPermission.always),
        );
        return buildBloc();
      },
      seed: () => const LocationState(errorMessage: 'error anterior'),
      act: (bloc) => bloc.add(CheckAndRequestPermissionEvent()),
      expect: () => [
        isA<LocationState>(),
        isA<LocationState>()
            .having(
              (s) => s.locationProcess,
              'locationProcess',
              LocationProcess.permissionsReady,
            )
            .having((s) => s.errorMessage, 'errorMessage', isNull),
      ],
    );
  });

  group('FetchCurrentLocationEvent', () {
    blocTest<LocationBloc, LocationState>(
      'corta temprano con permissionsError si el permiso está denegado, sin llamar al servicio',
      build: buildBloc,
      seed: () =>
          const LocationState(permissionStatus: LocationPermission.denied),
      act: (bloc) => bloc.add(FetchCurrentLocationEvent()),
      expect: () => [
        isA<LocationState>().having(
          (s) => s.locationProcess,
          'locationProcess',
          LocationProcess.gettingCurrentCords,
        ),
        isA<LocationState>()
            .having(
              (s) => s.locationProcess,
              'locationProcess',
              LocationProcess.permissionsError,
            )
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              'No tiene permisos de ubicación.',
            ),
      ],
      verify: (_) {
        verifyNever(() => locationService.getCurrentPosition());
      },
    );

    blocTest<LocationBloc, LocationState>(
      'corta temprano también con deniedForever',
      build: buildBloc,
      seed: () => const LocationState(
        permissionStatus: LocationPermission.deniedForever,
      ),
      act: (bloc) => bloc.add(FetchCurrentLocationEvent()),
      expect: () => [
        isA<LocationState>(),
        isA<LocationState>().having(
          (s) => s.locationProcess,
          'locationProcess',
          LocationProcess.permissionsError,
        ),
      ],
      verify: (_) {
        verifyNever(() => locationService.getCurrentPosition());
      },
    );

    blocTest<LocationBloc, LocationState>(
      'obtiene la posición actual cuando el permiso ya está otorgado',
      build: () {
        when(() => locationService.getCurrentPosition()).thenAnswer(
          (_) async => Right(UserLocation(latitude: 1, longitude: 2)),
        );
        return buildBloc();
      },
      seed: () =>
          const LocationState(permissionStatus: LocationPermission.whileInUse),
      act: (bloc) => bloc.add(FetchCurrentLocationEvent()),
      expect: () => [
        isA<LocationState>().having(
          (s) => s.locationProcess,
          'locationProcess',
          LocationProcess.gettingCurrentCords,
        ),
        isA<LocationState>()
            .having(
              (s) => s.locationProcess,
              'locationProcess',
              LocationProcess.currentCordsReady,
            )
            .having(
              (s) => s.lastKnownLocation?.latitude,
              'lastKnownLocation.latitude',
              1,
            ),
      ],
    );

    blocTest<LocationBloc, LocationState>(
      'emite currentCordsError si el servicio falla con permiso otorgado',
      build: () {
        when(() => locationService.getCurrentPosition()).thenAnswer(
          (_) async => Left(Failure(message: 'GPS apagado')),
        );
        return buildBloc();
      },
      seed: () =>
          const LocationState(permissionStatus: LocationPermission.whileInUse),
      act: (bloc) => bloc.add(FetchCurrentLocationEvent()),
      expect: () => [
        isA<LocationState>(),
        isA<LocationState>()
            .having(
              (s) => s.locationProcess,
              'locationProcess',
              LocationProcess.currentCordsError,
            )
            .having((s) => s.errorMessage, 'errorMessage', 'GPS apagado'),
      ],
    );

    blocTest<LocationBloc, LocationState>(
      'también consulta la posición cuando el permiso todavía no se chequeó (null)',
      build: () {
        when(() => locationService.getCurrentPosition()).thenAnswer(
          (_) async => Right(UserLocation(latitude: 5, longitude: 6)),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(FetchCurrentLocationEvent()),
      expect: () => [
        isA<LocationState>(),
        isA<LocationState>().having(
          (s) => s.locationProcess,
          'locationProcess',
          LocationProcess.currentCordsReady,
        ),
      ],
      verify: (_) {
        verify(() => locationService.getCurrentPosition()).called(1);
      },
    );
  });

  group('OpenAppSettingsEvent', () {
    blocTest<LocationBloc, LocationState>(
      'delega en el servicio y no emite ningún estado nuevo',
      build: () {
        when(
          () => locationService.openAppSettings(),
        ).thenAnswer((_) async => const Right(true));
        return buildBloc();
      },
      act: (bloc) => bloc.add(OpenAppSettingsEvent()),
      expect: () => <LocationState>[],
      verify: (_) {
        verify(() => locationService.openAppSettings()).called(1);
      },
    );
  });
}

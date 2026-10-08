import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/core/error/errors.dart';
import 'package:passenger_app/features/map/presentation/bloc/map_picker/map_picker_bloc.dart';
import 'package:passenger_app/shared/geocoding/domain/repository/geocoding_repository.dart';
import 'package:passenger_app/shared/sectors/domain/entity/sector_entity.dart';
import 'package:passenger_app/shared/sectors/domain/service/sector_service.dart';

class _MockGeocodingRepository extends Mock implements GeocodingRepository {}

class _MockSectorService extends Mock implements SectorService {}

const _bounds = SectorBounds(
  minLatitude: -1.70,
  minLongitude: -78.70,
  maxLatitude: -1.60,
  maxLongitude: -78.60,
);

SectorEntity _sector(String name) {
  return SectorEntity(
    name: name,
    ring: const [
      SectorPoint(latitude: -1.67, longitude: -78.65),
      SectorPoint(latitude: -1.66, longitude: -78.65),
      SectorPoint(latitude: -1.66, longitude: -78.64),
    ],
    bounds: _bounds,
    area: 1,
  );
}

void main() {
  late _MockGeocodingRepository geocodingRepository;
  late _MockSectorService sectorService;

  setUp(() {
    geocodingRepository = _MockGeocodingRepository();
    sectorService = _MockSectorService();

    when(
      () => sectorService.loadSectors(),
    ).thenAnswer((_) async => Right([_sector('La Condamine')]));
    when(
      () => sectorService.coverageBounds(),
    ).thenAnswer((_) async => const Right(_bounds));
    when(
      () => sectorService.sectorFor(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).thenAnswer((_) async => Right(_sector('La Condamine')));
  });

  void stubOutOfCoverage() {
    when(
      () => sectorService.sectorFor(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).thenAnswer((_) async => const Right(null));
  }

  MapPickerBloc buildBloc() => MapPickerBloc(
    geocodingRepository: geocodingRepository,
    sectorService: sectorService,
  );

  test('el estado inicial es MapPickerState() con status initial', () {
    final state = buildBloc().state;
    expect(state.status, MapPickerStatus.initial);
    expect(state.latitude, 0);
    expect(state.longitude, 0);
    expect(state.sectors, isEmpty);
  });

  group('MapCenterInitialized (no debounced)', () {
    blocTest<MapPickerBloc, MapPickerState>(
      'emite loadingAddress y luego addressReady',
      build: () {
        when(
          () => geocodingRepository.getAddressFromCoordinates(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenAnswer((_) async => const Right('Mi dirección'));
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(MapCenterInitialized(latitude: 1, longitude: 2)),
      expect: () => [
        isA<MapPickerState>().having(
          (s) => s.status,
          'status',
          MapPickerStatus.loadingAddress,
        ),
        isA<MapPickerState>()
            .having((s) => s.status, 'status', MapPickerStatus.addressReady)
            .having((s) => s.address, 'address', 'Mi dirección')
            .having((s) => s.sector, 'sector', 'La Condamine'),
      ],
    );

    // La vista necesita los polígonos para dibujarlos y la caja para limitar el
    // encuadre; se cargan una vez, al abrir la pantalla.
    blocTest<MapPickerBloc, MapPickerState>(
      'carga los sectores y la caja de cobertura para la vista',
      build: () {
        when(
          () => geocodingRepository.getAddressFromCoordinates(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenAnswer((_) async => const Right('Mi dirección'));
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(MapCenterInitialized(latitude: 1, longitude: 2)),
      expect: () => [
        predicate<MapPickerState>(
          (s) => s.sectors.length == 1 && s.coverageBounds == _bounds,
        ),
        isA<MapPickerState>().having(
          (s) => s.status,
          'status',
          MapPickerStatus.addressReady,
        ),
      ],
    );

    blocTest<MapPickerBloc, MapPickerState>(
      'emite error cuando el geocoding falla',
      build: () {
        when(
          () => geocodingRepository.getAddressFromCoordinates(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenAnswer((_) async => Left(Failure(code: FailureCode.unexpected)));
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(MapCenterInitialized(latitude: 1, longitude: 2)),
      expect: () => [
        isA<MapPickerState>().having(
          (s) => s.status,
          'status',
          MapPickerStatus.loadingAddress,
        ),
        isA<MapPickerState>()
            .having((s) => s.status, 'status', MapPickerStatus.error)
            .having((s) => s.errorCode, 'errorCode', FailureCode.unexpected),
      ],
    );
  });

  group('MapCameraIdle (debounced 500ms + switchMap)', () {
    blocTest<MapPickerBloc, MapPickerState>(
      'un burst de movimientos de cámara solo resuelve la última posición',
      build: () {
        when(
          () => geocodingRepository.getAddressFromCoordinates(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenAnswer((_) async => const Right('Dirección final'));
        return buildBloc();
      },
      act: (bloc) {
        bloc.add(MapCameraIdle(latitude: 1, longitude: 1));
        bloc.add(MapCameraIdle(latitude: 2, longitude: 2));
        bloc.add(MapCameraIdle(latitude: 3, longitude: 3));
      },
      wait: const Duration(milliseconds: 600),
      expect: () => [
        predicate<MapPickerState>(
          (s) =>
              s.status == MapPickerStatus.loadingAddress &&
              s.latitude == 3 &&
              s.longitude == 3,
        ),
        isA<MapPickerState>()
            .having((s) => s.status, 'status', MapPickerStatus.addressReady)
            .having((s) => s.address, 'address', 'Dirección final'),
      ],
      verify: (_) {
        verify(
          () => geocodingRepository.getAddressFromCoordinates(
            lat: 3,
            lng: 3,
          ),
        ).called(1);
      },
    );

    // El pin fuera de los polígonos no se puede confirmar, y no se gasta una
    // llamada a Geocoding por cada arrastre fuera de la zona.
    blocTest<MapPickerBloc, MapPickerState>(
      'emite outOfCoverage y no geocodifica si el pin cae fuera de los sectores',
      build: () {
        stubOutOfCoverage();
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(MapCameraIdle(latitude: -0.1807, longitude: -78.4678)),
      wait: const Duration(milliseconds: 600),
      expect: () => [
        isA<MapPickerState>().having(
          (s) => s.status,
          'status',
          MapPickerStatus.loadingAddress,
        ),
        predicate<MapPickerState>(
          (s) =>
              s.status == MapPickerStatus.outOfCoverage && s.sector == null,
        ),
      ],
      verify: (_) {
        verifyNever(
          () => geocodingRepository.getAddressFromCoordinates(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        );
      },
    );

    // Volver a una zona válida tiene que rehabilitar el confirmar.
    blocTest<MapPickerBloc, MapPickerState>(
      'volver a cobertura emite addressReady de nuevo',
      build: () {
        when(
          () => geocodingRepository.getAddressFromCoordinates(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenAnswer((_) async => const Right('Av. Daniel L. Borja'));
        return buildBloc();
      },
      seed: () => const MapPickerState(status: MapPickerStatus.outOfCoverage),
      act: (bloc) => bloc.add(MapCameraIdle(latitude: -1.665, longitude: -78.645)),
      wait: const Duration(milliseconds: 600),
      expect: () => [
        isA<MapPickerState>().having(
          (s) => s.status,
          'status',
          MapPickerStatus.loadingAddress,
        ),
        predicate<MapPickerState>(
          (s) =>
              s.status == MapPickerStatus.addressReady &&
              s.sector == 'La Condamine',
        ),
      ],
    );

    // Si el .geojson no se puede leer, el mapa sigue andando sin validar: es
    // preferible a dejar al pasajero sin poder elegir nada.
    blocTest<MapPickerBloc, MapPickerState>(
      'si falla la lectura de sectores deja confirmar igual, sin sector',
      build: () {
        when(
          () => sectorService.sectorFor(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenAnswer(
          (_) async => Left(Failure(code: FailureCode.sectorsLoadFailed)),
        );
        when(
          () => geocodingRepository.getAddressFromCoordinates(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenAnswer((_) async => const Right('Av. Daniel L. Borja'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(MapCameraIdle(latitude: -1.665, longitude: -78.645)),
      wait: const Duration(milliseconds: 600),
      skip: 1,
      expect: () => [
        predicate<MapPickerState>(
          (s) =>
              s.status == MapPickerStatus.addressReady && s.sector == null,
        ),
      ],
    );
  });
}

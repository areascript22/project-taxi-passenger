import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/core/error/errors.dart';
import 'package:passenger_app/features/map/presentation/bloc/map_picker/map_picker_bloc.dart';
import 'package:passenger_app/shared/geocoding/domain/repository/geocoding_repository.dart';

class _MockGeocodingRepository extends Mock implements GeocodingRepository {}

void main() {
  late _MockGeocodingRepository geocodingRepository;

  setUp(() {
    geocodingRepository = _MockGeocodingRepository();
  });

  MapPickerBloc buildBloc() =>
      MapPickerBloc(geocodingRepository: geocodingRepository);

  test('el estado inicial es MapPickerState() con status initial', () {
    final state = buildBloc().state;
    expect(state.status, MapPickerStatus.initial);
    expect(state.latitude, 0);
    expect(state.longitude, 0);
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
            .having((s) => s.address, 'address', 'Mi dirección'),
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
        ).thenAnswer((_) async => Left(Failure(message: 'sin señal')));
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
            .having((s) => s.errorMessage, 'errorMessage', 'sin señal'),
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
  });
}

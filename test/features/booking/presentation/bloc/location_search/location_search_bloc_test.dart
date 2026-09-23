import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/core/error/errors.dart';
import 'package:passenger_app/features/booking/domain/repository/location_search_repository.dart';
import 'package:passenger_app/features/booking/presentation/bloc/location_search/location_search_bloc.dart';
import 'package:passenger_app/shared/domain/entity/place_entity.dart';

class _MockLocationSearchRepository extends Mock
    implements LocationSearchRepository {}

void main() {
  late _MockLocationSearchRepository repository;

  setUp(() {
    repository = _MockLocationSearchRepository();
  });

  LocationSearchBloc buildBloc() =>
      LocationSearchBloc(locationSearchRepository: repository);

  test('el estado inicial es LocationSearchInitial', () {
    expect(buildBloc().state, isA<LocationSearchInitial>());
  });

  group('SearchQueryChanged (debounced 500ms)', () {
    blocTest<LocationSearchBloc, LocationSearchState>(
      'query vacía emite LocationSearchInitial sin llamar al repositorio',
      build: buildBloc,
      act: (bloc) => bloc.add(SearchQueryChanged(query: '')),
      wait: const Duration(milliseconds: 600),
      expect: () => [isA<LocationSearchInitial>()],
      verify: (_) {
        verifyNever(
          () => repository.getAutocompletePlaces(query: any(named: 'query')),
        );
      },
    );

    blocTest<LocationSearchBloc, LocationSearchState>(
      'query válida emite Loading y luego Loaded con los resultados',
      build: () {
        when(
          () => repository.getAutocompletePlaces(query: any(named: 'query')),
        ).thenAnswer(
          (_) async => const Right([PlaceEntity(address: 'Resultado 1')]),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(SearchQueryChanged(query: 'Av')),
      wait: const Duration(milliseconds: 600),
      expect: () => [
        isA<LocationSearchLoading>(),
        isA<LocationSearchLoaded>().having(
          (s) => s.places.map((p) => p.address).toList(),
          'places',
          ['Resultado 1'],
        ),
      ],
    );

    blocTest<LocationSearchBloc, LocationSearchState>(
      'emite LocationSearchError cuando el repositorio devuelve Left',
      build: () {
        when(
          () => repository.getAutocompletePlaces(query: any(named: 'query')),
        ).thenAnswer((_) async => Left(Failure(message: 'sin resultados')));
        return buildBloc();
      },
      act: (bloc) => bloc.add(SearchQueryChanged(query: 'zzz')),
      wait: const Duration(milliseconds: 600),
      expect: () => [
        isA<LocationSearchLoading>(),
        isA<LocationSearchError>().having(
          (s) => s.message,
          'message',
          'sin resultados',
        ),
      ],
    );

    blocTest<LocationSearchBloc, LocationSearchState>(
      'un burst de queries (debounce) solo dispara la búsqueda con el último valor',
      build: () {
        when(
          () => repository.getAutocompletePlaces(query: any(named: 'query')),
        ).thenAnswer((_) async => const Right([]));
        return buildBloc();
      },
      act: (bloc) {
        bloc.add(SearchQueryChanged(query: 'a'));
        bloc.add(SearchQueryChanged(query: 'av'));
        bloc.add(SearchQueryChanged(query: 'ave'));
      },
      wait: const Duration(milliseconds: 600),
      expect: () => [isA<LocationSearchLoading>(), isA<LocationSearchLoaded>()],
      verify: (_) {
        verify(
          () => repository.getAutocompletePlaces(query: 'ave'),
        ).called(1);
        verifyNever(() => repository.getAutocompletePlaces(query: 'a'));
        verifyNever(() => repository.getAutocompletePlaces(query: 'av'));
      },
    );
  });

  group('ClearSearchResults', () {
    blocTest<LocationSearchBloc, LocationSearchState>(
      'siempre vuelve a LocationSearchInitial sin importar el estado previo',
      build: () {
        when(
          () => repository.getAutocompletePlaces(query: any(named: 'query')),
        ).thenAnswer(
          (_) async => const Right([PlaceEntity(address: 'algo')]),
        );
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(SearchQueryChanged(query: 'algo'));
        await Future.delayed(const Duration(milliseconds: 600));
        bloc.add(ClearSearchResults());
      },
      skip: 2,
      expect: () => [isA<LocationSearchInitial>()],
    );
  });

  group('FetchCordsPlace', () {
    blocTest<LocationSearchBloc, LocationSearchState>(
      'no-op si el estado actual no es LocationSearchLoaded',
      build: buildBloc,
      act: (bloc) => bloc.add(FetchCordsPlace(placeId: 'p1')),
      expect: () => <LocationSearchState>[],
      verify: (_) {
        verifyNever(
          () => repository.getPlaceDetails(placeId: any(named: 'placeId')),
        );
      },
    );

    blocTest<LocationSearchBloc, LocationSearchState>(
      'obtiene coordenadas y actualiza el LocationSearchLoaded actual',
      build: () {
        when(
          () => repository.getAutocompletePlaces(query: any(named: 'query')),
        ).thenAnswer(
          (_) async => const Right([PlaceEntity(address: 'algo', placeId: 'p1')]),
        );
        when(
          () => repository.getPlaceDetails(placeId: any(named: 'placeId')),
        ).thenAnswer(
          (_) async => const Right(
            PlaceEntity(address: 'algo', latitude: 1, longitude: 2, placeId: 'p1'),
          ),
        );
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(SearchQueryChanged(query: 'algo'));
        await Future.delayed(const Duration(milliseconds: 600));
        bloc.add(FetchCordsPlace(placeId: 'p1'));
      },
      skip: 2,
      expect: () => [
        isA<LocationSearchLoaded>().having(
          (s) => s.searchLoadedProcess,
          'process',
          SearchLoadedProcess.gettingCords,
        ),
        isA<LocationSearchLoaded>()
            .having(
              (s) => s.searchLoadedProcess,
              'process',
              SearchLoadedProcess.gettingCordsReady,
            )
            .having(
              (s) => s.placeWithCords?.latitude,
              'placeWithCords.latitude',
              1,
            ),
      ],
    );

    blocTest<LocationSearchBloc, LocationSearchState>(
      'propaga el error de getPlaceDetails en cordsError',
      build: () {
        when(
          () => repository.getAutocompletePlaces(query: any(named: 'query')),
        ).thenAnswer(
          (_) async => const Right([PlaceEntity(address: 'algo', placeId: 'p1')]),
        );
        when(
          () => repository.getPlaceDetails(placeId: any(named: 'placeId')),
        ).thenAnswer(
          (_) async => Left(Failure(message: 'place no encontrado')),
        );
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(SearchQueryChanged(query: 'algo'));
        await Future.delayed(const Duration(milliseconds: 600));
        bloc.add(FetchCordsPlace(placeId: 'p1'));
      },
      skip: 2,
      expect: () => [
        isA<LocationSearchLoaded>().having(
          (s) => s.searchLoadedProcess,
          'process',
          SearchLoadedProcess.gettingCords,
        ),
        isA<LocationSearchLoaded>()
            .having(
              (s) => s.searchLoadedProcess,
              'process',
              SearchLoadedProcess.gettingCordsError,
            )
            .having((s) => s.cordsError, 'cordsError', 'place no encontrado'),
      ],
    );
  });
}

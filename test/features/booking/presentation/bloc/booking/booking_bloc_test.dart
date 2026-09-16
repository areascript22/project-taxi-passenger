import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/core/error/errors.dart';
import 'package:passenger_app/features/booking/domain/entity/request_entity.dart';
import 'package:passenger_app/features/booking/domain/repository/booking_repository.dart';
import 'package:passenger_app/features/booking/presentation/bloc/booking/booking_bloc.dart';
import 'package:passenger_app/shared/domain/entity/place_entity.dart';
import 'package:passenger_app/shared/geocoding/domain/repository/geocoding_repository.dart';

class _MockGeocodingRepository extends Mock implements GeocodingRepository {}

class _MockBookingRepository extends Mock implements BookingRepository {}

class _FakeRequestEntity extends Fake implements RequestEntity {}

void main() {
  late _MockGeocodingRepository geocodingRepository;
  late _MockBookingRepository bookingRepository;

  setUpAll(() {
    registerFallbackValue(_FakeRequestEntity());
  });

  setUp(() {
    geocodingRepository = _MockGeocodingRepository();
    bookingRepository = _MockBookingRepository();
  });

  BookingBloc buildBloc() => BookingBloc(
    geocodingRepository: geocodingRepository,
    bookingRepository: bookingRepository,
  );

  test('el estado inicial es BookingState() con status initial', () {
    expect(buildBloc().state.status, BookingStatus.initial);
  });

  group('FetchPickupAddress', () {
    blocTest<BookingBloc, BookingState>(
      'emite fetchingAddress y luego readyToBook con la dirección resuelta',
      build: () {
        when(
          () => geocodingRepository.getAddressFromCoordinates(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenAnswer((_) async => const Right('Av. Siempre Viva 123'));
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(FetchPickupAddress(latitude: -34.6, longitude: -58.4)),
      expect: () => [
        predicate<BookingState>(
          (s) =>
              s.status == BookingStatus.fetchingAddress &&
              s.pickupLat == -34.6 &&
              s.pickupLng == -58.4,
        ),
        predicate<BookingState>(
          (s) =>
              s.status == BookingStatus.readyToBook &&
              s.pickupAddress == 'Av. Siempre Viva 123',
        ),
      ],
    );

    blocTest<BookingBloc, BookingState>(
      'emite error cuando el geocoding falla',
      build: () {
        when(
          () => geocodingRepository.getAddressFromCoordinates(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenAnswer((_) async => Left(Failure(message: 'sin conexión')));
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(FetchPickupAddress(latitude: -34.6, longitude: -58.4)),
      expect: () => [
        isA<BookingState>().having(
          (s) => s.status,
          'status',
          BookingStatus.fetchingAddress,
        ),
        isA<BookingState>()
            .having((s) => s.status, 'status', BookingStatus.error)
            .having((s) => s.errorMessage, 'errorMessage', 'sin conexión'),
      ],
    );
  });

  group('UpdatePickUpAddress', () {
    blocTest<BookingBloc, BookingState>(
      'actualiza address/lat/lng de forma síncrona desde un PlaceEntity',
      build: buildBloc,
      act: (bloc) => bloc.add(
        UpdatePickUpAddress(
          placeEntity: const PlaceEntity(
            address: 'Nueva dirección',
            latitude: 1.0,
            longitude: 2.0,
          ),
        ),
      ),
      expect: () => [
        predicate<BookingState>(
          (s) =>
              s.pickupAddress == 'Nueva dirección' &&
              s.pickupLat == 1.0 &&
              s.pickupLng == 2.0,
        ),
      ],
    );
  });

  group('RequestTaxi', () {
    const request = RequestEntity(
      pickupLat: 1,
      pickupLng: 2,
      pickupAddress: 'x',
    );

    blocTest<BookingBloc, BookingState>(
      'emite requestingTaxi y luego requestInQueue si el repo confirma',
      build: () {
        when(
          () => bookingRepository.requestTaxi(request: any(named: 'request')),
        ).thenAnswer((_) async => const Right(unit));
        return buildBloc();
      },
      act: (bloc) => bloc.add(RequestTaxi(request: request)),
      expect: () => [
        isA<BookingState>().having(
          (s) => s.status,
          'status',
          BookingStatus.requestingTaxi,
        ),
        isA<BookingState>().having(
          (s) => s.status,
          'status',
          BookingStatus.requestInQueue,
        ),
      ],
      verify: (_) {
        verify(
          () => bookingRepository.requestTaxi(request: request),
        ).called(1);
      },
    );

    blocTest<BookingBloc, BookingState>(
      'emite error si el repositorio rechaza la solicitud',
      build: () {
        when(
          () => bookingRepository.requestTaxi(request: any(named: 'request')),
        ).thenAnswer((_) async => Left(Failure(message: 'no hay conductores')));
        return buildBloc();
      },
      act: (bloc) => bloc.add(RequestTaxi(request: request)),
      expect: () => [
        isA<BookingState>().having(
          (s) => s.status,
          'status',
          BookingStatus.requestingTaxi,
        ),
        isA<BookingState>()
            .having((s) => s.status, 'status', BookingStatus.error)
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              'no hay conductores',
            ),
      ],
    );
  });

  group('CancelTaxiRequest', () {
    blocTest<BookingBloc, BookingState>(
      'emite cancellingRequest y vuelve a initial tras confirmar cancelación',
      build: () {
        when(
          () => bookingRepository.cancelTaxiRequest(),
        ).thenAnswer((_) async => const Right(unit));
        return buildBloc();
      },
      act: (bloc) => bloc.add(CancelTaxiRequest()),
      wait: const Duration(seconds: 2),
      expect: () => [
        isA<BookingState>().having(
          (s) => s.status,
          'status',
          BookingStatus.cancellingRequest,
        ),
        isA<BookingState>().having(
          (s) => s.status,
          'status',
          BookingStatus.initial,
        ),
      ],
    );

    blocTest<BookingBloc, BookingState>(
      'emite error si la cancelación falla en el backend',
      build: () {
        when(() => bookingRepository.cancelTaxiRequest()).thenAnswer(
          (_) async => Left(Failure(message: 'no se pudo cancelar')),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(CancelTaxiRequest()),
      wait: const Duration(seconds: 2),
      expect: () => [
        isA<BookingState>().having(
          (s) => s.status,
          'status',
          BookingStatus.cancellingRequest,
        ),
        isA<BookingState>()
            .having((s) => s.status, 'status', BookingStatus.error)
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              'no se pudo cancelar',
            ),
      ],
    );
  });
}

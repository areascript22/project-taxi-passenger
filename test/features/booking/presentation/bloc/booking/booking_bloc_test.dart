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
import 'package:passenger_app/shared/sectors/domain/entity/sector_entity.dart';
import 'package:passenger_app/shared/sectors/domain/service/sector_service.dart';

class _MockGeocodingRepository extends Mock implements GeocodingRepository {}

class _MockBookingRepository extends Mock implements BookingRepository {}

class _MockSectorService extends Mock implements SectorService {}

class _FakeRequestEntity extends Fake implements RequestEntity {}

// El anillo y el área no importan acá: el Bloc solo lee el nombre. Lo que se
// prueba en este archivo es el gate de cobertura, no la geometría (eso está en
// sector_geojson_parser_test.dart).
SectorEntity _sector(String name) {
  return SectorEntity(
    name: name,
    ring: const [
      SectorPoint(latitude: -1.67, longitude: -78.65),
      SectorPoint(latitude: -1.66, longitude: -78.65),
      SectorPoint(latitude: -1.66, longitude: -78.64),
    ],
    bounds: const SectorBounds(
      minLatitude: -1.67,
      minLongitude: -78.65,
      maxLatitude: -1.66,
      maxLongitude: -78.64,
    ),
    area: 1,
  );
}

void main() {
  late _MockGeocodingRepository geocodingRepository;
  late _MockBookingRepository bookingRepository;
  late _MockSectorService sectorService;

  setUpAll(() {
    registerFallbackValue(_FakeRequestEntity());
  });

  setUp(() {
    geocodingRepository = _MockGeocodingRepository();
    bookingRepository = _MockBookingRepository();
    sectorService = _MockSectorService();
    // Por defecto todos los puntos están en cobertura, para que los tests que
    // no se ocupan de los sectores sigan leyéndose igual que antes.
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

  BookingBloc buildBloc() => BookingBloc(
    geocodingRepository: geocodingRepository,
    bookingRepository: bookingRepository,
    sectorService: sectorService,
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
        ).thenAnswer((_) async => Left(Failure(code: FailureCode.unexpected)));
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
            .having((s) => s.errorCode, 'errorCode', FailureCode.unexpected),
      ],
    );

    blocTest<BookingBloc, BookingState>(
      'guarda el sector del punto junto con la dirección',
      build: () {
        when(
          () => geocodingRepository.getAddressFromCoordinates(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenAnswer((_) async => const Right('Av. Daniel L. Borja'));
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(FetchPickupAddress(latitude: -1.669, longitude: -78.658)),
      skip: 1,
      expect: () => [
        predicate<BookingState>(
          (s) =>
              s.status == BookingStatus.readyToBook &&
              s.pickupSector == 'La Condamine' &&
              s.canRequestTaxi,
        ),
      ],
    );

    // El pasajero puede estar físicamente fuera de Riobamba (de viaje): el GPS
    // es un camino de entrada más y también tiene que pasar por el gate.
    blocTest<BookingBloc, BookingState>(
      'si el GPS está fuera de cobertura no geocodifica ni deja pedir',
      build: () {
        stubOutOfCoverage();
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(FetchPickupAddress(latitude: -0.1807, longitude: -78.4678)),
      expect: () => [
        isA<BookingState>().having(
          (s) => s.status,
          'status',
          BookingStatus.fetchingAddress,
        ),
        predicate<BookingState>(
          (s) =>
              s.status == BookingStatus.outOfCoverage &&
              s.isOutOfCoverage &&
              s.pickupSector == null &&
              !s.canRequestTaxi,
        ),
      ],
      verify: (_) {
        // Se ahorra la llamada a Geocoding: la dirección de un punto que no se
        // puede pedir no le sirve a nadie y esa API se paga por consulta.
        verifyNever(
          () => geocodingRepository.getAddressFromCoordinates(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        );
      },
    );

    // Si el .geojson no se puede leer, bloquear a todos sería peor que perder
    // el filtro: el pedido sigue, sin sector, y driver_app vuelve a leer la
    // dirección completa.
    blocTest<BookingBloc, BookingState>(
      'si no se puede verificar la cobertura, deja pedir sin sector',
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
      act: (bloc) =>
          bloc.add(FetchPickupAddress(latitude: -1.669, longitude: -78.658)),
      skip: 1,
      expect: () => [
        predicate<BookingState>(
          (s) =>
              s.status == BookingStatus.readyToBook &&
              !s.isOutOfCoverage &&
              s.pickupSector == null &&
              s.canRequestTaxi,
        ),
      ],
    );
  });

  group('UpdatePickUpAddress', () {
    blocTest<BookingBloc, BookingState>(
      'actualiza address/lat/lng y el sector desde un PlaceEntity',
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
              s.pickupLng == 2.0 &&
              s.pickupSector == 'La Condamine' &&
              s.canRequestTaxi,
        ),
      ],
    );

    // Este es el camino del buscador: las predicciones del autocomplete no
    // traen coordenadas, así que el rechazo solo puede ocurrir acá, cuando ya
    // se pidieron los detalles del lugar.
    blocTest<BookingBloc, BookingState>(
      'marca fuera de cobertura y no deja pedir si el lugar no cae en ningún sector',
      build: () {
        stubOutOfCoverage();
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        UpdatePickUpAddress(
          placeEntity: const PlaceEntity(
            address: 'Quito, Ecuador',
            latitude: -0.1807,
            longitude: -78.4678,
          ),
        ),
      ),
      expect: () => [
        predicate<BookingState>(
          (s) =>
              s.status == BookingStatus.outOfCoverage &&
              s.isOutOfCoverage &&
              s.pickupSector == null &&
              // La dirección rechazada se guarda igual: la UI muestra qué fue
              // lo que no se aceptó.
              s.pickupAddress == 'Quito, Ecuador' &&
              !s.canRequestTaxi,
        ),
      ],
    );

    // Si no se limpiara el sector anterior, el conductor escucharía el sector
    // de un punto que el pasajero ya descartó.
    blocTest<BookingBloc, BookingState>(
      'un punto fuera de cobertura no hereda el sector del punto anterior',
      build: () {
        stubOutOfCoverage();
        return buildBloc();
      },
      seed: () => const BookingState(
        pickupSector: 'Loma de Quito',
        pickupAddress: 'Algo viejo',
        pickupLat: -1.66,
        pickupLng: -78.65,
      ),
      act: (bloc) => bloc.add(
        UpdatePickUpAddress(
          placeEntity: const PlaceEntity(
            address: 'Quito, Ecuador',
            latitude: -0.1807,
            longitude: -78.4678,
          ),
        ),
      ),
      expect: () => [
        predicate<BookingState>((s) => s.pickupSector == null),
      ],
    );

    blocTest<BookingBloc, BookingState>(
      'un lugar sin coordenadas no se puede ubicar: queda fuera de cobertura',
      build: buildBloc,
      act: (bloc) => bloc.add(
        UpdatePickUpAddress(
          placeEntity: const PlaceEntity(address: 'Sin coordenadas'),
        ),
      ),
      expect: () => [
        predicate<BookingState>(
          (s) => s.isOutOfCoverage && !s.canRequestTaxi,
        ),
      ],
      verify: (_) {
        verifyNever(
          () => sectorService.sectorFor(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        );
      },
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
        ).thenAnswer((_) async => Left(Failure(code: FailureCode.unexpected)));
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
            .having((s) => s.errorCode, 'errorCode', FailureCode.unexpected),
      ],
    );

    // Guarda de última línea: el botón ya está deshabilitado, pero el diálogo
    // de confirmación pudo quedar abierto desde antes de que el punto cambiara.
    blocTest<BookingBloc, BookingState>(
      'ignora el evento si el punto está fuera de cobertura',
      build: buildBloc,
      seed: () => const BookingState(isOutOfCoverage: true),
      act: (bloc) => bloc.add(RequestTaxi(request: request)),
      expect: () => const <BookingState>[],
      verify: (_) {
        verifyNever(
          () => bookingRepository.requestTaxi(request: any(named: 'request')),
        );
      },
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
          (_) async => Left(Failure(code: FailureCode.unexpected)),
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
            .having((s) => s.errorCode, 'errorCode', FailureCode.unexpected),
      ],
    );
  });
}

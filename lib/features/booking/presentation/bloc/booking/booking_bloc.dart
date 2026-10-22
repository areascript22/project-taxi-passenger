import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:passenger_app/core/error/errors.dart';
import 'package:passenger_app/features/booking/domain/entity/request_entity.dart';
import 'package:passenger_app/features/booking/domain/repository/booking_repository.dart';
import 'package:passenger_app/shared/domain/entity/place_entity.dart';
import 'package:passenger_app/shared/geocoding/domain/repository/geocoding_repository.dart';
import 'package:passenger_app/shared/sectors/domain/service/sector_service.dart';

part 'booking_event.dart';

part 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final GeocodingRepository geocodingRepository;
  final BookingRepository bookingRepository;

  // Los sectores son la zona de cobertura: acá se decide si el punto elegido se
  // puede pedir, para los TRES caminos que llegan a un pickup (GPS, mapa y
  // buscador). Va en el Bloc y no en cada pantalla justamente porque es el
  // único lugar por el que pasan los tres.
  final SectorService sectorService;

  BookingBloc({
    required this.geocodingRepository,
    required this.bookingRepository,
    required this.sectorService,
  }) : super(const BookingState()) {
    on<FetchPickupAddress>(_onFetchPickupAddress);
    on<UpdatePickUpAddress>(_onUpdatePickupAddress);
    on<RequestTaxi>(_onRequestTaxi);
    on<CancelTaxiRequest>(_onCancelTaxiRequest);
  }

  Future<void> _onFetchPickupAddress(
    FetchPickupAddress event,
    Emitter<BookingState> emit,
  ) async {
    // 1. Emit loading status and save the raw coordinates for later
    emit(
      state.copyWith(
        status: BookingStatus.fetchingAddress,
        pickupLat: event.latitude,
        pickupLng: event.longitude,
        // We clear any previous errors when starting a new request
        clearError: true,
      ),
    );

    // La cobertura se verifica ANTES de geocodificar: si el pasajero está fuera
    // de Riobamba no tiene sentido gastar una llamada a Geocoding para armar una
    // dirección que no va a poder usar.
    final coverage = await _resolveCoverage(
      latitude: event.latitude,
      longitude: event.longitude,
    );

    if (coverage.isOutOfCoverage) {
      emit(
        state.copyWith(
          status: BookingStatus.outOfCoverage,
          isOutOfCoverage: true,
          clearPickupSector: true,
        ),
      );
      return;
    }

    // 2. Call the repository
    final result = await geocodingRepository.getAddressFromCoordinates(
      lat: event.latitude,
      lng: event.longitude,
    );

    // 3. Handle the result
    result.fold(
      (failure) {
        emit(
          state.copyWith(
            status: BookingStatus.error,
            errorCode: failure.code,
          ),
        );
      },
      (address) {
        emit(
          state.copyWith(
            status: BookingStatus.readyToBook,
            pickupAddress: address,
            pickupSector: coverage.sector,
            isOutOfCoverage: false,
            clearPickupSector: coverage.sector == null,
          ),
        );
      },
    );
  }

  Future<void> _onUpdatePickupAddress(
    UpdatePickUpAddress event,
    Emitter<BookingState> emit,
  ) async {
    final place = event.placeEntity;
    final latitude = place.latitude;
    final longitude = place.longitude;

    // Una sugerencia del buscador sin coordenadas no se puede ubicar en ningún
    // sector; getPlaceDetails ya las exige, así que esto es defensa.
    if (latitude == null || longitude == null) {
      emit(
        state.copyWith(
          status: BookingStatus.outOfCoverage,
          isOutOfCoverage: true,
          pickupAddress: place.address,
          clearPickupSector: true,
        ),
      );
      return;
    }

    final coverage = await _resolveCoverage(
      latitude: latitude,
      longitude: longitude,
    );

    // El punto elegido se guarda igual (la UI muestra qué fue rechazado), pero
    // con isOutOfCoverage en true no se puede pedir el taxi.
    emit(
      state.copyWith(
        status:
            coverage.isOutOfCoverage
                ? BookingStatus.outOfCoverage
                : BookingStatus.readyToBook,
        pickupAddress: place.address,
        pickupLat: latitude,
        pickupLng: longitude,
        pickupSector: coverage.sector,
        isOutOfCoverage: coverage.isOutOfCoverage,
        clearPickupSector: coverage.sector == null,
      ),
    );
  }

  // Resuelve el sector del punto. Devuelve `isOutOfCoverage: true` SOLO si se
  // pudo verificar que el punto no pertenece a ningún sector: si el archivo de
  // sectores no se puede leer, se deja pasar sin sector (el conductor cae a la
  // dirección exacta, como antes de que existieran los sectores) en vez de
  // bloquear a todos los pasajeros por un asset roto.
  Future<_Coverage> _resolveCoverage({
    required double latitude,
    required double longitude,
  }) async {
    final result = await sectorService.sectorFor(
      latitude: latitude,
      longitude: longitude,
    );

    return result.fold(
      (_) => const _Coverage(sector: null, isOutOfCoverage: false),
      (sector) => _Coverage(
        sector: sector?.name,
        isOutOfCoverage: sector == null,
      ),
    );
  }

  void _onRequestTaxi(RequestTaxi event, Emitter<BookingState> emit) async {
    // Guarda de última línea: la UI ya deshabilita el botón fuera de cobertura,
    // pero el evento podría llegar por otro camino (un diálogo ya abierto
    // cuando el punto cambió, por ejemplo).
    if (state.isOutOfCoverage) return;

    emit(state.copyWith(status: BookingStatus.requestingTaxi));

    final response = await bookingRepository.requestTaxi(
      request: event.request,
    );

    response.fold(
      (l) => emit(
        state.copyWith(status: BookingStatus.error, errorCode: l.code),
      ),
      (r) => emit(state.copyWith(status: BookingStatus.requestInQueue)),
    );
  }

  void _onCancelTaxiRequest(
    CancelTaxiRequest event,
    Emitter<BookingState> emit,
  ) async {
    emit(state.copyWith(status: BookingStatus.cancellingRequest));

    await Future.delayed(const Duration(seconds: 2));

    final response = await bookingRepository.cancelTaxiRequest();

    response.fold(
      (l) => emit(
        state.copyWith(status: BookingStatus.error, errorCode: l.code),
      ),
      (r) => emit(state.copyWith(status: BookingStatus.initial)),
    );
  }
}

// Resultado de verificar la cobertura de un punto. Los dos campos son
// independientes: `sector == null` con `isOutOfCoverage == false` es el caso
// "no se pudo verificar", que se deja pasar.
class _Coverage {
  final String? sector;
  final bool isOutOfCoverage;

  const _Coverage({required this.sector, required this.isOutOfCoverage});
}

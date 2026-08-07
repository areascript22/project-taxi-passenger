import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:passenger_app/shared/domain/entity/place_entity.dart';
import 'package:passenger_app/features/booking/domain/entity/request_entity.dart';
import 'package:passenger_app/features/booking/domain/repository/booking_repository.dart';
import 'package:passenger_app/shared/geocoding/domain/repository/geocoding_repository.dart';

part 'booking_event.dart';

part 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final GeocodingRepository geocodingRepository;
  final BookingRepository bookingRepository;

  BookingBloc({
    required this.geocodingRepository,
    required this.bookingRepository,
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
        errorMessage: null,
      ),
    );

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
            errorMessage: failure.message,
          ),
        );
      },
      (address) {
        emit(
          state.copyWith(
            status: BookingStatus.readyToBook,
            pickupAddress: address,
          ),
        );
      },
    );
  }

  void _onUpdatePickupAddress(
    UpdatePickUpAddress event,
    Emitter<BookingState> emit,
  ) {
    emit(
      state.copyWith(
        pickupAddress: event.placeEntity.address,
        pickupLat: event.placeEntity.latitude,
        pickupLng: event.placeEntity.longitude,
      ),
    );
  }

  void _onRequestTaxi(RequestTaxi event, Emitter<BookingState> emit) async {
    emit(state.copyWith(status: BookingStatus.requestingTaxi));

    final response = await bookingRepository.requestTaxi(
      request: event.request,
    );

    response.fold(
      (l) => emit(
        state.copyWith(status: BookingStatus.error, errorMessage: l.message),
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
        state.copyWith(status: BookingStatus.error, errorMessage: l.message),
      ),
      (r) => emit(state.copyWith(status: BookingStatus.initial)),
    );
  }
}

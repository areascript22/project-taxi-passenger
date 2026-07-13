import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import '../../../domain/repository/geocoding_repository.dart';

part 'booking_event.dart';

part 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final GeocodingRepository geocodingRepository;

  BookingBloc({required this.geocodingRepository})
    : super(const BookingState()) {
    on<FetchPickupAddress>(_onFetchPickupAddress);
    on<UpdatePickUpAddress>(_onUpdatePickupAddress);
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
    emit(state.copyWith(pickupAddress: event.pickUpAddress));
  }
}

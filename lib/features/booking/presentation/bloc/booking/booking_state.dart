part of 'booking_bloc.dart';

enum BookingStatus {
  initial,
  fetchingAddress,
  readyToBook,
  requestingTaxi,
  cancellingRequest,
  requestInQueue,
  searchingForDriver,
  error,
}

@immutable
class BookingState {
  final BookingStatus status;
  final double? pickupLat;
  final double? pickupLng;
  final String? pickupAddress;
  final String? destinationAddress;
  final String? errorMessage;

  const BookingState({
    this.status = BookingStatus.initial,
    this.pickupLat,
    this.pickupLng,
    this.pickupAddress,
    this.destinationAddress,
    this.errorMessage,
  });

  BookingState copyWith({
    BookingStatus? status,
    double? pickupLat,
    double? pickupLng,
    String? pickupAddress,
    String? destinationAddress,
    String? errorMessage,
  }) {
    return BookingState(
      status: status ?? this.status,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      // If we pass null to errorMessage, we want to clear it,
      // so we handle it slightly differently if needed,
      // or just trust the new state emission to override it.
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

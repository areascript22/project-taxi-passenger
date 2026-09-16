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
    bool clearError = false,
  }) {
    return BookingState(
      status: status ?? this.status,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

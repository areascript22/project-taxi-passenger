part of 'booking_bloc.dart';

enum BookingStatus {
  initial,
  fetchingAddress,
  readyToBook,
  requestingTaxi, // Placeholder for future use
  searchingForDriver, // Placeholder for future use
  error,
}

@immutable
class BookingState {
  final BookingStatus status;

  // Data we hold onto during the entire booking lifecycle
  final double? pickupLat;
  final double? pickupLng;
  final String? pickupAddress;

  // Future fields we will need before requesting the taxi
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

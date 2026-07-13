part of 'booking_bloc.dart';

@immutable
sealed class BookingEvent {}

class FetchPickupAddress extends BookingEvent {
  final double latitude;
  final double longitude;

  FetchPickupAddress({required this.latitude, required this.longitude});
}

class UpdatePickUpAddress extends BookingEvent {
  final String pickUpAddress;

  UpdatePickUpAddress({required this.pickUpAddress});
}

// Future Event:
// class RequestTaxi extends BookingEvent {}

part of 'booking_bloc.dart';

@immutable
sealed class BookingEvent {}

class FetchPickupAddress extends BookingEvent {
  final double latitude;
  final double longitude;

  FetchPickupAddress({required this.latitude, required this.longitude});
}

class UpdatePickUpAddress extends BookingEvent {
  final PlaceEntity placeEntity;

  UpdatePickUpAddress({required this.placeEntity});
}

class RequestTaxi extends BookingEvent{
  final RequestEntity request;

  RequestTaxi({required this.request});
}


class CancelTaxiRequest extends BookingEvent{

}


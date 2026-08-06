part of 'ride_tracking_bloc.dart';

@immutable
sealed class RideTrackingEvent {}

class StartRideTracking extends RideTrackingEvent {
  final String passengerId;

  StartRideTracking({required this.passengerId});
}

class RideUpdated extends RideTrackingEvent {

  final RideEntity ride;

  RideUpdated(this.ride);

}


class StopRideTracking extends RideTrackingEvent {}

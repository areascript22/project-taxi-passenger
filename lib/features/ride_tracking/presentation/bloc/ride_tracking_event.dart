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

class CancelRideRequested extends RideTrackingEvent {
  final String passengerId;

  CancelRideRequested({required this.passengerId});
}

class ConfirmOnTheWayRequested extends RideTrackingEvent {
  final String passengerId;

  ConfirmOnTheWayRequested({required this.passengerId});
}

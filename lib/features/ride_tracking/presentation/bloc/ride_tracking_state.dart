part of 'ride_tracking_bloc.dart';

enum RideTrackingStatus {
  initial,
  connecting,
  waitingDriver,
  driverAssigned,
  driverArriving,
  driverArrived,
  tripStarted,
  tripCompleted,
  cancelled,
  error,
}

@immutable
class RideTrackingState {
  final RideTrackingStatus status;
  final RideEntity? ride;
  final String? errorMessage;

  const RideTrackingState({
    this.status = RideTrackingStatus.initial,
    this.ride,
    this.errorMessage,
  });

  RideTrackingState copyWith({
    RideTrackingStatus? status,

    RideEntity? ride,

    String? errorMessage,
  }) {
    return RideTrackingState(
      status: status ?? this.status,

      ride: ride ?? this.ride,

      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

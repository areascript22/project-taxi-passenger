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
  final bool isCancelling;

  const RideTrackingState({
    this.status = RideTrackingStatus.initial,
    this.ride,
    this.errorMessage,
    this.isCancelling = false,
  });

  RideTrackingState copyWith({
    RideTrackingStatus? status,
    RideEntity? ride,
    String? errorMessage,
    bool? isCancelling,
  }) {
    return RideTrackingState(
      status: status ?? this.status,
      ride: ride ?? this.ride,
      // Siempre explícito: pasar null limpia el error anterior en vez de
      // arrastrarlo indefinidamente.
      errorMessage: errorMessage,
      isCancelling: isCancelling ?? this.isCancelling,
    );
  }
}

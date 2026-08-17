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
  // Calculados en RideTrackingBloc a partir de ride.driver.location y
  // ride.pickupLatitude/Longitude cada vez que llega un RideUpdated. Una vez
  // que se conocen no vuelven a null (mismo criterio que `ride`): la
  // ubicación de Firebase no desaparece sola, así que "pegajosos" evita que
  // un copyWith de otro campo (ej. isCancelling) los borre de la UI.
  final double? distanceMeters;
  final int? etaMinutes;
  final double? progress;

  const RideTrackingState({
    this.status = RideTrackingStatus.initial,
    this.ride,
    this.errorMessage,
    this.isCancelling = false,
    this.distanceMeters,
    this.etaMinutes,
    this.progress,
  });

  RideTrackingState copyWith({
    RideTrackingStatus? status,
    RideEntity? ride,
    String? errorMessage,
    bool? isCancelling,
    double? distanceMeters,
    int? etaMinutes,
    double? progress,
  }) {
    return RideTrackingState(
      status: status ?? this.status,
      ride: ride ?? this.ride,
      // Siempre explícito: pasar null limpia el error anterior en vez de
      // arrastrarlo indefinidamente.
      errorMessage: errorMessage,
      isCancelling: isCancelling ?? this.isCancelling,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      progress: progress ?? this.progress,
    );
  }
}

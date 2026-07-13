part of 'location_bloc.dart';

@immutable
class LocationState {
  final bool isCheckingLocation;
  final LocationPermission? permissionStatus;
  final UserLocation? lastKnownLocation;
  final String? errorMessage;

  const LocationState({
    this.isCheckingLocation = false,
    this.permissionStatus,
    this.lastKnownLocation,
    this.errorMessage,
  });

  LocationState copyWith({
    bool? isCheckingLocation,
    LocationPermission? permissionStatus,
    UserLocation? lastKnownLocation,
    String? errorMessage,
  }) {
    return LocationState(
      isCheckingLocation: isCheckingLocation ?? this.isCheckingLocation,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      lastKnownLocation: lastKnownLocation ?? this.lastKnownLocation,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

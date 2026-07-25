part of 'location_bloc.dart';

enum LocationProcess {
  initial,
  checkingPermissions,
  permissionsReady,
  permissionsError,
  gettingCurrentCords,
  currentCordsReady,
  currentCordsError,
}

@immutable
class LocationState {
  final LocationPermission? permissionStatus;
  final UserLocation? lastKnownLocation;
  final String? errorMessage;
  final LocationProcess locationProcess;

  const LocationState({
    this.permissionStatus,
    this.lastKnownLocation,
    this.errorMessage,
    this.locationProcess = LocationProcess.initial,
  });

  LocationState copyWith({
    LocationPermission? permissionStatus,
    UserLocation? lastKnownLocation,
    String? errorMessage,
    LocationProcess? locationProcess,
  }) {
    return LocationState(
      permissionStatus: permissionStatus ?? this.permissionStatus,
      lastKnownLocation: lastKnownLocation ?? this.lastKnownLocation,
      errorMessage: errorMessage ?? this.errorMessage,
      locationProcess: locationProcess ?? this.locationProcess,
    );
  }
}

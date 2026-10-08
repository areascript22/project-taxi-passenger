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
  final FailureCode? errorCode;
  final LocationProcess locationProcess;

  const LocationState({
    this.permissionStatus,
    this.lastKnownLocation,
    this.errorCode,
    this.locationProcess = LocationProcess.initial,
  });

  LocationState copyWith({
    LocationPermission? permissionStatus,
    UserLocation? lastKnownLocation,
    FailureCode? errorCode,
    LocationProcess? locationProcess,
    bool clearError = false,
  }) {
    return LocationState(
      permissionStatus: permissionStatus ?? this.permissionStatus,
      lastKnownLocation: lastKnownLocation ?? this.lastKnownLocation,
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      locationProcess: locationProcess ?? this.locationProcess,
    );
  }
}

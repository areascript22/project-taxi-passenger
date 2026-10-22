part of 'location_bloc.dart';

@immutable
sealed class LocationEvent {}
class CheckAndRequestPermissionEvent extends LocationEvent {}

class FetchCurrentLocationEvent extends LocationEvent {}

class OpenAppSettingsEvent extends LocationEvent {}
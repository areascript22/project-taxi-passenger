part of 'map_picker_bloc.dart';

@immutable
sealed class MapPickerEvent {}

class MapCenterInitialized extends MapPickerEvent {
  final double latitude;
  final double longitude;

  MapCenterInitialized({required this.latitude, required this.longitude});
}

class MapCameraIdle extends MapPickerEvent {
  final double latitude;
  final double longitude;

  MapCameraIdle({required this.latitude, required this.longitude});
}

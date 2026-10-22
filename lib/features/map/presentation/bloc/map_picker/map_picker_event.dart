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

/// Abre el mapa. [latitude]/[longitude] son el punto de partida ya conocido
/// (la recogida elegida antes); si faltan, el bloc decide donde centrar: ultima
/// ubicacion guardada, GPS o el centro de Riobamba.
class MapPickerStarted extends MapPickerEvent {
  final double? latitude;
  final double? longitude;

  MapPickerStarted({this.latitude, this.longitude});
}

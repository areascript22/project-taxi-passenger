part of 'map_picker_bloc.dart';

enum MapPickerStatus { initial, loadingAddress, addressReady, error }

@immutable
class MapPickerState {
  final MapPickerStatus status;
  final double latitude;
  final double longitude;
  final String? address;
  final FailureCode? errorCode;

  const MapPickerState({
    this.status = MapPickerStatus.initial,
    this.latitude = 0,
    this.longitude = 0,
    this.address,
    this.errorCode,
  });

  MapPickerState copyWith({
    MapPickerStatus? status,
    double? latitude,
    double? longitude,
    String? address,
    FailureCode? errorCode,
  }) {
    return MapPickerState(
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      errorCode: errorCode ?? this.errorCode,
    );
  }
}

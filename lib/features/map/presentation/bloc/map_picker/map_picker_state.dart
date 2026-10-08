part of 'map_picker_bloc.dart';

enum MapPickerStatus {
  initial,
  loadingAddress,
  addressReady,
  // El pin quedó fuera de los sectores de Riobamba: no se puede confirmar esa
  // ubicación. No es `error` porque nada falló.
  outOfCoverage,
  error,
}

@immutable
class MapPickerState {
  final MapPickerStatus status;
  final double latitude;
  final double longitude;
  final String? address;

  /// Sector donde cayó el pin. Solo informativo en esta pantalla -- el que
  /// viaja al backend lo vuelve a resolver BookingBloc desde las coordenadas.
  final String? sector;

  /// Los polígonos a dibujar y el encuadre permitido del mapa. Se cargan una
  /// vez al abrir la pantalla; vacíos si el archivo no se pudo leer, caso en el
  /// que el mapa se comporta como antes (sin límites ni validación).
  final List<SectorEntity> sectors;
  final SectorBounds? coverageBounds;

  final FailureCode? errorCode;

  const MapPickerState({
    this.status = MapPickerStatus.initial,
    this.latitude = 0,
    this.longitude = 0,
    this.address,
    this.sector,
    this.sectors = const [],
    this.coverageBounds,
    this.errorCode,
  });

  MapPickerState copyWith({
    MapPickerStatus? status,
    double? latitude,
    double? longitude,
    String? address,
    String? sector,
    List<SectorEntity>? sectors,
    SectorBounds? coverageBounds,
    FailureCode? errorCode,
    bool clearSector = false,
  }) {
    return MapPickerState(
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      sector: clearSector ? null : (sector ?? this.sector),
      sectors: sectors ?? this.sectors,
      coverageBounds: coverageBounds ?? this.coverageBounds,
      errorCode: errorCode ?? this.errorCode,
    );
  }
}

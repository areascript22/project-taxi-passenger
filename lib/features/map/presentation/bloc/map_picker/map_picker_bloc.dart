import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:passenger_app/core/error/errors.dart';
import 'package:passenger_app/shared/geocoding/domain/repository/geocoding_repository.dart';
import 'package:passenger_app/shared/sectors/domain/entity/sector_entity.dart';
import 'package:passenger_app/shared/sectors/domain/service/sector_service.dart';
import 'package:passenger_app/shared/utils/debouncer.dart';

part 'map_picker_event.dart';

part 'map_picker_state.dart';

class MapPickerBloc extends Bloc<MapPickerEvent, MapPickerState> {
  final GeocodingRepository geocodingRepository;
  final SectorService sectorService;

  MapPickerBloc({
    required this.geocodingRepository,
    required this.sectorService,
  }) : super(const MapPickerState()) {
    on<MapCenterInitialized>(_onMapCenterInitialized);
    on<MapCameraIdle>(
      _onMapCameraIdle,
      transformer: debounce(const Duration(milliseconds: 500)),
    );
  }

  Future<void> _onMapCenterInitialized(
    MapCenterInitialized event,
    Emitter<MapPickerState> emit,
  ) async {
    // Los sectores se cargan una vez al abrir la pantalla: la vista los dibuja
    // y usa su caja para no dejar al usuario salirse de Riobamba.
    final sectorsResult = await sectorService.loadSectors();
    final sectors = sectorsResult.getOrElse(() => const []);
    final boundsResult = await sectorService.coverageBounds();

    emit(
      state.copyWith(
        status: MapPickerStatus.loadingAddress,
        latitude: event.latitude,
        longitude: event.longitude,
        sectors: sectors,
        coverageBounds: boundsResult.fold((_) => null, (bounds) => bounds),
      ),
    );

    await _fetchAddress(
      latitude: event.latitude,
      longitude: event.longitude,
      emit: emit,
    );
  }

  // Debounced + switchMap (see debounce()): if the map is dragged again
  // before this finishes, the stale in-flight fetch's emit is cancelled
  // and only the latest position's address is applied.
  Future<void> _onMapCameraIdle(
    MapCameraIdle event,
    Emitter<MapPickerState> emit,
  ) async {
    emit(
      state.copyWith(
        status: MapPickerStatus.loadingAddress,
        latitude: event.latitude,
        longitude: event.longitude,
      ),
    );

    await _fetchAddress(
      latitude: event.latitude,
      longitude: event.longitude,
      emit: emit,
    );
  }

  Future<void> _fetchAddress({
    required double latitude,
    required double longitude,
    required Emitter<MapPickerState> emit,
  }) async {
    // El sector se resuelve ANTES de geocodificar: esto corre en cada parada de
    // la cámara, así que fuera de cobertura nos ahorramos una llamada a
    // Geocoding por cada arrastre del mapa.
    final sectorResult = await sectorService.sectorFor(
      latitude: latitude,
      longitude: longitude,
    );
    // Un fallo al leer el archivo no bloquea el mapa: se sigue como antes de
    // que existieran los sectores (se geocodifica y se deja confirmar).
    final verified = sectorResult.isRight();
    final sector = sectorResult.fold((_) => null, (value) => value?.name);

    if (verified && sector == null) {
      emit(
        state.copyWith(
          status: MapPickerStatus.outOfCoverage,
          clearSector: true,
        ),
      );
      return;
    }

    final result = await geocodingRepository.getAddressFromCoordinates(
      lat: latitude,
      lng: longitude,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: MapPickerStatus.error,
          errorCode: failure.code,
        ),
      ),
      (address) => emit(
        state.copyWith(
          status: MapPickerStatus.addressReady,
          address: address,
          sector: sector,
          clearSector: sector == null,
        ),
      ),
    );
  }
}

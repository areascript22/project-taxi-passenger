import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:passenger_app/core/error/errors.dart';
import 'package:passenger_app/shared/domain/entity/user_location.dart';
import 'package:passenger_app/shared/geocoding/domain/repository/geocoding_repository.dart';
import 'package:passenger_app/shared/geolocator/service/geolocator/geolocator_service.dart';
import 'package:passenger_app/shared/geolocator/service/last_location/last_location_service.dart';
import 'package:passenger_app/shared/sectors/domain/entity/sector_entity.dart';
import 'package:passenger_app/shared/sectors/domain/service/sector_service.dart';
import 'package:passenger_app/shared/utils/debouncer.dart';

part 'map_picker_event.dart';

part 'map_picker_state.dart';

class MapPickerBloc extends Bloc<MapPickerEvent, MapPickerState> {
  final GeocodingRepository geocodingRepository;
  final SectorService sectorService;
  final GeolocatorService geolocatorService;
  final LastLocationService lastLocationService;

  // Centro de Riobamba: donde se abre el mapa si no hay ubicacion del usuario.
  static const double riobambaLatitude = -1.6702;
  static const double riobambaLongitude = -78.6631;

  MapPickerBloc({
    required this.geocodingRepository,
    required this.sectorService,
    required this.geolocatorService,
    required this.lastLocationService,
  }) : super(const MapPickerState()) {
    on<MapPickerStarted>(_onStarted);
    on<MapCenterInitialized>(_onMapCenterInitialized);
    on<MapCameraIdle>(
      _onMapCameraIdle,
      transformer: debounce(const Duration(milliseconds: 500)),
    );
  }

  // Donde abrir el mapa, por orden: el punto ya conocido, la ultima ubicacion
  // guardada (instantanea), el GPS (y se guarda para la proxima) y, si nada de
  // eso hay, el centro de Riobamba. Solo se resuelve una vez al abrir: despues
  // el mapa no se vuelve a mover solo.
  Future<void> _onStarted(
    MapPickerStarted event,
    Emitter<MapPickerState> emit,
  ) async {
    emit(state.copyWith(status: MapPickerStatus.resolvingCenter));

    var latitude = event.latitude;
    var longitude = event.longitude;

    if (latitude == null || longitude == null) {
      final cached = await lastLocationService.getLastLocation();
      final cachedLocation = cached.fold<UserLocation?>((_) => null, (l) => l);

      if (cachedLocation != null) {
        latitude = cachedLocation.latitude;
        longitude = cachedLocation.longitude;
      } else {
        final current = await geolocatorService.getCurrentPosition();
        final currentLocation = current.fold<UserLocation?>((_) => null, (l) => l);

        if (currentLocation != null) {
          latitude = currentLocation.latitude;
          longitude = currentLocation.longitude;
          await lastLocationService.saveLastLocation(location: currentLocation);
        } else {
          latitude = riobambaLatitude;
          longitude = riobambaLongitude;
        }
      }
    }

    await _onMapCenterInitialized(
      MapCenterInitialized(latitude: latitude, longitude: longitude),
      emit,
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

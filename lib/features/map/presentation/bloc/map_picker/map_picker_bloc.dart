import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:passenger_app/shared/geocoding/domain/repository/geocoding_repository.dart';
import 'package:passenger_app/shared/utils/debouncer.dart';

part 'map_picker_event.dart';

part 'map_picker_state.dart';

class MapPickerBloc extends Bloc<MapPickerEvent, MapPickerState> {
  final GeocodingRepository geocodingRepository;

  MapPickerBloc({required this.geocodingRepository})
    : super(const MapPickerState()) {
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
    final result = await geocodingRepository.getAddressFromCoordinates(
      lat: latitude,
      lng: longitude,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: MapPickerStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (address) => emit(
        state.copyWith(status: MapPickerStatus.addressReady, address: address),
      ),
    );
  }
}

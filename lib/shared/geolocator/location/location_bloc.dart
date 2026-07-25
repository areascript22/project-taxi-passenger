import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:passenger_app/shared/geolocator/service/geolocator/geolocator_service.dart';
import '../../domain/entity/user_location.dart';

part 'location_event.dart';

part 'location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final GeolocatorService locationService;

  LocationBloc({required this.locationService}) : super(LocationState()) {
    on<CheckAndRequestPermissionEvent>(_onCheckAndRequestPermission);
    on<FetchCurrentLocationEvent>(_onFetchCurrentLocation);
    on<OpenAppSettingsEvent>(_onOpenAppSettings);
  }

  Future<void> _onCheckAndRequestPermission(
    CheckAndRequestPermissionEvent event,
    Emitter<LocationState> emit,
  ) async {
    emit(state.copyWith(locationProcess: LocationProcess.checkingPermissions));

    final result = await locationService.checkAndRequestPermission();

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            locationProcess: LocationProcess.permissionsError,
            errorMessage: failure.message,
          ),
        );
      },
      (locationPermission) {
        emit(
          state.copyWith(
            locationProcess: LocationProcess.permissionsReady,
            permissionStatus: locationPermission,
            errorMessage: null,
          ),
        );
      },
    );
  }

  Future<void> _onFetchCurrentLocation(
    FetchCurrentLocationEvent event,
    Emitter<LocationState> emit,
  ) async {
    emit(state.copyWith(locationProcess: LocationProcess.gettingCurrentCords));
    if (state.permissionStatus == LocationPermission.denied ||
        state.permissionStatus == LocationPermission.deniedForever) {
      emit(
        state.copyWith(
          locationProcess: LocationProcess.permissionsError,
          errorMessage: "No tiene permisos de ubicación.",
        ),
      );
      return;
    }

    final result = await locationService.getCurrentPosition();
    result.fold(
      (failure) => emit(
        state.copyWith(
          locationProcess: LocationProcess.currentCordsError,
          errorMessage: failure.message,
        ),
      ),
      (location) => emit(
        state.copyWith(
          locationProcess: LocationProcess.currentCordsReady,
          lastKnownLocation: location,
        ),
      ),
    );
  }

  Future<void> _onOpenAppSettings(
    OpenAppSettingsEvent event,
    Emitter<LocationState> emit,
  ) async {
    await locationService.openAppSettings();
  }
}

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import '../../domain/entity/ride_entity.dart';
import '../../domain/repository/ride_tracking_repository.dart';

part 'ride_tracking_event.dart';
part 'ride_tracking_state.dart';

class RideTrackingBloc extends Bloc<RideTrackingEvent, RideTrackingState> {
  final RideTrackingRepository repository;
  StreamSubscription<RideEntity>? _subscription;

  RideTrackingBloc({required this.repository})
    : super(const RideTrackingState()) {
    on<StartRideTracking>(_onStart);
    on<RideUpdated>(_onRideUpdated);
    on<StopRideTracking>(_onStop);
  }

  Future<void> _onStart(
    StartRideTracking event,
    Emitter<RideTrackingState> emit,
  ) async {
    emit(state.copyWith(status: RideTrackingStatus.connecting));

    await _subscription?.cancel();

    _subscription = repository
        .watchRideTrack(passengerId: event.passengerId)
        .listen((ride) {
          add(RideUpdated(ride));
        });
  }

  void _onRideUpdated(RideUpdated event, Emitter<RideTrackingState> emit) {
    final ride = event.ride;
    debugPrint("Ride update event called ; ${ride}");
    emit(state.copyWith(status: ride.rideStatus));
  }

  Future<void> _onStop(StopRideTracking event, Emitter<RideTrackingState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = null;
    emit(const RideTrackingState());
  }
}

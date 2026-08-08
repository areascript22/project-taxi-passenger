import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:passenger_app/features/ride_tracking/domain/repository/ride_tracking_repository.dart';
import 'package:passenger_app/shared/domain/repository/session_repository.dart';
import '../../../domain/entity/user_entity.dart';

part 'session_event.dart';
part 'session_state.dart';

class SessionBloc extends Bloc<SessionEvent, SessionState> {
  final SessionRepository sessionRepository;
  final RideTrackingRepository rideTrackingRepository;

  SessionBloc({
    required this.sessionRepository,
    required this.rideTrackingRepository,
  }) : super(SessionUnknown()) {
    on<SessionCheckRequested>(_onCheckRequested);
    on<SessionUserUpdated>(_onUserUpdated);
    on<SessionLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckRequested(
    SessionCheckRequested event,
    Emitter<SessionState> emit,
  ) async {
    final result = await sessionRepository.isUserAuthenticated();

    final user = result.fold((failure) => null, (user) => user);
    if (user == null) {
      emit(SessionUnauthenticated());
      return;
    }

    final activeRideResult = await rideTrackingRepository.getActiveRide(
      passengerId: user.id,
    );
    final hasActiveRide = activeRideResult.fold(
      (_) => false,
      (ride) => ride != null,
    );

    emit(SessionAuthenticated(user: user, hasActiveRide: hasActiveRide));
  }

  void _onUserUpdated(SessionUserUpdated event, Emitter<SessionState> emit) {
    emit(SessionAuthenticated(user: event.user));
  }

  Future<void> _onLogoutRequested(SessionLogoutRequested event,
      Emitter<SessionState> emit,) async {
    final response = await sessionRepository.signOut();
    response.fold(
            (failure) => emit(state),
            (unit) =>
        emit(SessionUnauthenticated()));
  }
}

part of 'session_bloc.dart';

@immutable
sealed class SessionState {}

final class SessionUnknown extends SessionState {}

final class SessionAuthenticated extends SessionState {
  final UserEntity user;
  // true si el pasajero tiene un viaje en curso (conductor asignado en
  // adelante). Se resuelve al chequear la sesión para decidir si hay que
  // resumir RideTrackingScreen en vez de ir a BookingScreen.
  final bool hasActiveRide;

  SessionAuthenticated({required this.user, this.hasActiveRide = false});
}

final class SessionUnauthenticated extends SessionState {}

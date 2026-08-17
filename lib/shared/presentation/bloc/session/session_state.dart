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

// El usuario ya se autenticó con Google pero todavía no tiene datos de
// pasajero guardados en Firestore -- debe completar el registro (datos
// personales + foto de perfil) antes de continuar.
final class SessionOnboardingRequired extends SessionState {
  final UserEntity user;

  SessionOnboardingRequired({required this.user});
}

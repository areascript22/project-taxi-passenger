part of 'session_bloc.dart';

@immutable
sealed class SessionState {}

final class SessionUnknown extends SessionState {}

final class SessionAuthenticated extends SessionState {
  final UserEntity user;
  // Viaje en curso del pasajero, si lo hay (incluye 'pending' -- solicitud
  // ya escrita en Firebase pero sin conductor asignado todavía). Se resuelve
  // al chequear la sesión para decidir a dónde navegar: null -> BookingScreen
  // normal, waitingDriver -> BookingScreen resumiendo el diálogo "Buscando
  // conductor", cualquier otro status activo -> RideTrackingScreen directo.
  final RideEntity? activeRide;

  SessionAuthenticated({required this.user, this.activeRide});
}

final class SessionUnauthenticated extends SessionState {}

// El usuario ya se autenticó con Google pero todavía no tiene datos de
// pasajero guardados en Firestore -- debe completar el registro (datos
// personales + foto de perfil) antes de continuar.
final class SessionOnboardingRequired extends SessionState {
  final UserEntity user;

  SessionOnboardingRequired({required this.user});
}

// El usuario está autenticado pero no se pudo verificar si tiene datos de
// pasajero guardados (error de red, permisos, etc.) -- distinto de
// SessionOnboardingRequired: acá NO sabemos si el pasajero ya existe, así
// que no se debe mandar a re-registrar, sino permitir reintentar.
final class SessionCheckFailed extends SessionState {
  final UserEntity user;

  SessionCheckFailed({required this.user});
}

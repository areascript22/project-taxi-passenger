part of 'auth_bloc.dart';

@immutable
sealed class AuthState {}

final class AuthInitial extends AuthState {}

final class AuthLoading extends AuthState {}

final class AuthAuthenticated extends AuthState {}

final class AuthUnauthenticated extends AuthState {}

// NUEVO: Estado para emitir los errores capturados por el repositorio
final class AuthError extends AuthState {
  final String message;

  AuthError(this.message);
}
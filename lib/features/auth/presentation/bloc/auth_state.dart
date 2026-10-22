part of 'auth_bloc.dart';

@immutable
sealed class AuthState {}

final class AuthInitial extends AuthState {}

final class AuthLoading extends AuthState {}

final class AuthAuthenticated extends AuthState {
  final UserEntity user;

  AuthAuthenticated({required this.user});
}

final class AuthError extends AuthState {
  // Lleva el codigo, no el texto: el texto lo resuelve la pantalla con
  // context.failureText(code) -- ver core/error/errors.dart.
  final FailureCode code;

  AuthError(this.code);
}
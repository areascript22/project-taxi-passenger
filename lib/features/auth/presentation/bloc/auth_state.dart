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
  final String message;

  AuthError(this.message);
}
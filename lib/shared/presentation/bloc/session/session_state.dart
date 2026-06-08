part of 'session_bloc.dart';

@immutable
sealed class SessionState {}

final class SessionUnknown extends SessionState {}

final class SessionAuthenticated extends SessionState {
  final UserEntity user;
  SessionAuthenticated({required this.user});
}

final class SessionUnauthenticated extends SessionState {}

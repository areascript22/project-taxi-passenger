part of 'session_bloc.dart';

@immutable
sealed class SessionEvent {}

class SessionCheckRequested extends SessionEvent {}

class SessionUserUpdated extends SessionEvent {
  final UserEntity user;

  SessionUserUpdated(this.user);
}

class SessionLogoutRequested extends SessionEvent {}

part of 'session_bloc.dart';

@immutable
sealed class SessionEvent {}

class SessionCheckRequested extends SessionEvent {}

class SessionLogoutRequested extends SessionEvent {}

part of 'profile_bloc.dart';

@immutable
sealed class ProfileEvent {}

class ProfileLoadRequested extends ProfileEvent {
  final String passengerId;

  ProfileLoadRequested({required this.passengerId});
}

// Se dispara al entrar a la screen de edición para limpiar cualquier imagen
// local o error que haya quedado de un intento anterior.
class ProfileEditStarted extends ProfileEvent {}

class ProfileImagePicked extends ProfileEvent {
  final ProfileImageSource source;

  ProfileImagePicked(this.source);
}

class ProfileUpdateSubmitted extends ProfileEvent {
  final String firstName;
  final String lastName;

  ProfileUpdateSubmitted({required this.firstName, required this.lastName});
}

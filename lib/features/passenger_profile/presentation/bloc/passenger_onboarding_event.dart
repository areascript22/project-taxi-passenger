part of 'passenger_onboarding_bloc.dart';

@immutable
sealed class PassengerOnboardingEvent {}

class PassengerOnboardingStarted extends PassengerOnboardingEvent {
  final UserEntity user;

  PassengerOnboardingStarted(this.user);
}

class PassengerOnboardingImagePicked extends PassengerOnboardingEvent {
  final ProfileImageSource source;

  PassengerOnboardingImagePicked(this.source);
}

class PassengerOnboardingSubmitted extends PassengerOnboardingEvent {
  final String firstName;
  final String lastName;

  PassengerOnboardingSubmitted({
    required this.firstName,
    required this.lastName,
  });
}

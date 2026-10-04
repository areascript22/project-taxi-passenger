part of 'passenger_onboarding_bloc.dart';

@immutable
class PassengerOnboardingState {
  final UserEntity? user;
  final File? profileImage;
  final bool isPickingImage;
  final bool isSubmitting;
  final FailureCode? errorCode;
  final bool registrationSuccess;

  const PassengerOnboardingState({
    this.user,
    this.profileImage,
    this.isPickingImage = false,
    this.isSubmitting = false,
    this.errorCode,
    this.registrationSuccess = false,
  });

  PassengerOnboardingState copyWith({
    UserEntity? user,
    File? profileImage,
    bool? isPickingImage,
    bool? isSubmitting,
    FailureCode? errorCode,
    bool? registrationSuccess,
  }) {
    return PassengerOnboardingState(
      user: user ?? this.user,
      profileImage: profileImage ?? this.profileImage,
      isPickingImage: isPickingImage ?? this.isPickingImage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorCode: errorCode,
      registrationSuccess: registrationSuccess ?? this.registrationSuccess,
    );
  }
}

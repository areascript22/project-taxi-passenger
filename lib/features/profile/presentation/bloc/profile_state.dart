part of 'profile_bloc.dart';

@immutable
class ProfileState {
  final bool isLoading;
  final PassengerEntity? passenger;
  final File? localImage;
  final bool isPickingImage;
  final bool isSubmitting;
  final String? errorMessage;
  // Flag de un solo uso: la UI lo consume para mostrar un snackbar de éxito
  // y luego queda en false en cualquier emisión posterior.
  final bool updateSuccess;

  const ProfileState({
    this.isLoading = false,
    this.passenger,
    this.localImage,
    this.isPickingImage = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.updateSuccess = false,
  });

  ProfileState copyWith({
    bool? isLoading,
    PassengerEntity? passenger,
    File? localImage,
    bool clearLocalImage = false,
    bool? isPickingImage,
    bool? isSubmitting,
    String? errorMessage,
    bool? updateSuccess,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      passenger: passenger ?? this.passenger,
      localImage: clearLocalImage ? null : (localImage ?? this.localImage),
      isPickingImage: isPickingImage ?? this.isPickingImage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      updateSuccess: updateSuccess ?? false,
    );
  }
}

import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import '../../../../shared/domain/entity/user_entity.dart';
import '../../../../shared/image_picker/service/profile_image_picker_service.dart';
import '../../domain/entity/passenger_entity.dart';
import '../../domain/repository/passenger_profile_repository.dart';

part 'passenger_onboarding_event.dart';
part 'passenger_onboarding_state.dart';

class PassengerOnboardingBloc
    extends Bloc<PassengerOnboardingEvent, PassengerOnboardingState> {
  final PassengerProfileRepository passengerProfileRepository;
  final ProfileImagePickerService imagePickerService;

  PassengerOnboardingBloc({
    required this.passengerProfileRepository,
    required this.imagePickerService,
  }) : super(const PassengerOnboardingState()) {
    on<PassengerOnboardingStarted>(_onStarted);
    on<PassengerOnboardingImagePicked>(_onImagePicked);
    on<PassengerOnboardingSubmitted>(_onSubmitted);
  }

  void _onStarted(
    PassengerOnboardingStarted event,
    Emitter<PassengerOnboardingState> emit,
  ) {
    emit(state.copyWith(user: event.user));
  }

  Future<void> _onImagePicked(
    PassengerOnboardingImagePicked event,
    Emitter<PassengerOnboardingState> emit,
  ) async {
    emit(state.copyWith(isPickingImage: true, errorMessage: null));

    final result = await imagePickerService.pickImage(source: event.source);

    result.fold(
      (failure) => emit(
        state.copyWith(isPickingImage: false, errorMessage: failure.message),
      ),
      (file) {
        if (file == null) {
          emit(state.copyWith(isPickingImage: false));
          return;
        }
        emit(state.copyWith(isPickingImage: false, profileImage: file));
      },
    );
  }

  Future<void> _onSubmitted(
    PassengerOnboardingSubmitted event,
    Emitter<PassengerOnboardingState> emit,
  ) async {
    final user = state.user;
    if (user == null) {
      return;
    }

    emit(state.copyWith(isSubmitting: true, errorMessage: null));

    final passenger = PassengerEntity(
      id: user.id,
      firstName: event.firstName,
      lastName: event.lastName,
      email: user.email ?? '',
      photoUrl: user.photoUrl,
    );

    final result = await passengerProfileRepository.registerPassenger(
      passenger: passenger,
      profileImage: state.profileImage,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(isSubmitting: false, errorMessage: failure.message),
      ),
      (_) => emit(
        state.copyWith(isSubmitting: false, registrationSuccess: true),
      ),
    );
  }
}

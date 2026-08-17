import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import '../../../passenger_profile/domain/entity/passenger_entity.dart';
import '../../../passenger_profile/domain/repository/passenger_profile_repository.dart';
import '../../../../shared/image_picker/service/profile_image_picker_service.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final PassengerProfileRepository passengerProfileRepository;
  final ProfileImagePickerService imagePickerService;

  ProfileBloc({
    required this.passengerProfileRepository,
    required this.imagePickerService,
  }) : super(const ProfileState()) {
    on<ProfileLoadRequested>(_onLoadRequested);
    on<ProfileEditStarted>(_onEditStarted);
    on<ProfileImagePicked>(_onImagePicked);
    on<ProfileUpdateSubmitted>(_onUpdateSubmitted);
  }

  Future<void> _onLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    final result = await passengerProfileRepository.getPassenger(
      passengerId: event.passengerId,
    );

    final passenger = result.fold((failure) => null, (passenger) => passenger);
    if (passenger == null) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'No se pudo cargar tu información',
        ),
      );
      return;
    }

    emit(state.copyWith(isLoading: false, passenger: passenger));
  }

  void _onEditStarted(ProfileEditStarted event, Emitter<ProfileState> emit) {
    emit(state.copyWith(clearLocalImage: true, errorMessage: null));
  }

  Future<void> _onImagePicked(
    ProfileImagePicked event,
    Emitter<ProfileState> emit,
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
        emit(state.copyWith(isPickingImage: false, localImage: file));
      },
    );
  }

  Future<void> _onUpdateSubmitted(
    ProfileUpdateSubmitted event,
    Emitter<ProfileState> emit,
  ) async {
    final current = state.passenger;
    if (current == null) return;

    emit(state.copyWith(isSubmitting: true, errorMessage: null));

    final updated = PassengerEntity(
      id: current.id,
      firstName: event.firstName,
      lastName: event.lastName,
      email: current.email,
      photoUrl: current.photoUrl,
      fcmToken: current.fcmToken,
      status: current.status,
      createdAt: current.createdAt,
      updatedAt: current.updatedAt,
    );

    final result = await passengerProfileRepository.updatePassenger(
      passenger: updated,
      profileImage: state.localImage,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(isSubmitting: false, errorMessage: failure.message),
      ),
      (savedPassenger) => emit(
        state.copyWith(
          isSubmitting: false,
          passenger: savedPassenger,
          clearLocalImage: true,
          updateSuccess: true,
        ),
      ),
    );
  }
}

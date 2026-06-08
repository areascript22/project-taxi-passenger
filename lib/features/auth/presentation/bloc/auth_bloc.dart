import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:passenger_app/features/auth/domain/repository/auth_repository.dart';
import '../../../../shared/domain/entity/user_entity.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<AuthSignInWithGoogle>(_onSignInWithGoogle);
  }

  Future<void> _onSignInWithGoogle(
    AuthSignInWithGoogle event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await authRepository.signInWithGoogle();

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user: user)),
    );
  }
}

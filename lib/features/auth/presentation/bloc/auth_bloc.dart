import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:passenger_app/features/auth/domain/repository/auth_repository.dart';

part 'auth_event.dart';

part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    // Registramos los eventos y los enlazamos a sus manejadores privados
    on<AuthSignInWithGoogle>(_onSignInWithGoogle);
    on<AuthCheckRequested>(_onAuthCheckRequested); // NUEVO
  }

  Future<void> _onSignInWithGoogle(
    AuthSignInWithGoogle event,
    Emitter<AuthState> emit,
  ) async {
    // 1. Emitimos el estado de carga para que la UI muestre el CircularProgressIndicator
    emit(AuthLoading());

    // 2. Ejecutamos el caso de uso/repositorio
    final result = await authRepository.signInWithGoogle();

    // 3. Manejamos el Either usando el método fold de Dartz
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      // Lado Izquierdo: Falla
      (_) => emit(AuthAuthenticated()), // Lado Derecho: Éxito (Unit)
    );
  }

  // NUEVO: Manejador para verificar si el usuario ya tiene sesión iniciada
  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Ejecutamos la verificación en el repositorio
    final result = await authRepository.isUserAuthenticated();

    // Manejamos el resultado
    result.fold(
      // Si ocurre un error inesperado al consultar Firebase
      (failure) => emit(AuthError(failure.message)),

      // Si la consulta es exitosa, evaluamos el booleano
      (isAuthenticated) {
        if (isAuthenticated) {
          emit(AuthAuthenticated());
        } else {
          emit(AuthUnauthenticated());
        }
      },
    );
  }
}

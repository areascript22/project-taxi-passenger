import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:passenger_app/core/error/errors.dart';
import 'package:passenger_app/shared/account/domain/repository/account_repository.dart';

@immutable
class AccountState {
  final bool isDeleting;
  final FailureCode? errorCode;
  final bool wasDeleted;

  const AccountState({
    this.isDeleting = false,
    this.errorCode,
    this.wasDeleted = false,
  });

  AccountState copyWith({
    bool? isDeleting,
    FailureCode? errorCode,
    bool? wasDeleted,
    bool clearError = false,
  }) {
    return AccountState(
      isDeleting: isDeleting ?? this.isDeleting,
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      wasDeleted: wasDeleted ?? this.wasDeleted,
    );
  }
}

// Cubit propio para la autoeliminación de cuenta desde Settings: una sola
// acción destructiva, sin necesitar un Bloc con varios eventos.
class AccountCubit extends Cubit<AccountState> {
  final AccountRepository accountRepository;

  AccountCubit({required this.accountRepository}) : super(const AccountState());

  Future<void> deleteAccount() async {
    emit(state.copyWith(isDeleting: true, clearError: true));

    final result = await accountRepository.deleteAccount();

    // El borrado puede tardar decenas de segundos, tiempo más que suficiente
    // para que la pantalla de Settings se desmonte y BlocProvider cierre este
    // cubit. Sin este guard, el emit lanzaría StateError ("cannot emit new
    // states after calling close") y, como la UI llama deleteAccount() sin
    // await, el error se perdería como error async no manejado: ni SnackBar
    // ni logout, sin ninguna pista en consola.
    if (isClosed) {
      debugPrint(
        'AccountDebug | deleteAccount terminó con el cubit ya cerrado; '
        'no se emite estado (resultado: ${result.isRight() ? "éxito" : "error"})',
      );
      return;
    }

    result.fold(
      (failure) {
        debugPrint('AccountDebug | deleteAccount falló: ${failure.code}');
        emit(state.copyWith(isDeleting: false, errorCode: failure.code));
      },
      (_) {
        debugPrint('AccountDebug | deleteAccount OK, emitiendo wasDeleted');
        emit(state.copyWith(isDeleting: false, wasDeleted: true));
      },
    );
  }
}

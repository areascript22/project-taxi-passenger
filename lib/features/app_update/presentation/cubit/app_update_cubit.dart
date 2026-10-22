import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:passenger_app/core/error/errors.dart';
import 'package:passenger_app/features/app_update/domain/repository/app_update_repository.dart';
import 'package:passenger_app/features/app_update/domain/service/store_launcher_service.dart';

part 'app_update_state.dart';

// Vive durante todo el ciclo de vida de la app (singleton de GetIt, provisto
// una sola vez en main.dart): la pantalla de "actualiza" tiene que poder
// cubrir cualquier ruta, así que su estado no depende de qué feature esté
// montada.
class AppUpdateCubit extends Cubit<AppUpdateState> {
  AppUpdateCubit({
    required this.repository,
    required this.storeLauncher,
  }) : super(const AppUpdateState());

  final AppUpdateRepository repository;
  final StoreLauncherService storeLauncher;

  /// Consulta si esta versión todavía se admite.
  ///
  /// Falla ABIERTO: si no se puede consultar (sin internet, servidor caído) la
  /// app sigue funcionando. Solo se bloquea cuando el servidor dice
  /// explícitamente que la versión es demasiado vieja -- un corte de red no
  /// debe dejar a todos los pasajeros sin poder pedir un taxi.
  Future<void> check() async {
    if (state.status == AppUpdateStatus.checking) return;
    emit(state.copyWith(status: AppUpdateStatus.checking));

    final result = await repository.checkUpdate();
    result.fold(
      (failure) {
        debugPrint(
          'AppUpdateDebug | No se pudo consultar la versión mínima '
          '(${failure.code}); la app sigue',
        );
        emit(state.copyWith(status: AppUpdateStatus.allowed));
      },
      (requirement) {
        emit(
          state.copyWith(
            status:
                requirement.updateRequired
                    ? AppUpdateStatus.updateRequired
                    : AppUpdateStatus.allowed,
            minimumVersion: requirement.minimumVersion,
            storeUrl: requirement.storeUrl,
          ),
        );
      },
    );
  }

  /// Abre la ficha de la app en la tienda.
  Future<void> openStore() async {
    // Solo se emite si había un error que limpiar: sin él, un estado idéntico
    // reconstruiría la pantalla para nada.
    if (state.errorCode != null) {
      emit(state.copyWith(clearError: true));
    }

    final result = await storeLauncher.open(url: state.storeUrl);
    result.fold(
      (failure) => emit(state.copyWith(errorCode: failure.code)),
      (_) {},
    );
  }
}

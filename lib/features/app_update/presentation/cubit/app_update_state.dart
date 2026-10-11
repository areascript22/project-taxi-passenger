part of 'app_update_cubit.dart';

/// unknown: todavía no se consultó. checking: consulta en curso. allowed: la
/// versión se admite -- o no se pudo consultar, que se trata igual (ver
/// [AppUpdateCubit.check]). updateRequired: el servidor dijo que esta versión
/// ya no se admite.
enum AppUpdateStatus { unknown, checking, allowed, updateRequired }

@immutable
class AppUpdateState {
  const AppUpdateState({
    this.status = AppUpdateStatus.unknown,
    this.minimumVersion = '',
    this.storeUrl = '',
    this.errorCode,
  });

  final AppUpdateStatus status;
  final String minimumVersion;
  final String storeUrl;

  /// Por qué no se pudo abrir la tienda (solo para mostrar en la pantalla de
  /// actualización). La consulta de versión nunca deja error: si falla, la app
  /// sigue.
  final FailureCode? errorCode;

  bool get isUpdateRequired => status == AppUpdateStatus.updateRequired;

  AppUpdateState copyWith({
    AppUpdateStatus? status,
    String? minimumVersion,
    String? storeUrl,
    FailureCode? errorCode,
    bool clearError = false,
  }) {
    return AppUpdateState(
      status: status ?? this.status,
      minimumVersion: minimumVersion ?? this.minimumVersion,
      storeUrl: storeUrl ?? this.storeUrl,
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
    );
  }
}

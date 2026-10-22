import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import '../../domain/repository/connectivity_repository.dart';

part 'connectivity_state.dart';

// Vive durante todo el ciclo de vida de la app (registrado como singleton en
// connectivity_service_locator.dart y provisto una sola vez en main.dart):
// el banner de "sin conexión" tiene que poder mostrarse sobre cualquier
// pantalla, así que su estado no puede depender de qué feature esté montada
// en un momento dado.
class ConnectivityCubit extends Cubit<ConnectivityState> {
  ConnectivityCubit({required this.repository})
    : super(const ConnectivityState()) {
    _startWatching();
  }

  final ConnectivityRepository repository;
  StreamSubscription<bool>? _subscription;

  void _startWatching() {
    try {
      _subscription = repository.watchConnection().listen(
        (isOnline) {
          emit(
            state.copyWith(
              status:
                  isOnline
                      ? ConnectivityStatus.online
                      : ConnectivityStatus.offline,
            ),
          );
        },
        onError: (Object error) {
          // Ante la duda (el propio stream de conectividad falló) se asume
          // lo más conservador para el usuario: mostrar el banner en vez de
          // confiar en un último estado "online" que puede estar obsoleto.
          debugPrint(
            'ConnectivityDebug | Error en el stream de watchConnection: $error',
          );
          emit(state.copyWith(status: ConnectivityStatus.offline));
        },
      );
    } catch (e) {
      debugPrint(
        'ConnectivityDebug | Error inesperado al suscribirse a '
        'watchConnection: $e',
      );
      emit(state.copyWith(status: ConnectivityStatus.offline));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

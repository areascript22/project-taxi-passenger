part of 'connectivity_cubit.dart';

// unknown es el instante entre que arranca la app y llega la primera
// lectura real de ConnectivityRepository -- se trata igual que "online"
// en el banner (no parpadear un aviso de "sin conexión" en cada cold start
// mientras se resuelve el primer chequeo).
enum ConnectivityStatus { unknown, online, offline }

@immutable
class ConnectivityState {
  const ConnectivityState({this.status = ConnectivityStatus.unknown});

  final ConnectivityStatus status;

  bool get isOffline => status == ConnectivityStatus.offline;

  ConnectivityState copyWith({ConnectivityStatus? status}) {
    return ConnectivityState(status: status ?? this.status);
  }
}

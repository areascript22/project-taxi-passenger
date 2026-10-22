import 'package:flutter/foundation.dart';

// Guarda el rideId de un push de chat tocado (foreground, background con la
// app viva, o cold-start con la app cerrada) hasta que RideTrackingScreen
// pueda abrir el chat de forma segura -- nunca navega directo desde el
// servicio de notificaciones porque en un cold-start esa pantalla todavía no
// existe (el SessionBloc recién está resolviendo si hay un viaje en curso).
// Un ValueNotifier permite cubrir los 3 casos con el mismo mecanismo: si
// RideTrackingScreen ya está montada, el listener dispara al instante; si
// no, la consulta inicial en su initState/listener recoge el valor que haya
// quedado pendiente de antes de montarse.
class PendingChatNavigationTracker {
  final ValueNotifier<String?> pendingRideId = ValueNotifier<String?>(null);

  void request({required String rideId}) {
    pendingRideId.value = rideId;
  }

  // Consume el pedido solo si es de la misma carrera que se está mostrando
  // -- evita abrir el chat equivocado si hay un pedido viejo de otra carrera
  // sin consumir.
  bool consumeIfMatches({required String rideId}) {
    if (pendingRideId.value != rideId) return false;
    pendingRideId.value = null;
    return true;
  }
}

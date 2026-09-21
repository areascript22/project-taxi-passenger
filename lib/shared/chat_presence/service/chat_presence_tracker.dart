import 'package:flutter/foundation.dart';

// Permite que el foreground handler de push notifications sepa si el chat de
// una carrera puntual está abierto en pantalla, para no duplicar el mensaje
// (el ChatScreen ya lo va a mostrar en vivo vía su stream de Firestore).
class ChatPresenceTracker {
  final ValueNotifier<String?> openRideId = ValueNotifier<String?>(null);

  void markOpen({required String rideId}) {
    openRideId.value = rideId;
  }

  // Compara el rideId antes de limpiar para no pisar el estado de un chat
  // distinto que se haya abierto entre el open y el dispose de este (por
  // ejemplo, navegación rápida entre dos carreras).
  void markClosed({required String rideId}) {
    if (openRideId.value == rideId) {
      openRideId.value = null;
    }
  }

  bool isOpen({required String rideId}) => openRideId.value == rideId;
}

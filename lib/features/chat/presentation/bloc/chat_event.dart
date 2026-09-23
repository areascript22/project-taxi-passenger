part of 'chat_bloc.dart';

@immutable
sealed class ChatEvent {}

class WatchMessages extends ChatEvent {
  WatchMessages({required this.rideId});

  final String rideId;
}

class _ChatMessagesUpdated extends ChatEvent {
  _ChatMessagesUpdated(this.messages);

  final List<ChatMessageEntity> messages;
}

// El stream de Firestore puede terminar en error (ej. permission-denied si
// el doc padre chats/{rideId} no existe o las reglas rechazan al usuario) --
// sin esto el error quedaba sin manejar y la pantalla se quedaba pegada en
// "Todavía no hay mensajes" para siempre, sin ninguna pista de qué pasó.
class _ChatMessagesErrored extends ChatEvent {
  _ChatMessagesErrored(this.error);

  final Object error;
}

class SendMessage extends ChatEvent {
  SendMessage({required this.passengerId, required this.text});

  final String passengerId;
  final String text;
}

// Se dispara cuando ChatScreen se abre (y en su reintento tras enviar) para
// limpiar el contador de mensajes sin leer que se muestra como badge en la
// pantalla anterior (RideTrackingScreen).
class MarkMessagesRead extends ChatEvent {}

class StopWatchingMessages extends ChatEvent {}

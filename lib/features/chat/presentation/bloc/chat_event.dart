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

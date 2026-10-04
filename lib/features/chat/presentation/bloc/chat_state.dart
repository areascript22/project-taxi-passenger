part of 'chat_bloc.dart';

@immutable
class ChatState {
  const ChatState({
    this.messages = const [],
    this.unreadCount = 0,
    this.isSending = false,
    this.errorCode,
  });

  final List<ChatMessageEntity> messages;
  final int unreadCount;
  final bool isSending;
  final FailureCode? errorCode;

  ChatState copyWith({
    List<ChatMessageEntity>? messages,
    int? unreadCount,
    bool? isSending,
    FailureCode? errorCode,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      unreadCount: unreadCount ?? this.unreadCount,
      isSending: isSending ?? this.isSending,
      // Siempre explícito: pasar null limpia el error anterior.
      errorCode: errorCode,
    );
  }
}

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import '../../domain/entity/chat_message_entity.dart';
import '../../domain/repository/chat_repository.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({required this.repository}) : super(const ChatState()) {
    on<WatchMessages>(_onWatch);
    on<_ChatMessagesUpdated>(_onMessagesUpdated);
    on<_ChatMessagesErrored>(_onMessagesErrored);
    on<SendMessage>(_onSendMessage);
    on<MarkMessagesRead>(_onMarkRead);
    on<StopWatchingMessages>(_onStop);
  }

  // Desde el punto de vista del pasajero, "sin leer" son los mensajes que
  // mandó el conductor -- los que manda el propio pasajero nunca cuentan
  // como no leídos para sí mismo.
  static const _otherSenderRole = 'driver';

  final ChatRepository repository;
  StreamSubscription<List<ChatMessageEntity>>? _subscription;
  DateTime? _lastReadAt;

  void _onWatch(WatchMessages event, Emitter<ChatState> emit) {
    _subscription?.cancel();
    _lastReadAt = null;
    _subscription = repository
        .watchMessages(rideId: event.rideId)
        .listen(
          (messages) => add(_ChatMessagesUpdated(messages)),
          onError: (Object error) => add(_ChatMessagesErrored(error)),
        );
  }

  void _onMessagesUpdated(_ChatMessagesUpdated event, Emitter<ChatState> emit) {
    final unreadSince = _lastReadAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final unreadCount =
        event.messages
            .where(
              (m) =>
                  m.senderRole == _otherSenderRole &&
                  m.createdAt.isAfter(unreadSince),
            )
            .length;

    emit(state.copyWith(messages: event.messages, unreadCount: unreadCount));
  }

  void _onMessagesErrored(_ChatMessagesErrored event, Emitter<ChatState> emit) {
    debugPrint('ChatDebug | Error en watchMessages: ${event.error}');
    emit(
      state.copyWith(
        errorMessage: 'No se pudieron cargar los mensajes. Intenta de nuevo.',
      ),
    );
  }

  Future<void> _onSendMessage(SendMessage event, Emitter<ChatState> emit) async {
    emit(state.copyWith(isSending: true, errorMessage: null));

    final result = await repository.sendMessage(
      passengerId: event.passengerId,
      text: event.text,
    );

    result.fold(
      (failure) =>
          emit(state.copyWith(isSending: false, errorMessage: failure.message)),
      // El stream de watchMessages ya va a traer el mensaje enviado.
      (_) => emit(state.copyWith(isSending: false)),
    );
  }

  void _onMarkRead(MarkMessagesRead event, Emitter<ChatState> emit) {
    _lastReadAt = DateTime.now();
    emit(state.copyWith(unreadCount: 0));
  }

  Future<void> _onStop(StopWatchingMessages event, Emitter<ChatState> emit) async {
    await _subscription?.cancel();
    _subscription = null;
    _lastReadAt = null;
    emit(const ChatState());
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

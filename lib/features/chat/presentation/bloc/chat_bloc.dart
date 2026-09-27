import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import '../../../../shared/connectivity/domain/repository/connectivity_repository.dart';
import '../../domain/entity/chat_message_entity.dart';
import '../../domain/repository/chat_repository.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({required this.repository, required this.connectivityRepository})
    : super(const ChatState()) {
    on<WatchMessages>(_onWatch);
    on<_ChatMessagesUpdated>(_onMessagesUpdated);
    on<_ChatMessagesErrored>(_onMessagesErrored);
    on<SendMessage>(_onSendMessage);
    on<MarkMessagesRead>(_onMarkRead);
    on<StopWatchingMessages>(_onStop);
    on<_ConnectivityRestored>(_onConnectivityRestored);
    _startWatchingConnectivity();
  }

  // Desde el punto de vista del pasajero, "sin leer" son los mensajes que
  // mandó el conductor -- los que manda el propio pasajero nunca cuentan
  // como no leídos para sí mismo.
  static const _otherSenderRole = 'driver';

  final ChatRepository repository;
  final ConnectivityRepository connectivityRepository;
  StreamSubscription<List<ChatMessageEntity>>? _subscription;
  StreamSubscription<bool>? _connectivitySubscription;
  DateTime? _lastReadAt;

  // rideId de la última carrera para la que se pidió WatchMessages. Se usa
  // para poder re-suscribir el stream de Firestore cuando vuelve la
  // conexión, sin depender de que la pantalla de chat siga montada (este
  // Bloc es singleton -- ver chat_service_locator.dart).
  String? _currentRideId;

  void _onWatch(WatchMessages event, Emitter<ChatState> emit) {
    _currentRideId = event.rideId;
    _lastReadAt = null;
    _subscribeToMessages(event.rideId);
  }

  void _subscribeToMessages(String rideId) {
    _subscription?.cancel();
    try {
      _subscription = repository
          .watchMessages(rideId: rideId)
          .listen(
            (messages) => add(_ChatMessagesUpdated(messages)),
            onError: (Object error) => add(_ChatMessagesErrored(error)),
          );
    } catch (e) {
      debugPrint(
        'ChatDebug | Error inesperado al suscribirse a watchMessages '
        '(rideId=$rideId): $e',
      );
      add(_ChatMessagesErrored(e));
    }
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

    // Un stream que vuelve a emitir con datos es la señal de que ya está
    // sano -- limpia cualquier errorMessage que hubiera quedado de un corte
    // de conexión anterior (ver _onMessagesErrored/_onConnectivityRestored).
    emit(
      state.copyWith(
        messages: event.messages,
        unreadCount: unreadCount,
        errorMessage: null,
      ),
    );
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
    _currentRideId = null;
    emit(const ChatState());
  }

  void _startWatchingConnectivity() {
    try {
      _connectivitySubscription = connectivityRepository.watchConnection().listen(
        (isOnline) {
          if (isOnline) add(_ConnectivityRestored());
        },
        onError: (Object error) {
          debugPrint(
            'ChatDebug | Error en el stream de watchConnection: $error',
          );
        },
      );
    } catch (e) {
      debugPrint(
        'ChatDebug | Error inesperado al suscribirse a watchConnection: $e',
      );
    }
  }

  // Si el stream de Firestore quedó "colgado" tras un corte de conexión
  // largo (no siempre se recupera solo -- ver análisis de este bug en la
  // conversación del proyecto) o nunca llegó a suscribirse, se reintenta acá
  // apenas vuelve la conexión. Si ya está sano (con subscription activa y
  // sin error), no se toca -- resuscribirse en cada parpadeo de red sería
  // ruido innecesario sobre Firestore.
  void _onConnectivityRestored(
    _ConnectivityRestored event,
    Emitter<ChatState> emit,
  ) {
    final rideId = _currentRideId;
    if (rideId == null) return;

    final needsReconnect = _subscription == null || state.errorMessage != null;
    if (!needsReconnect) return;

    debugPrint(
      'ChatDebug | Conexión restaurada, reintentando watchMessages '
      '(rideId=$rideId)',
    );
    emit(state.copyWith(errorMessage: null));
    _subscribeToMessages(rideId);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    _connectivitySubscription?.cancel();
    return super.close();
  }
}

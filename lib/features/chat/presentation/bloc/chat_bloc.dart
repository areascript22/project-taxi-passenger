import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // El backend crea el doc padre chats/{rideId} (el que exige la regla de
  // Firestore para autorizar la subcolección de mensajes) DESPUÉS de que el
  // estado driverAssigned ya quedó escrito en Realtime Database -- que es
  // justo la señal que hace que esta pantalla se abra y se suscriba a
  // Firestore. En esa ventana de milisegundos el doc padre puede no existir
  // todavía y Firestore corta el listener con permission-denied (a
  // diferencia de un corte de red, esto NO se reintenta solo). Un puñado de
  // reintentos cortos alcanza de sobra para esa ventana real (medida en
  // logs: ~400ms) sin arriesgar un loop largo si el permiso de verdad no
  // corresponde.
  static const _permissionRetryDelay = Duration(milliseconds: 1200);
  static const _maxPermissionRetries = 4;

  final ChatRepository repository;
  final ConnectivityRepository connectivityRepository;
  StreamSubscription<List<ChatMessageEntity>>? _subscription;
  StreamSubscription<bool>? _connectivitySubscription;
  Timer? _permissionRetryTimer;
  int _permissionRetryCount = 0;
  DateTime? _lastReadAt;

  // rideId de la última carrera para la que se pidió WatchMessages. Se usa
  // para poder re-suscribir el stream de Firestore cuando vuelve la
  // conexión, sin depender de que la pantalla de chat siga montada (este
  // Bloc es singleton -- ver chat_service_locator.dart).
  String? _currentRideId;

  void _onWatch(WatchMessages event, Emitter<ChatState> emit) {
    debugPrint('ChatFlowDebug | ChatBloc._onWatch -> rideId=${event.rideId}');
    _currentRideId = event.rideId;
    _lastReadAt = null;
    _permissionRetryCount = 0;
    _subscribeToMessages(event.rideId);
  }

  void _subscribeToMessages(String rideId) {
    _subscription?.cancel();
    _permissionRetryTimer?.cancel();
    debugPrint(
      'ChatFlowDebug | ChatBloc._subscribeToMessages -> suscribiendo '
      'rideId=$rideId',
    );
    try {
      _subscription = repository
          .watchMessages(rideId: rideId)
          .listen(
            (messages) => add(_ChatMessagesUpdated(messages)),
            onError: (Object error) => add(_ChatMessagesErrored(error)),
          );
      debugPrint(
        'ChatFlowDebug | ChatBloc._subscribeToMessages -> subscription '
        'creada OK rideId=$rideId',
      );
    } catch (e) {
      debugPrint(
        'ChatFlowDebug | ChatBloc._subscribeToMessages -> EXCEPCION al '
        'suscribirse rideId=$rideId: $e',
      );
      debugPrint(
        'ChatDebug | Error inesperado al suscribirse a watchMessages '
        '(rideId=$rideId): $e',
      );
      add(_ChatMessagesErrored(e));
    }
  }

  void _onMessagesUpdated(_ChatMessagesUpdated event, Emitter<ChatState> emit) {
    debugPrint(
      'ChatFlowDebug | ChatBloc._onMessagesUpdated -> rideId=$_currentRideId '
      'count=${event.messages.length}',
    );
    // El stream ya está sano -- si veníamos reintentando por un
    // permission-denied momentáneo, se acabó, no hace falta seguir contando.
    _permissionRetryCount = 0;
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
    debugPrint(
      'ChatFlowDebug | ChatBloc._onMessagesErrored -> rideId=$_currentRideId '
      'error=${event.error}',
    );
    debugPrint('ChatDebug | Error en watchMessages: ${event.error}');

    final rideId = _currentRideId;
    final error = event.error;
    final isPermissionDenied =
        error is FirebaseException && error.code == 'permission-denied';

    if (isPermissionDenied &&
        rideId != null &&
        _permissionRetryCount < _maxPermissionRetries) {
      _permissionRetryCount++;
      debugPrint(
        'ChatFlowDebug | ChatBloc._onMessagesErrored -> permission-denied, '
        'reintento $_permissionRetryCount/$_maxPermissionRetries en '
        '${_permissionRetryDelay.inMilliseconds}ms (rideId=$rideId)',
      );
      // Silencioso a propósito: se espera que se resuelva solo en el
      // próximo intento, no tiene sentido parpadear un mensaje de error que
      // va a desaparecer en un instante.
      _permissionRetryTimer = Timer(_permissionRetryDelay, () {
        if (_currentRideId == rideId) _subscribeToMessages(rideId);
      });
      return;
    }

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
    _permissionRetryTimer?.cancel();
    _permissionRetryTimer = null;
    _permissionRetryCount = 0;
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
    debugPrint(
      'ChatFlowDebug | ChatBloc._onConnectivityRestored -> rideId=$rideId '
      'subscriptionActiva=${_subscription != null} '
      'errorPrevio=${state.errorMessage}',
    );
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
    _permissionRetryTimer?.cancel();
    return super.close();
  }
}

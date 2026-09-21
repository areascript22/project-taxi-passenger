import 'package:dartz/dartz.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../core/error/errors.dart';
import '../../../core/routing/app_routing.dart';
import '../../chat_presence/service/chat_presence_tracker.dart';
import '../../chat_presence/service/pending_chat_navigation_tracker.dart';
import 'push_notifications_service.dart';

const _androidChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'Notificaciones importantes',
  description: 'Usado para mostrar notificaciones mientras la app está abierta',
  importance: Importance.high,
);

class PushNotificationsServiceImpl implements PushNotificationsService {
  PushNotificationsServiceImpl({
    required this.chatPresenceTracker,
    required this.pendingChatNavigationTracker,
  });

  final ChatPresenceTracker chatPresenceTracker;
  final PendingChatNavigationTracker pendingChatNavigationTracker;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  @override
  Future<Either<Failure, Unit>> initialize() async {
    try {
      await _messaging.requestPermission();

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_androidChannel);

      await _localNotifications.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) {
          _navigate(response.payload);
        },
      );

      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
      // App en foreground o en background pero con el proceso vivo: en
      // cualquiera de los dos casos RideTrackingScreen ya está montada
      // dentro del stack del branch, así que basta con avisarle al tracker
      // -- su listener reacciona al instante.
      FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);

      // A propósito NO se navega acá con getInitialMessage() para rutas
      // genéricas (app abierta tocando la notificación estando
      // completamente cerrada, "cold start"): en ese momento SessionBloc
      // todavía no corrió su chequeo de sesión (recién va a arrancar el
      // flujo splash -> SessionScreen), así que empujar la ruta ahora monta
      // esa pantalla sin sesión resuelta -- RideTrackingScreen resuelve su
      // propio passengerId desde SessionBloc, así que sin sesión no dispara
      // el tracking y queda sin datos (y no se reintenta después, porque
      // go_router preserva el estado de la rama al navegar ahí de nuevo).
      // El flujo normal de sesión ya detecta el viaje en curso
      // (SessionAuthenticated.hasActiveRide) y navega al mismo lugar una vez
      // la sesión está resuelta, con los datos completos
      // (SessionAuthenticated.activeRide).
      //
      // Para chat sí hace falta dejar constancia del pedido: una vez que
      // RideTrackingScreen se monte con esa misma carrera (flujo de arriba),
      // recoge el pendiente y abre el chat encima.
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage?.data['type'] == 'chat_message') {
        _requestChatNavigation(initialMessage!.data);
      }

      return const Right(unit);
    } catch (e) {
      debugPrint('NotificationsDebug | Error en initialize: $e');
      return Left(
        Failure(message: 'No se pudo inicializar las notificaciones push'),
      );
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    // El chat de esa misma carrera ya está abierto y renderiza el mensaje
    // en vivo vía su stream de Firestore: mostrar el banner sería duplicado.
    final data = message.data;
    if (data['type'] == 'chat_message' &&
        chatPresenceTracker.isOpen(rideId: data['rideId'] as String? ?? '')) {
      return;
    }

    try {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        // Los pushes de chat codifican el rideId en el payload (con un
        // prefijo para distinguirlos) en vez de la route genérica, para que
        // el tap navegue directo al chat -- ver _navigate.
        payload:
            data['type'] == 'chat_message'
                ? 'chat:${data['rideId']}'
                : data['route'] as String?,
      );
    } catch (e) {
      debugPrint(
        'NotificationsDebug | Error en _showForegroundNotification: $e',
      );
    }
  }

  void _handleOpenedMessage(RemoteMessage message) {
    if (message.data['type'] == 'chat_message') {
      _requestChatNavigation(message.data);
      return;
    }
    _navigate(message.data['route'] as String?);
  }

  void _requestChatNavigation(Map<String, dynamic> data) {
    final rideId = data['rideId'] as String?;
    if (rideId == null || rideId.isEmpty) return;
    pendingChatNavigationTracker.request(rideId: rideId);
  }

  static const _chatPayloadPrefix = 'chat:';

  void _navigate(String? payload) {
    if (payload == null || payload.isEmpty) return;

    if (payload.startsWith(_chatPayloadPrefix)) {
      final rideId = payload.substring(_chatPayloadPrefix.length);
      if (rideId.isEmpty) return;
      pendingChatNavigationTracker.request(rideId: rideId);
      return;
    }

    AppRouter.router.push(payload);
  }

  @override
  Future<Either<Failure, String?>> getToken() async {
    try {
      final token = await _messaging.getToken();
      return Right(token);
    } catch (e) {
      debugPrint('NotificationsDebug | Error en getToken: $e');
      return Left(
        Failure(message: 'No se pudo obtener el token de notificaciones'),
      );
    }
  }

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;
}

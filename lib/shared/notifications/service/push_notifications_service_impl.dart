import 'package:dartz/dartz.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../core/error/errors.dart';
import '../../../core/routing/app_routing.dart';
import 'push_notifications_service.dart';

const _androidChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'Notificaciones importantes',
  description: 'Usado para mostrar notificaciones mientras la app está abierta',
  importance: Importance.high,
);

class PushNotificationsServiceImpl implements PushNotificationsService {
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
      FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => _navigate(message.data['route'] as String?),
      );

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        final route = initialMessage.data['route'] as String?;
        WidgetsBinding.instance.addPostFrameCallback((_) => _navigate(route));
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
        payload: message.data['route'] as String?,
      );
    } catch (e) {
      debugPrint(
        'NotificationsDebug | Error en _showForegroundNotification: $e',
      );
    }
  }

  void _navigate(String? route) {
    if (route == null || route.isEmpty) return;
    AppRouter.router.push(route);
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

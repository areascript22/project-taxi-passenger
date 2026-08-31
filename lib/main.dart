import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:passenger_app/core/routing/app_routing.dart';
import 'package:passenger_app/core/service_locator/main_service_locator.dart';
import 'package:passenger_app/core/theme/app_theme.dart';
import 'package:passenger_app/shared/notifications/service/push_notifications_service.dart';
import 'package:passenger_app/shared/presentation/bloc/session/session_bloc.dart';
import 'package:passenger_app/shared/services/services_initializer.dart';
import 'package:passenger_app/shared/settings/presentation/bloc/settings_bloc.dart';

// Debe ser una función top-level (o estática): FCM la ejecuta en un isolate
// separado cuando llega un mensaje con la app en background, así que no
// tiene acceso al estado ya inicializado en main().
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  initMainServiceLocator();
  await ServicesInitializer.initializeServices();
  // No se espera (fire-and-forget): no debe bloquear el arranque de la app.
  unawaited(GetIt.instance<PushNotificationsService>().initialize());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SessionBloc>(
          create: (context) => GetIt.instance<SessionBloc>(),
        ),
        BlocProvider<SettingsBloc>(
          create:
              (context) => GetIt.instance<SettingsBloc>()..add(LoadSettings()),
        ),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          return MaterialApp.router(
            title: 'Taxi project',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settingsState.themeMode,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}

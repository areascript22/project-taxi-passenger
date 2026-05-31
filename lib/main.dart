import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
// Importamos el archivo de configuración de GoRouter que creaste
import 'package:passenger_app/core/routing/app_routing.dart';
import 'package:passenger_app/core/service_locator/main_service_locator.dart';
import 'package:passenger_app/shared/services/services_initializer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Se mantiene tu inicialización nativa de Firebase
  initMainServiceLocator();
  await ServicesInitializer.initializeServices();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Cambiamos a MaterialApp.router para que GoRouter tome el control
    return MaterialApp.router(
      title: 'Taxi project', // Mantenemos el título de tu app
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), // Tu esquema de colores original
        useMaterial3: true,
      ),
      // 2. Inyectamos la propiedad estática router de tu clase AppRouter
      routerConfig: AppRouter.router,
    );
  }
}
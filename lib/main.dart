import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:passenger_app/core/routing/app_routing.dart';
import 'package:passenger_app/core/service_locator/main_service_locator.dart';
import 'package:passenger_app/shared/presentation/bloc/session/session_bloc.dart';
import 'package:passenger_app/shared/services/services_initializer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  initMainServiceLocator();
  await ServicesInitializer.initializeServices();
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
      ],
      child: MaterialApp.router(
        title: 'Taxi project',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        routerConfig: AppRouter.router,
      ),
    );
  }
}

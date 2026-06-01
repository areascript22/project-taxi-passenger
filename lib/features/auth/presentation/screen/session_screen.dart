import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:passenger_app/core/routing/app_routes.dart';
import 'package:passenger_app/core/service_locator/main_service_locator.dart';
import 'package:passenger_app/features/auth/presentation/bloc/auth_bloc.dart';

// TODO: Update these imports with your actual project paths
// import 'package:passenger_app/features/auth/presentation/bloc/auth_bloc.dart';
// import 'package:passenger_app/features/auth/domain/repository/auth_repository.dart';
// import 'package:passenger_app/features/auth/presentation/pages/sign_in_screen.dart';
// import 'package:passenger_app/features/home/presentation/pages/home_screen.dart';

/// 1. El widget principal que provee el BLoC
class SessionScreen extends StatelessWidget {
  const SessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Instanciamos el BLoC y disparamos el evento inmediatamente al montarse
      create:
          (context) =>
              mainServiceLocator<AuthBloc>()..add(AuthCheckRequested()),

      // Pasamos la vista separada como hijo
      child: const SessionView(),
    );
  }
}

/// 2. La vista que escucha los cambios de estado y dibuja la UI
class SessionView extends StatelessWidget {
  const SessionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          // Si ocurre un error o el usuario no está autenticado -> SignInScreen
          if (state is AuthError || state is AuthUnauthenticated) {
            context.goNamed(signInRoute.name);
          }
          // Si la verificación es exitosa -> HomeScreen
          else if (state is AuthAuthenticated) {
            context.goNamed(homeRoute.name);
          }
        },
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

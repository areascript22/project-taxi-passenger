import 'package:go_router/go_router.dart';
import 'package:passenger_app/core/routing/app_routes.dart';
import 'package:passenger_app/features/auth/presentation/screen/session_screen.dart';
import 'package:passenger_app/features/auth/presentation/screen/sign_in_screen.dart';
import 'package:passenger_app/features/home/presentation/screen/home_screen.dart';

import '../../features/auth/presentation/screen/splash_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: splashRoute.route,
    routes: [
      GoRoute(
        path: splashRoute.route,
        name: splashRoute.name,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: signInRoute.route,
        name: signInRoute.name,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: sessionRoute.route,
        name: sessionRoute.name,
        builder: (context, state) => const SessionScreen(),
      ),
      GoRoute(
        path: homeRoute.route,
        name: homeRoute.name,
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
}

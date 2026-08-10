import 'package:go_router/go_router.dart';
import 'package:passenger_app/core/routing/app_routes.dart';
import 'package:passenger_app/features/auth/presentation/screen/session_screen.dart';
import 'package:passenger_app/features/auth/presentation/screen/sign_in_screen.dart';
import 'package:passenger_app/features/booking/presentation/screen/booking_sccreen.dart';
import 'package:passenger_app/features/booking/presentation/screen/booking_sccreen_2.dart';
import 'package:passenger_app/features/map/presentation/screen/map_picker_screen.dart';
import 'package:passenger_app/features/passenger_profile/presentation/screen/passenger_onboarding_screen.dart';
import 'package:passenger_app/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:passenger_app/features/profile/presentation/screen/edit_profile_screen.dart';
import 'package:passenger_app/features/profile/presentation/screen/profile_screen.dart';
import 'package:passenger_app/features/profile/presentation/screen/profile_screen_2.dart';
import 'package:passenger_app/features/ride_tracking/presentation/screen/ride_tracking_screen.dart';
import 'package:passenger_app/shared/domain/entity/user_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/shared/presentation/component/scaffold_nav_bar.dart';
import 'package:passenger_app/shared/settings/presentation/screen/settings_screen.dart';
import 'package:passenger_app/shared/domain/entity/place_entity.dart';
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
        path: passengerOnboardingRoute.route,
        name: passengerOnboardingRoute.name,
        builder:
            (context, state) =>
                PassengerOnboardingScreen(user: state.extra as UserEntity),
      ),

      // The StatefulShellRoute acts as your authenticated "Home"
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // ---------------------------
          // BRANCH 1: Booking Flow
          // ---------------------------
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: bookingRoute.route,
                name: bookingRoute.name,
                builder: (context, state) => const BookingScreen(),
              ),
              GoRoute(
                path: '/booking2',
                name: 'booking2',
                builder: (context, state) => const BookingScreen2(),
              ),

              GoRoute(
                path: rideTrackingRoute.route,
                name: rideTrackingRoute.name,
                builder: (context, state) => const RideTrackingScreen(),
              ),

              GoRoute(
                path: mapPickerRoute.route,
                name: mapPickerRoute.name,
                builder: (context, state) {
                  final initialPlace = state.extra as PlaceEntity?;
                  return MapPickerScreen(initialPlace: initialPlace);
                },
              ),
            ],
          ),

          // ---------------------------
          // BRANCH 2: Profile Flow
          // ---------------------------
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  // CHILD ROUTE: Notice there is no leading '/'
                  // Navigate here using: context.pushNamed('profile2')
                  GoRoute(
                    path: '2',
                    name: 'profile2',
                    builder: (context, state) => const ProfileScreen2(),
                  ),
                ],
              ),
              GoRoute(
                path: settingsRoute.route,
                name: settingsRoute.name,
                builder: (context, state) => const SettingsScreen(),
              ),
              GoRoute(
                path: editProfileRoute.route,
                name: editProfileRoute.name,
                builder:
                    (context, state) => BlocProvider.value(
                      value: state.extra as ProfileBloc,
                      child: const EditProfileScreen(),
                    ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
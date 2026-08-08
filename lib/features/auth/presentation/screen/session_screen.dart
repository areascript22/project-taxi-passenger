import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:passenger_app/core/routing/app_routes.dart';
import 'package:passenger_app/shared/presentation/bloc/session/session_bloc.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  @override
  void initState() {
    super.initState();
    _checkIfUserLoggedIn();
  }

  void _checkIfUserLoggedIn() {
    context.read<SessionBloc>().add(SessionCheckRequested());
  }

  @override
  Widget build(BuildContext context) {
    return const SessionView();
  }
}

class SessionView extends StatelessWidget {
  const SessionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<SessionBloc, SessionState>(
        listener: (context, state) {
          if (state is SessionUnauthenticated) {
            context.goNamed(signInRoute.name);
          }

          if (state is SessionAuthenticated) {
            if (state.hasActiveRide) {
              // Viaje en curso (con conductor asignado antes de un kill de
              // la app) -- resume directo en RideTrackingScreen en vez de
              // BookingScreen.
              context.goNamed(rideTrackingRoute.name);
            } else {
              context.goNamed('booking');
            }
          }
        },
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

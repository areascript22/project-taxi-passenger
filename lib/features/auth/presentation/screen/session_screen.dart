import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:passenger_app/core/routing/app_routes.dart';
import 'package:passenger_app/features/ride_tracking/presentation/bloc/ride_tracking_bloc.dart';
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
      body: BlocConsumer<SessionBloc, SessionState>(
        listener: (context, state) {
          if (state is SessionUnauthenticated) {
            context.goNamed(signInRoute.name);
          }

          if (state is SessionOnboardingRequired) {
            context.goNamed(passengerOnboardingRoute.name, extra: state.user);
          }

          if (state is SessionAuthenticated) {
            final ride = state.activeRide;
            if (ride == null) {
              context.goNamed('booking');
            } else if (ride.rideStatus == RideTrackingStatus.waitingDriver) {
              // Solicitud pendiente (sin conductor asignado todavía) antes de
              // un kill de la app -- resume BookingScreen con el diálogo
              // "Buscando conductor" en vez de perderla silenciosamente.
              context.goNamed('booking', extra: ride);
            } else {
              // Viaje en curso (con conductor asignado en adelante) -- resume
              // directo en RideTrackingScreen.
              context.goNamed(rideTrackingRoute.name);
            }
          }
        },
        builder: (context, state) {
          if (state is SessionCheckFailed) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'No se pudo verificar tu sesión. Revisa tu conexión e '
                      'intenta de nuevo.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<SessionBloc>().add(
                        SessionCheckRequested(),
                      ),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:passenger_app/features/booking/presentation/bloc/booking/booking_bloc.dart';
import 'package:passenger_app/features/ride_tracking/presentation/bloc/ride_tracking_bloc.dart';
import 'package:passenger_app/shared/feedback/feedback_service.dart';

import '../../../../core/routing/app_routes.dart';

class WaitingForDriverDialog extends StatelessWidget {
  final VoidCallback onCancel;

  const WaitingForDriverDialog({super.key, required this.onCancel});

  static Future<void> show({
    required BuildContext context,
    required VoidCallback onCancel,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) =>
          MultiBlocProvider(providers: [
            BlocProvider.value(
              value: GetIt.instance<BookingBloc>(),
            ),
            BlocProvider.value(
              value: GetIt.instance<RideTrackingBloc>(),
            ),

          ], child: WaitingForDriverDialog(onCancel: onCancel)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;

    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: onSurface.withValues(alpha: 0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: Transform.scale(
                    scale: 3.2,
                    child: Lottie.asset(
                      'assets/animations/taxi_animation.json',
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Buscando conductor...",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Estamos buscando un taxi disponible para tu viaje. Por favor espera, un conductor aceptará tu solicitud en breve.",
                style: TextStyle(
                  fontSize: 14,
                  color: onSurface.withValues(alpha: 0.6),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              BlocListener<RideTrackingBloc, RideTrackingState>(
                  listenWhen: (previous, current) =>
                  previous.status != current.status,
                  listener: (context, state) {
                    if (state.status == RideTrackingStatus.driverAssigned) {
                      GetIt.instance<FeedbackService>().announce(
                        'Carrera aceptada',
                        withVibration: true,
                      );
                      Navigator.pop(context);
                      context.goNamed(rideTrackingRoute.name);
                    }
                  },
                  child: SizedBox(),
              ),

              SizedBox(
                width: double.infinity,
                child: BlocConsumer<BookingBloc, BookingState>(
                  listener: (context, state) {
                    if (state.status == BookingStatus.initial) {
                      Navigator.of(context).pop();
                    }
                  },
                  builder: (context, state) {
                    final isCancelling =
                        state.status == BookingStatus.cancellingRequest;

                    return ElevatedButton(
                      onPressed:
                          !isCancelling
                              ? () {
                                context.read<BookingBloc>().add(
                                  CancelTaxiRequest(),
                                );
                              }
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.error.withValues(
                          alpha: 0.1,
                        ),
                        foregroundColor: colorScheme.error,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: colorScheme.error.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      child:
                          isCancelling
                              ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colorScheme.error,
                                  ),
                                ),
                              )
                              : const Text(
                                "Cancelar solicitud",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

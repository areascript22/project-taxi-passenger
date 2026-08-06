import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:passenger_app/features/booking/presentation/bloc/booking/booking_bloc.dart';
import 'package:passenger_app/features/ride_tracking/presentation/bloc/ride_tracking_bloc.dart';

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
    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
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
              const Text(
                "Buscando conductor...",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                "Estamos buscando un taxi disponible para tu viaje. Por favor espera, un conductor aceptará tu solicitud en breve.",
                style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              BlocListener<RideTrackingBloc, RideTrackingState>(
                  listenWhen: (previous, current) =>
                  previous.status != current.status,
                  listener: (context, state) {
                    if (state.status == RideTrackingStatus.driverAssigned) {
                      Navigator.pop(context);
                      //TODO: Navigate to ride tricking screen
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
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.red.shade200),
                        ),
                      ),
                      child:
                          isCancelling
                              ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.red,
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

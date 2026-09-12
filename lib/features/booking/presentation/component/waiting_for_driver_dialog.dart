import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:passenger_app/features/booking/presentation/bloc/booking/booking_bloc.dart';
import 'package:passenger_app/features/ride_tracking/presentation/bloc/ride_tracking_bloc.dart';
import 'package:passenger_app/shared/feedback/feedback_service.dart';

import '../../../../core/routing/app_routes.dart';

class WaitingForDriverDialog extends StatefulWidget {
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
  State<WaitingForDriverDialog> createState() =>
      _WaitingForDriverDialogState();
}

class _WaitingForDriverDialogState extends State<WaitingForDriverDialog> {
  // Tiempo máximo esperando a que un conductor acepte antes de cancelar la
  // solicitud automáticamente. El cliente pidió "25 o 30 segundos".
  static const _searchTimeout = Duration(seconds: 30);

  Timer? _timeoutTimer;

  // Marca que la próxima cancelación (éxito o falla) del BookingBloc fue
  // disparada por el timeout automático, no por el botón. Así el listener de
  // BookingBloc sabe qué mensaje mostrar sin necesitar un nuevo estado en el
  // bloc.
  bool _cancelledByTimeout = false;

  @override
  void initState() {
    super.initState();
    _timeoutTimer = Timer(_searchTimeout, _handleSearchTimeout);
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _handleSearchTimeout() {
    if (!mounted) return;

    // Guarda contra la carrera donde un conductor acepta justo en el
    // instante en que expira el timer: si ya hay conductor asignado, dejamos
    // que el otro listener (más abajo) cierre este diálogo y navegue --  no
    // cancelamos una carrera que ya fue aceptada.
    final rideStatus = context.read<RideTrackingBloc>().state.status;
    if (rideStatus == RideTrackingStatus.driverAssigned) return;

    // No cerramos el diálogo acá: el endpoint de cancelación puede fallar
    // (conexión caída, la carrera ya fue aceptada en el instante exacto,
    // etc.), y si cerráramos el popup igual perderíamos el BlocListener de
    // RideTrackingBloc de más abajo -- el que nos avisa si un conductor
    // terminó aceptando la carrera que creíamos cancelada. Solo cerramos
    // cuando BookingBloc confirme éxito (ver el BlocConsumer más abajo).
    _cancelledByTimeout = true;
    context.read<BookingBloc>().add(CancelTaxiRequest());
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
                      // Éxito confirmado por el backend (Right en el
                      // repositorio): recién acá es seguro cerrar el popup.
                      final wasTimeout = _cancelledByTimeout;
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.of(context).pop();
                      if (wasTimeout) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Ahora mismo no hay conductores disponibles. Intenta de nuevo en unos minutos.',
                            ),
                          ),
                        );
                      }
                    } else if (state.status == BookingStatus.error &&
                        _cancelledByTimeout) {
                      // El repositorio devolvió Failure: la carrera puede
                      // seguir viva en Firebase, así que el popup se queda
                      // abierto (y con él, el listener de RideTrackingBloc
                      // que reacciona si un conductor la acepta mientras
                      // tanto). El botón "Cancelar solicitud" sigue
                      // disponible para reintentar manualmente.
                      _cancelledByTimeout = false;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            state.errorMessage ??
                                'No se pudo cancelar automáticamente. Intenta cancelar de nuevo.',
                          ),
                        ),
                      );
                    } else if (state.status == BookingStatus.error) {
                      // Falla al cancelar manualmente con el botón: el
                      // diálogo se queda abierto (nunca cerramos en error),
                      // solo avisamos para que el usuario reintente.
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            state.errorMessage ??
                                'No se pudo cancelar la solicitud. Intenta de nuevo.',
                          ),
                        ),
                      );
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

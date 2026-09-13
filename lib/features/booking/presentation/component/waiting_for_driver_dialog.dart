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
  // Epoch millis de RideEntity.createdAtMillis, solo cuando este diálogo se
  // muestra al reanudar una solicitud 'pending' que ya existía en Firebase
  // (app cerrada y reabierta). Null en el flujo normal (solicitud recién
  // creada): en ese caso el countdown arranca completo desde _searchTimeout.
  final int? rideCreatedAtMillis;

  const WaitingForDriverDialog({
    super.key,
    required this.onCancel,
    this.rideCreatedAtMillis,
  });

  static Future<void> show({
    required BuildContext context,
    required VoidCallback onCancel,
    int? rideCreatedAtMillis,
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

          ], child: WaitingForDriverDialog(
            onCancel: onCancel,
            rideCreatedAtMillis: rideCreatedAtMillis,
          )),
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

  // true mientras haya un intento de cancelación disparado por ESTE cliente
  // (botón o timeout) en curso o ya confirmado. El backend también puede
  // cancelar la solicitud por su cuenta (auto-expiry si nadie la acepta a
  // tiempo, ver PENDING_REQUEST_EXPIRY_SECONDS server-side) sin que este
  // cliente llegue a llamar a /cancel -- el listener de RideTrackingBloc de
  // más abajo usa este flag para no duplicar el cierre del popup cuando la
  // cancelación sí la iniciamos nosotros (en ese caso ya la maneja el
  // BlocConsumer<BookingBloc>), y para poder reaccionar cuando NO la
  // iniciamos nosotros. Se resetea a false si un intento local falla, para
  // que el diálogo vuelva a poder reaccionar a una cancelación externa.
  bool _localCancelRequested = false;

  @override
  void initState() {
    super.initState();
    _timeoutTimer = Timer(_remainingSearchTime(), _handleSearchTimeout);
  }

  // Margen mínimo al resumir una solicitud cuyo timeout ya se cumplió con la
  // app cerrada: le da tiempo al listener de Firebase (RideTrackingBloc) a
  // reconectar y traer el status real antes de evaluar si corresponde
  // auto-cancelar -- evita cancelar una carrera que en realidad ya fue
  // aceptada segundos antes de reabrir la app.
  static const _minResumeGrace = Duration(seconds: 3);

  // Si rideCreatedAtMillis viene seteado (diálogo resumido tras reabrir la
  // app con una solicitud 'pending' ya existente), el countdown se calcula
  // contra ese momento real en vez de reiniciar los 30s completos --
  // createdAt es un ServerValue.timestamp de Firebase, así que no depende
  // del reloj local del dispositivo.
  Duration _remainingSearchTime() {
    final createdAtMillis = widget.rideCreatedAtMillis;
    if (createdAtMillis == null) return _searchTimeout;

    final createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtMillis);
    final elapsed = DateTime.now().difference(createdAt);
    final remaining = _searchTimeout - elapsed;
    return remaining < _minResumeGrace ? _minResumeGrace : remaining;
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
    _localCancelRequested = true;
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
                      if (!context.mounted) return;
                      GetIt.instance<FeedbackService>().announce(
                        'Carrera aceptada',
                        withVibration: true,
                      );
                      Navigator.pop(context);
                      context.goNamed(rideTrackingRoute.name);
                    } else if (state.status == RideTrackingStatus.cancelled) {
                      // El backend puede auto-cancelar la solicitud por su
                      // cuenta (ver PENDING_REQUEST_EXPIRY_SECONDS) sin que
                      // este cliente llegue a llamar a /cancel -- este
                      // listener reacciona directo al cambio real en
                      // Firebase. Si la cancelación la iniciamos nosotros
                      // (botón o timeout local), no hacemos nada acá: ya la
                      // maneja el BlocConsumer<BookingBloc> de más abajo, con
                      // su propia lógica de mensaje.
                      if (_localCancelRequested) return;
                      if (!context.mounted) return;
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.of(context).pop();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Ahora mismo no hay conductores disponibles. Intenta de nuevo en unos minutos.',
                          ),
                        ),
                      );
                    }
                  },
                  child: SizedBox(),
              ),

              SizedBox(
                width: double.infinity,
                child: BlocConsumer<BookingBloc, BookingState>(
                  listener: (context, state) {
                    if (state.status == BookingStatus.initial) {
                      if (!context.mounted) return;
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
                      // disponible para reintentar manualmente. Reseteamos
                      // ambos flags para que el listener de RideTrackingBloc
                      // vuelva a poder reaccionar por su cuenta (ej. si el
                      // backend termina auto-cancelándola igual).
                      _cancelledByTimeout = false;
                      _localCancelRequested = false;
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
                      _localCancelRequested = false;
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
                                _localCancelRequested = true;
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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:passenger_app/features/booking/domain/search_elapsed.dart';
import 'package:passenger_app/features/booking/presentation/bloc/booking/booking_bloc.dart';
import 'package:passenger_app/features/ride_tracking/presentation/bloc/ride_tracking_bloc.dart';
import 'package:passenger_app/l10n/app_localizations.dart';
import 'package:passenger_app/shared/feedback/feedback_service.dart';
import 'package:passenger_app/shared/presentation/component/app_toast.dart';
import 'package:passenger_app/shared/presentation/failure_text.dart';
import '../../../../core/routing/app_routes.dart';

/// El popup "Buscando conductor".
///
/// La app NO decide cuando termina la busqueda: el servidor recorre los anillos
/// de cercania y, si nadie acepta, cierra la solicitud (y este popup reacciona a
/// ese cambio por el listener de [RideTrackingBloc]). Por eso el contador cuenta
/// hacia arriba -- lleva esperando -- y no hacia abajo: la app no sabe cuanto va
/// a durar la busqueda, la configura un administrador.
class WaitingForDriverDialog extends StatefulWidget {
  final VoidCallback onCancel;
  // Epoch millis de RideEntity.createdAtMillis, solo cuando este diálogo se
  // muestra al reanudar una solicitud 'pending' que ya existía en Firebase
  // (app cerrada y reabierta). Null en el flujo normal (solicitud recién
  // creada): en ese caso el contador arranca en 0.
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
  late final DateTime _openedAt;

  // Tiempo que lleva buscandose, refrescado cada segundo. Es solo para
  // mostrar: no dispara ninguna accion.
  Duration _elapsed = Duration.zero;
  Timer? _displayTicker;

  // true mientras haya un intento de cancelación disparado por ESTE cliente
  // (el botón) en curso o ya confirmado. El servidor también cierra la
  // solicitud por su cuenta (nadie aceptó tras el último anillo) sin que este
  // cliente llame a /cancel -- el listener de RideTrackingBloc de más abajo usa
  // este flag para no duplicar el cierre del popup cuando la cancelación sí la
  // iniciamos nosotros (en ese caso ya la maneja el BlocConsumer<BookingBloc>),
  // y para poder reaccionar cuando NO la iniciamos nosotros. Se resetea a
  // false si un intento local falla, para que el diálogo vuelva a poder
  // reaccionar a una cancelación del servidor.
  bool _localCancelRequested = false;

  @override
  void initState() {
    super.initState();
    _openedAt = DateTime.now();
    _elapsed = _computeElapsed();
    _displayTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed = _computeElapsed());
    });
  }

  Duration _computeElapsed() => searchElapsed(
    now: DateTime.now(),
    openedAt: _openedAt,
    rideCreatedAtMillis: widget.rideCreatedAtMillis,
  );

  @override
  void dispose() {
    _displayTicker?.cancel();
    super.dispose();
  }

  // Anillo indeterminado alrededor del taxi: "se esta buscando". No muestra
  // progreso porque no hay un total conocido (ver la nota de la clase).
  Widget _buildSearchRing(ColorScheme colorScheme) {
    return SizedBox(
      width: 158,
      height: 158,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 158,
            height: 158,
            child: CircularProgressIndicator(
              strokeWidth: 5,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
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
        ],
      ),
    );
  }

  // Chip con el tiempo que lleva buscandose.
  Widget _buildElapsedChip(ColorScheme colorScheme) {
    final chipColor = colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 14, color: chipColor),
          const SizedBox(width: 6),
          Text(
            AppLocalizations.of(
              context,
            ).bookingSearchElapsed(formatSearchElapsed(_elapsed)),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: chipColor,
            ),
          ),
        ],
      ),
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
              _buildSearchRing(colorScheme),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context).waitingTitle,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context).waitingBody,
                style: TextStyle(
                  fontSize: 14,
                  color: onSurface.withValues(alpha: 0.6),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _buildElapsedChip(colorScheme),
              const SizedBox(height: 24),

              BlocListener<RideTrackingBloc, RideTrackingState>(
                  listenWhen: (previous, current) =>
                  previous.status != current.status,
                  listener: (context, state) {
                    if (state.status == RideTrackingStatus.driverAssigned) {
                      if (!context.mounted) return;
                      GetIt.instance<FeedbackService>().announce(
                        AppLocalizations.of(context).waitingRideAccepted,
                        withVibration: true,
                      );
                      Navigator.pop(context);
                      context.goNamed(rideTrackingRoute.name);
                    } else if (state.status == RideTrackingStatus.cancelled) {
                      // El servidor cierra la solicitud por su cuenta cuando
                      // se recorrieron todos los anillos y nadie aceptó (o
                      // vence): este listener reacciona directo al cambio real
                      // en Firebase. Si la cancelación la iniciamos nosotros
                      // (botón), no hacemos nada acá: ya la maneja el
                      // BlocConsumer<BookingBloc> de más abajo.
                      if (_localCancelRequested) return;
                      if (!context.mounted) return;
                      // El toast se muestra ANTES del pop: vive en el overlay
                      // raíz, así que sobrevive al cierre del diálogo.
                      AppToast.error(
                        context,
                        message:
                            AppLocalizations.of(context).waitingNoDrivers,
                      );
                      Navigator.of(context).pop();
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
                      Navigator.of(context).pop();
                    } else if (state.status == BookingStatus.error) {
                      // Falla al cancelar con el botón: el diálogo se queda
                      // abierto (nunca cerramos en error, para no perder el
                      // listener que reacciona si un conductor acepta),
                      // solo avisamos para que el usuario reintente.
                      _localCancelRequested = false;
                      AppToast.error(
                        context,
                        message:
                            state.errorCode != null
                                ? context.failureText(state.errorCode!)
                                : AppLocalizations.of(
                                  context,
                                ).waitingCancelFailed,
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
                              : Text(
                                AppLocalizations.of(context).waitingCancelRequest,
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

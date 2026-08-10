import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:passenger_app/features/ride_tracking/presentation/bloc/ride_tracking_bloc.dart';
import 'package:passenger_app/shared/presentation/component/custom_loader.dart';

// Diálogo de confirmación para cancelar un viaje que ya tiene conductor
// asignado. Arquitectura basada en TaxiConfirmationDialog (booking feature).
class ConfirmCancelRideDialog extends StatelessWidget {
  final String passengerId;

  const ConfirmCancelRideDialog({super.key, required this.passengerId});

  static Future<void> show({
    required BuildContext context,
    required String passengerId,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => BlocProvider.value(
            value: GetIt.instance<RideTrackingBloc>(),
            child: ConfirmCancelRideDialog(passengerId: passengerId),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RideTrackingBloc, RideTrackingState>(
      // Dos señales pueden indicar "ya terminó, cierra el diálogo": que el
      // propio request de cancelación termine (isCancelling true->false) o
      // que el stream de Firebase confirme el nuevo status primero -- no hay
      // orden garantizado entre ambos, así que reaccionamos a la que llegue
      // primero.
      listenWhen:
          (previous, current) =>
              (previous.isCancelling &&
                  !current.isCancelling &&
                  current.errorMessage == null) ||
              (previous.status != RideTrackingStatus.cancelled &&
                  current.status == RideTrackingStatus.cancelled),
      listener: (context, state) {
        // Cancelación exitosa: el listener de RideTrackingScreen puede haber
        // navegado ya (llega por el mismo stream) y desmontado este diálogo,
        // así que verificamos antes de intentar cerrarlo nosotros mismos.
        if (!context.mounted) return;
        Navigator.of(context).pop();
      },
      builder: (context, state) {
        final isCancelling = state.isCancelling;
        final colorScheme = Theme.of(context).colorScheme;

        return PopScope(
          canPop: !isCancelling,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colorScheme.onSurface.withValues(alpha: 0.08),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.error.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_rounded,
                      color: colorScheme.error,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "¿Cancelar viaje?",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Tu conductor ya está en camino. Si cancelas ahora, es posible que se te aplique un cargo por cancelación.",
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      state.errorMessage!,
                      style: TextStyle(fontSize: 13, color: colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed:
                              isCancelling
                                  ? null
                                  : () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            foregroundColor: colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Continuar viaje",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              !isCancelling
                                  ? () {
                                    context.read<RideTrackingBloc>().add(
                                      CancelRideRequested(
                                        passengerId: passengerId,
                                      ),
                                    );
                                  }
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.error,
                            foregroundColor: colorScheme.onError,
                            padding: EdgeInsets.symmetric(
                              vertical: isCancelling ? 0.0 : 14,
                            ),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child:
                              isCancelling
                                  ? CustomLoader(width: 40, height: 40)
                                  : const Text(
                                    "Cancelar viaje",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

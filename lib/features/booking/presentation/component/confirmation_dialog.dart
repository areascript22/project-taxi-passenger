import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:passenger_app/core/theme/app_colors.dart';
import 'package:passenger_app/features/booking/presentation/bloc/booking/booking_bloc.dart';
import 'package:passenger_app/features/booking/presentation/component/waiting_for_driver_dialog.dart';
import 'package:passenger_app/features/ride_tracking/presentation/bloc/ride_tracking_bloc.dart';
import 'package:passenger_app/shared/presentation/bloc/session/session_bloc.dart';
import 'package:passenger_app/shared/presentation/component/custom_loader.dart';

class TaxiConfirmationDialog extends StatelessWidget {
  final String address;
  final VoidCallback onConfirm;

  const TaxiConfirmationDialog({
    super.key,
    required this.address,
    required this.onConfirm,
  });

  static Future<void> show({
    required BuildContext context,
    required String address,
    required VoidCallback onConfirm,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: GetIt.instance<BookingBloc>()),
              BlocProvider.value(value: GetIt.instance<RideTrackingBloc>()),
            ],
            child: TaxiConfirmationDialog(
              address: address,
              onConfirm: onConfirm,
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, state) {
        final isRequesting = state.status == BookingStatus.requestingTaxi;
        final colorScheme = Theme.of(context).colorScheme;
        final onSurface = colorScheme.onSurface;
        final warning = context.appColors.warning;

        return PopScope(
          canPop: !isRequesting,
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
                border: Border.all(color: onSurface.withValues(alpha: 0.08)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: warning.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.local_taxi_rounded,
                      color: warning,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "¿Confirmar viaje?",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Un conductor será enviado a la siguiente ubicación:",
                    style: TextStyle(
                      fontSize: 14,
                      color: onSurface.withValues(alpha: 0.6),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: onSurface.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: onSurface.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: onSurface.withValues(alpha: 0.5),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            address,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed:
                              isRequesting
                                  ? null
                                  : () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            foregroundColor: onSurface.withValues(alpha: 0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Cancelar",
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
                              !isRequesting
                                  ? () {
                                    onConfirm();
                                  }
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: EdgeInsets.symmetric(
                              vertical: isRequesting ? 0.0 : 14,
                            ),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child:
                              isRequesting
                                  ? CustomLoader(width: 40, height: 40)
                                  : const Text(
                                    "Solicitar",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                  BlocListener<BookingBloc, BookingState>(
                    listener: (context, state) {
                      if (state.status == BookingStatus.requestInQueue) {
                        Navigator.of(context).pop();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          WaitingForDriverDialog.show(
                            context: context,
                            onCancel: () {
                              context.read<BookingBloc>().add(
                                CancelTaxiRequest(),
                              );
                            },
                          );
                        });

                        final currentSessionState =
                            context.read<SessionBloc>().state;
                        if (currentSessionState is! SessionAuthenticated) {
                          return;
                        }

                        context.read<RideTrackingBloc>().add(
                          StartRideTracking(
                            passengerId: currentSessionState.user.id,
                          ),
                        );
                      }
                    },
                    child: const SizedBox.shrink(),
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

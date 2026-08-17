import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:passenger_app/features/ride_tracking/domain/entity/ride_entity.dart';
import 'package:passenger_app/features/ride_tracking/presentation/bloc/ride_tracking_bloc.dart';
import 'package:passenger_app/features/ride_tracking/presentation/screen/widgets/confirm_cancel_ride_dialog.dart';
import 'package:passenger_app/features/ride_tracking/presentation/screen/widgets/driver_arrived_dialog.dart';
import 'package:passenger_app/features/ride_tracking/presentation/screen/widgets/driver_cancelled_dialog.dart';
import 'package:passenger_app/features/ride_tracking/presentation/screen/widgets/trip_completed_dialog.dart';
import 'package:passenger_app/features/ride_tracking/presentation/widget/driver_distance_indicator.dart';
import 'package:passenger_app/shared/feedback/feedback_service.dart';
import 'package:passenger_app/shared/presentation/bloc/session/session_bloc.dart';
import '../../../../core/routing/app_routes.dart';

class RideTrackingScreen extends StatelessWidget {
  const RideTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: GetIt.instance<RideTrackingBloc>(),
      child: const _RideTrackingView(),
    );
  }
}

class _RideTrackingView extends StatefulWidget {
  const _RideTrackingView();

  @override
  State<_RideTrackingView> createState() => _RideTrackingViewState();
}

class _RideTrackingViewState extends State<_RideTrackingView> {
  @override
  void initState() {
    super.initState();
    // Por si se llegó acá directo al reabrir la app con un viaje ya en
    // curso (ver SessionBloc/SessionScreen) -- en el flujo normal (booking
    // -> confirmación) el tracking ya lo arrancó ConfirmationDialog, así que
    // este segundo dispatch es idempotente (solo reinicia la subscripción).
    final passengerId = _readPassengerId(context);
    if (passengerId != null) {
      context.read<RideTrackingBloc>().add(
        StartRideTracking(passengerId: passengerId),
      );
    }
  }

  Future<void> _onRideCancelled(BuildContext context, RideEntity? ride) async {
    // 'passenger' == fui yo quien canceló (ya vi mi propio diálogo de
    // confirmación); 'driver' == el conductor canceló, así que aviso aquí.
    if (ride?.cancelledBy == 'driver') {
      GetIt.instance<FeedbackService>().announce(
        'El conductor canceló el viaje',
        withVibration: true,
      );
      await DriverCancelledDialog.show(context: context);
    }

    if (!context.mounted) return;
    context.read<RideTrackingBloc>().add(StopRideTracking());
    context.go(bookingRoute.route);
  }

  String? _readPassengerId(BuildContext context) {
    final sessionState = context.read<SessionBloc>().state;
    if (sessionState is! SessionAuthenticated) return null;
    return sessionState.user.id;
  }

  Future<void> _onDriverArrived(BuildContext context) async {
    final passengerId = _readPassengerId(context);
    if (passengerId == null) return;

    GetIt.instance<FeedbackService>().announce(
      'El conductor ha llegado',
      withVibration: true,
    );
    await DriverArrivedDialog.show(context: context, passengerId: passengerId);
  }

  Future<void> _onTripCompleted(BuildContext context) async {
    await TripCompletedDialog.show(context: context);

    if (!context.mounted) return;
    context.read<RideTrackingBloc>().add(StopRideTracking());
    context.go(bookingRoute.route);
  }

  Future<void> _onStatusChanged(
    BuildContext context,
    RideTrackingState state,
  ) async {
    switch (state.status) {
      case RideTrackingStatus.driverArrived:
        await _onDriverArrived(context);
        break;
      case RideTrackingStatus.tripCompleted:
        await _onTripCompleted(context);
        break;
      case RideTrackingStatus.cancelled:
        await _onRideCancelled(context, state.ride);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RideTrackingBloc, RideTrackingState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: _onStatusChanged,
      child: BlocBuilder<RideTrackingBloc, RideTrackingState>(
        builder: (context, state) {
          final driver = state.ride?.driver;

          return Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    _buildHeader(context),

                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            DriverDistanceIndicator(
                              progress: state.progress ?? 1.0,
                              distanceLabel: _formatDistance(state.distanceMeters),
                              etaLabel: _formatEta(state.etaMinutes),
                            ),
                            const SizedBox(height: 20),
                            _buildDriverCard(context, driver),
                            const SizedBox(height: 20),
                            _buildTripInfo(context, state.ride),
                            const SizedBox(height: 50),
                            _buildCancelButton(context),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Text(
                'Tu viaje',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: onSurface,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildDriverCard(BuildContext context, DriverEntity? driver) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(context),
      child: Row(
        children: [
          _buildDriverPhoto(context, driver),
          const SizedBox(width: 16),
          Expanded(child: _buildDriverInfo(context, driver)),
          _buildCallButton(context),
        ],
      ),
    );
  }

  Widget _buildDriverPhoto(BuildContext context, DriverEntity? driver) {
    final hasPhoto = driver != null && driver.photo.isNotEmpty;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: onSurface.withValues(alpha: 0.1),
        border: Border.all(color: onSurface.withValues(alpha: 0.15), width: 1.5),
        image:
            hasPhoto
                ? DecorationImage(
                  image: NetworkImage(driver.photo),
                  fit: BoxFit.cover,
                )
                : null,
      ),
      child:
          hasPhoto
              ? null
              : Center(
                child: Icon(
                  Icons.person_rounded,
                  color: onSurface.withValues(alpha: 0.6),
                  size: 34,
                ),
              ),
    );
  }

  Widget _buildDriverInfo(BuildContext context, DriverEntity? driver) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final driverName =
        (driver != null && driver.name.isNotEmpty)
            ? driver.name
            : 'Buscando datos del conductor...';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          driverName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tu conductor está en camino',
          style: TextStyle(fontSize: 14, color: onSurface.withValues(alpha: 0.6)),
        ),
      ],
    );
  }

  Widget _buildCallButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(shape: BoxShape.circle, color: colorScheme.primary),
      child: IconButton(
        onPressed: () {},
        icon: Icon(Icons.phone_rounded, color: colorScheme.onPrimary, size: 22),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildTripInfo(BuildContext context, RideEntity? ride) {
    final pickupAddress = ride?.pickupAddress;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(context),
      child: Column(
        children: [
          _buildInfoRow(
            context,
            icon: Icons.location_on_rounded,
            label: 'Punto de recogida',
            value:
                (pickupAddress == null || pickupAddress.isEmpty)
                    ? 'Ubicación no disponible'
                    : pickupAddress,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isDestination = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;
    final accentColor = isDestination ? colorScheme.error : onSurface;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accentColor.withValues(alpha: isDestination ? 0.1 : 0.08),
          ),
          child: Icon(icon, size: 18, color: accentColor.withValues(alpha: isDestination ? 1 : 0.6)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: onSurface.withValues(alpha: 0.6),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: () {
          final sessionState = context.read<SessionBloc>().state;
          if (sessionState is! SessionAuthenticated) return;

          ConfirmCancelRideDialog.show(
            context: context,
            passengerId: sessionState.user.id,
          );
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colorScheme.error, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          'Cancelar viaje',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.error,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BoxDecoration(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.08)),
    );
  }
}

// Redondeado al múltiplo de 10m más cercano para que no "tiemble" con cada
// actualización de ubicación del conductor (~cada 5s).
String _formatDistance(double? meters) {
  if (meters == null) return '--';

  if (meters < 1000) {
    final rounded = (meters / 10).round() * 10;
    return '$rounded m';
  }

  final km = meters / 1000;
  return '${km.toStringAsFixed(1)} km';
}

String _formatEta(int? minutes) {
  if (minutes == null) return '--';
  if (minutes <= 0) return 'Llegando';
  return '$minutes min';
}

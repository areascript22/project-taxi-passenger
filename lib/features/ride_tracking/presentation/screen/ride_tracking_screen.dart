import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:passenger_app/features/ride_tracking/domain/entity/ride_entity.dart';
import 'package:passenger_app/features/ride_tracking/presentation/bloc/ride_tracking_bloc.dart';
import 'package:passenger_app/features/ride_tracking/presentation/screen/widgets/confirm_cancel_ride_dialog.dart';
import 'package:passenger_app/features/ride_tracking/presentation/screen/widgets/driver_cancelled_dialog.dart';
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

class _RideTrackingView extends StatelessWidget {
  const _RideTrackingView();

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

  @override
  Widget build(BuildContext context) {
    return BlocListener<RideTrackingBloc, RideTrackingState>(
      listenWhen:
          (previous, current) =>
              previous.status != current.status &&
              current.status == RideTrackingStatus.cancelled,
      listener: (context, state) => _onRideCancelled(context, state.ride),
      child: BlocBuilder<RideTrackingBloc, RideTrackingState>(
        builder: (context, state) {
          final driver = state.ride?.driver;

          return Scaffold(
            backgroundColor: const Color(0xFFF7F7F7),
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
                            DriverDistanceIndicator(progress: 0.50),
                            const SizedBox(height: 20),
                            _buildDriverCard(driver),
                            const SizedBox(height: 20),
                            _buildTripInfo(),
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
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          const Expanded(
            child: Center(
              child: Text(
                'Tu viaje',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
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

  Widget _buildDriverCard(DriverEntity? driver) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _buildDriverPhoto(driver),
          const SizedBox(width: 16),
          Expanded(child: _buildDriverInfo(driver)),
          _buildCallButton(),
        ],
      ),
    );
  }

  Widget _buildDriverPhoto(DriverEntity? driver) {
    final hasPhoto = driver != null && driver.photo.isNotEmpty;

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade300,
        border: Border.all(color: Colors.grey.shade400, width: 1.5),
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
              : const Center(
                child: Icon(Icons.person_rounded, color: Colors.black54, size: 34),
              ),
    );
  }

  Widget _buildDriverInfo(DriverEntity? driver) {
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
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tu conductor está en camino',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildCallButton() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black),
      child: IconButton(
        onPressed: () {},
        icon: const Icon(Icons.phone_rounded, color: Colors.white, size: 22),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildTripInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.location_on_rounded,
            label: 'Punto de recogida',
            value: 'Av. Naciones Unidas y Shyris',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isDestination = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDestination ? Colors.red.shade50 : Colors.grey.shade100,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isDestination ? Colors.red.shade400 : Colors.grey.shade600,
          ),
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
                  color: Colors.grey.shade600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCancelButton(BuildContext context) {
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
          side: const BorderSide(color: Colors.red, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: const Text(
          'Cancelar viaje',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.red,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }
}

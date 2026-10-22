import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:passenger_app/core/routing/app_routes.dart';
import 'package:passenger_app/shared/presentation/component/network_avatar.dart';
import 'package:passenger_app/shared/profile_photo/presentation/cubit/profile_photo_cubit.dart';
import 'package:passenger_app/l10n/app_localizations.dart';

class BookingHeader extends StatelessWidget {
  const BookingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: onSurface.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.bookingWhereTo,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.bookingReadyToRide,
                style: TextStyle(
                  fontSize: 14,
                  color: onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          Tooltip(
            message: l10n.bookingOpenProfile,
            child: Semantics(
              button: true,
              label: l10n.bookingOpenProfile,
              child: GestureDetector(
                onTap: () => context.go(profileRoute.route),
                child: NetworkAvatar(
                  photoUrl: context.select<ProfilePhotoCubit, String?>(
                    (cubit) => cubit.state,
                  ),
                  size: 48,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:passenger_app/core/theme/app_colors.dart';

class DriverDistanceIndicator extends StatelessWidget {
  const DriverDistanceIndicator({
    super.key,
    required this.progress,
    required this.distanceLabel,
    required this.etaLabel,
  });

  /// 1 = driver is far away
  /// 0 = driver has arrived
  final double progress;

  /// Ya formateado ("850 m" / "2.4 km" / "--" si todavía no se conoce).
  final String distanceLabel;

  /// Ya formateado ("6 min" / "Llegando" / "--" si todavía no se conoce).
  final String etaLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "El conductor está en camino",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: onSurface,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            "Su conductor se dirige al lugar de recogida.",
            style: TextStyle(color: onSurface.withValues(alpha: 0.6)),
          ),

          const SizedBox(height: 10),

          SizedBox(
            height: 90,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;

                const iconSize = 44.0;

                // progress=1 (recién asignado, lejos) -> extremo derecho.
                // progress=0 (llegó) -> converge con el pin fijo de la
                // izquierda ("Tu ubicación" / punto de recogida).
                final driverX = progress * (width - iconSize);

                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Positioned(
                      left: iconSize / 2,
                      right: iconSize / 2,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: onSurface.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),

                    Positioned(
                      left: 0,
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: colorScheme.primary.withValues(
                          alpha: 0.15,
                        ),
                        child: Icon(
                          Icons.location_pin,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),

                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                      left: driverX,
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: context.appColors.success,
                        child: Icon(
                          Icons.local_taxi,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),

                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Text(
                        "Tu ubicación",
                        style: TextStyle(
                          fontSize: 12,
                          color: onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),

                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Text(
                        "Conductor",
                        style: TextStyle(
                          fontSize: 12,
                          color: onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon: Icons.route,
                  title: "Distancia",
                  value: distanceLabel,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoTile(
                  icon: Icons.access_time,
                  title: "Tiempo estimado",
                  value: etaLabel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: onSurface),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: onSurface.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

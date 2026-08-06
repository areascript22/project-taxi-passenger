import 'package:flutter/material.dart';

class DriverDistanceIndicator extends StatelessWidget {
  const DriverDistanceIndicator({
    super.key,
    required this.progress,
  });

  /// 1 = driver is far away
  /// 0 = driver has arrived
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "La conductora está en camino",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            "Su conductor se dirige al lugar de recogida.",
            style: TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            height: 90,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;

                const iconSize = 44.0;

                final driverX = (1 - progress) * (width - iconSize);

                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Positioned(
                      left: iconSize / 2,
                      right: iconSize / 2,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),

                    const Positioned(
                      left: 0,
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Color(0xffE3F2FD),
                        child: Icon(
                          Icons.location_pin,
                          color: Colors.blue,
                        ),
                      ),
                    ),

                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                      left: driverX,
                      child: const CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.green,
                        child: Icon(
                          Icons.local_taxi,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const Positioned(
                      bottom: 0,
                      left: 0,
                      child: Text(
                        "Tu ubicación",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),

                    const Positioned(
                      bottom: 0,
                      right: 0,
                      child: Text(
                        "Conductor",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
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
                  value: "2.4 km",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoTile(
                  icon: Icons.access_time,
                  title: "Tiempo estimado",
                  value: "6 min",
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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.black87,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
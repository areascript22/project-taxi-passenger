import 'package:flutter/material.dart';

class BookingHeader extends StatelessWidget {
  const BookingHeader({super.key});

  @override
  Widget build(BuildContext context) {
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
                "¿A dónde vas?",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "¿Listo para viajar?",
                style: TextStyle(
                  fontSize: 14,
                  color: onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outline,
              color: colorScheme.primary,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

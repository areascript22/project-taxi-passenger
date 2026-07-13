import 'package:flutter/material.dart';

class LocationDenied extends StatelessWidget {
  final bool isPermanentlyDenied;
  final VoidCallback onEnablePermissionsTapped;

  const LocationDenied({
    super.key,
    required this.isPermanentlyDenied,
    required this.onEnablePermissionsTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_off_rounded,
                color: Colors.orange.shade700,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "¿Dónde te encuentras?",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isPermanentlyDenied
                ? "El acceso al GPS está bloqueado. Ingresa tu punto de partida manualmente o habilítalo en la configuración de tu teléfono para pedir tu unidad más rápido."
                : "Ingresa tu punto de partida manualmente, o activa el GPS para ubicarte al instante.",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onEnablePermissionsTapped,
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange.shade700,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                // Change the button text based on the state!
                isPermanentlyDenied ? "Abrir configuraciones" : "Habilitar ubicación",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

class BookingButton extends StatefulWidget {
  final String pickupLocation;
  final String dropoffLocation;
  final VoidCallback? onRequestConfirmed;

  const BookingButton({
    super.key,
    required this.pickupLocation,
    required this.dropoffLocation,
    this.onRequestConfirmed,
  });

  @override
  State<BookingButton> createState() => _BookingButtonState();
}

class _BookingButtonState extends State<BookingButton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _showRequestDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pink,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        child: const Text(
          "SOLICITAR TAXI",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  void _showRequestDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text("Solicitar Taxi"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_taxi, size: 50, color: Colors.pink),
                const SizedBox(height: 16),
                Text(
                  "Desde: ${widget.pickupLocation}",
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  "Hasta: ${widget.dropoffLocation}",
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                const Text("Buscando conductores cerca de ti..."),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: _confirmRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Confirmar"),
              ),
            ],
          ),
    );
  }

  void _confirmRequest() {
    Navigator.pop(context); // Close dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("¡Taxi solicitado! Conductor asignado."),
        backgroundColor: Colors.green,
      ),
    );

    // Call optional callback
    widget.onRequestConfirmed?.call();
  }
}

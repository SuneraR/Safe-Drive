import 'package:flutter/material.dart';

class StartRideButton extends StatelessWidget {
  const StartRideButton({
    super.key,
    required this.isRideActive,
    required this.onPressed,
  });

  final bool isRideActive;
  final VoidCallback onPressed;

  static const Color _startColor = Color(0xFF2E90FA);
  static const Color _stopColor = Color(0xFFFF6B57);

  @override
  Widget build(BuildContext context) {
    final Color buttonColor = isRideActive ? _stopColor : _startColor;
    final String label = isRideActive ? 'Stop Ride' : 'Start Ride';

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: onPressed,
      icon: Icon(isRideActive ? Icons.stop_circle_outlined : Icons.play_arrow),
      label: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }
}

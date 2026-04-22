import 'package:flutter/material.dart';
import 'package:safe_drive/screens/live_monitoring.dart';

class StartButton extends StatelessWidget {
  const StartButton({super.key});

  static const Color _accentGreen = Color(0xFF65F58B);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _accentGreen,
        foregroundColor: const Color(0xFF121212),
        elevation: 0,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LiveMonitoringScreen()),
        );
      },
      child: const Text(
        "Start Monitoring",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}

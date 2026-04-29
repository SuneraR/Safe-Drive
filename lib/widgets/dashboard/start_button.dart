import 'package:flutter/material.dart';
import 'package:safe_drive/screens/live_monitoring.dart';

class StartButton extends StatelessWidget {
  const StartButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        /// ✅ PRIMARY COLOR FROM THEME
        backgroundColor: theme.colorScheme.primary,

        /// ✅ TEXT COLOR AUTO
        foregroundColor: theme.colorScheme.onPrimary,

        elevation: 0,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LiveMonitoringScreen(),
          ),
        );
      },

      /// ❌ REMOVE CONST (important)
      child: Text(
        "Start Monitoring",
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
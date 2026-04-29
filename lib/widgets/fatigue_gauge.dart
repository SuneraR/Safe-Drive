import 'package:flutter/material.dart';

class FatigueGauge extends StatelessWidget {
  final String fatigueStatus;
  final bool eyesClosed;

  const FatigueGauge({
    super.key,
    required this.fatigueStatus,
    required this.eyesClosed,
  });

  double _fatigueLevel() {
    if (fatigueStatus.contains('Sleepy')) return 0.9;
    if (fatigueStatus.contains('Drowsy')) return 0.55;
    return 0.15;
  }

  Color _fatigueColor() {
    if (fatigueStatus.contains('Sleepy')) return Colors.redAccent;
    if (fatigueStatus.contains('Drowsy')) return Colors.orangeAccent;
    return Colors.greenAccent;
  }

  @override
  Widget build(BuildContext context) {
    final double level = _fatigueLevel();
    final Color levelColor = _fatigueColor();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: levelColor.withOpacity(0.55), width: 2),
      ),
      child: Column(
        children: [
          const Text(
            'Fatigue Gauge',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: 175,
            height: 175,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 175,
                  height: 175,
                  child: CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 14,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withOpacity(0.12),
                    ),
                    backgroundColor: Colors.transparent,
                  ),
                ),
                SizedBox(
                  width: 175,
                  height: 175,
                  child: CircularProgressIndicator(
                    value: level,
                    strokeWidth: 14,
                    valueColor: AlwaysStoppedAnimation<Color>(levelColor),
                    backgroundColor: Colors.transparent,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${(level * 100).round()}%",
                      style: TextStyle(
                        color: levelColor,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      eyesClosed ? 'Eyes Closed' : 'Eyes Open',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Eye detection is running in background',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

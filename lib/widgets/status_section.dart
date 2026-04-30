import 'package:flutter/material.dart';

class StatusSection extends StatelessWidget {
  final bool eyesClosed;
  final String fatigueStatus;

  const StatusSection({
    super.key,
    required this.eyesClosed,
    required this.fatigueStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Eye Status',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    eyesClosed ? 'Closed 🔴' : 'Open 🟢',
                    style: TextStyle(
                      color: eyesClosed ? Colors.red : Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Container(width: 1, height: 50, color: Colors.grey),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fatigue Status',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    fatigueStatus,
                    style: TextStyle(
                      color: fatigueStatus.contains('Normal')
                          ? Colors.green
                          : fatigueStatus.contains('Drowsy')
                          ? Colors.orange
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

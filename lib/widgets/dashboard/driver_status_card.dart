import 'package:flutter/material.dart';
import 'package:safe_drive/widgets/dashboard/status_indicator.dart';
import 'dashboard_card.dart';

class DriverStatusCard extends StatelessWidget {
  const DriverStatusCard({super.key});

  static const Color _textSecondary = Color(0xFFA0A0A0);
  static const Color _accentGreen = Color(0xFF65F58B);

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // LEFT SIDE (text only)
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Driver Status",
                style: TextStyle(color: _textSecondary, fontSize: 14),
              ),
              SizedBox(height: 5),
              Text(
                "Safe",
                style: TextStyle(
                  color: _accentGreen,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // RIGHT SIDE (ring + inner circle)
          const StatusIndicator(),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:safe_drive/widgets/dashboard/status_indicator.dart';
import 'dashboard_card.dart';

class DriverStatusCard extends StatelessWidget {
  const DriverStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DashboardCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // LEFT SIDE (text)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Driver Status",
                style: TextStyle(
                  color: theme.textTheme.bodyMedium!.color!.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "Safe",
                style: TextStyle(
                  /// ✅ PRIMARY COLOR (auto green in both modes)
                  color: theme.colorScheme.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // RIGHT SIDE
          const StatusIndicator(),
        ],
      ),
    );
  }
}
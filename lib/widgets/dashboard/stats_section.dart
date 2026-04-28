import 'package:flutter/material.dart';
import 'stat_card.dart';

class StatsSection extends StatelessWidget {
  const StatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 🔥 HEADER
        Row(
          children: [
            Icon(
              Icons.insights_outlined,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              "Today's Statistics",
              style: TextStyle(
                color: theme.textTheme.bodyLarge!.color,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 15),

        /// CARD 1
        const StatCard(
          icon: Icons.timer,
          title: "Today's Driving Time",
          value: "4h 32m",
          iconBgColor: Color(0xFF1E3A2F),
          iconColor: Color(0xFF65F58B),
        ),

        /// CARD 2
        const StatCard(
          icon: Icons.warning_amber_rounded,
          title: "Fatigue Alerts Count",
          value: "3",
          iconBgColor: Color(0xFF3A2F1E),
          iconColor: Color(0xFFFFD60A),
        ),

        /// CARD 3
        const StatCard(
          icon: Icons.access_time,
          title: "Last Trip Duration",
          value: "2h 15m",
          iconBgColor: Color(0xFF1E2A3A),
          iconColor: Color(0xFF64B5F6),
        ),
      ],
    );
  }
}
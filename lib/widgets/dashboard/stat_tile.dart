import 'package:flutter/material.dart';
import 'dashboard_card.dart';

class StatTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const StatTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DashboardCard(
      child: Row(
        children: [
          /// ✅ ICON COLOR FROM THEME
          Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 28,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              title,
              style: TextStyle(
                /// ✅ SECONDARY TEXT
                color: theme.textTheme.bodyMedium!.color!
                    .withOpacity(0.6),
              ),
            ),
          ),

          Text(
            value,
            style: TextStyle(
              /// ✅ MAIN TEXT
              color: theme.textTheme.bodyLarge!.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
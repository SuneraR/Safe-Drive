import 'package:flutter/material.dart';

class DashboardCard extends StatelessWidget {
  final Widget child;

  const DashboardCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        /// ✅ USE THEME COLOR
        color: theme.cardColor,

        borderRadius: BorderRadius.circular(16),

        /// ✅ OPTIONAL BORDER (looks good in light mode)
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: child,
    );
  }
}
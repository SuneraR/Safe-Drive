import 'package:flutter/material.dart';

class DashboardCard extends StatelessWidget {
  final Widget child;
  static const Color _surfaceColor = Color(0xFF1C1C1E);

  const DashboardCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

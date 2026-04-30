import 'package:flutter/material.dart';

class StatusIndicator extends StatelessWidget {
  const StatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color accent = theme.colorScheme.primary;

    return Container(
      width: 50,
      height: 50,
      alignment: Alignment.center,

      /// OUTER RING
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: accent,
          width: 3,
        ),
      ),

      /// INNER DOT
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: accent,
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}
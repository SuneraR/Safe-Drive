import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color iconBgColor;
  final Color iconColor;

  const StatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.iconBgColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        /// ✅ CARD COLOR FROM THEME
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),

        /// ✅ OPTIONAL BORDER (better in light mode)
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          // ICON BOX (keep as is — customizable)
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor),
          ),

          const SizedBox(width: 15),

          // TEXTS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    /// ✅ SECONDARY TEXT
                    color: theme.textTheme.bodyMedium!.color!
                        .withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: TextStyle(
                    /// ✅ MAIN TEXT
                    color: theme.textTheme.bodyLarge!.color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
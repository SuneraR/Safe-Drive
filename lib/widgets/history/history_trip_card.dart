import 'package:flutter/material.dart';
import 'package:safe_drive/widgets/history/section_card.dart';
import 'package:safe_drive/widgets/history/status_chip.dart';

class HistoryTripCard extends StatelessWidget {
  const HistoryTripCard({
    super.key,
    required this.date,
    required this.duration,
    required this.alerts,
    required this.status,
    required this.statusColor,
  });

  final String date;
  final String duration;
  final String alerts;
  final String status;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color textPrimary =
        theme.textTheme.bodyLarge?.color ?? Colors.white;

    final Color textSecondary =
        theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ??
            Colors.white70;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      /// IMPORTANT: SectionCard no longer needs surfaceColor
      child: SectionCard(
        borderRadius: 12,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Duration: $duration   •   $alerts alerts',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),

            StatusChip(label: status, color: statusColor),
          ],
        ),
      ),
    );
  }
}
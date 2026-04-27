import 'package:flutter/material.dart';
import 'package:safe_drive/services/trip_history_service.dart';
import 'stat_card.dart';

class StatsSection extends StatefulWidget {
  const StatsSection({super.key});

  @override
  State<StatsSection> createState() => _StatsSectionState();
}

class _StatsSectionState extends State<StatsSection> {
  final TripHistoryService _tripHistoryService = TripHistoryService();

  int _todayDrivingSeconds = 0;
  int _todayFatigueAlerts = 0;
  int _lastTripDurationSeconds = 0;
  bool _isLoading = true;

  static const Color _textSecondary = Color(0xFFA0A0A0);
  static const Color _accentGreen = Color(0xFF65F58B);

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final List<TripRecord> trips = await _tripHistoryService.loadTrips();
    final DateTime now = DateTime.now();

    int todayDrivingSeconds = 0;
    int todayFatigueAlerts = 0;

    for (final TripRecord trip in trips) {
      final bool isToday =
          trip.tripDate.year == now.year &&
          trip.tripDate.month == now.month &&
          trip.tripDate.day == now.day;
      if (!isToday) {
        continue;
      }

      todayDrivingSeconds += trip.tripDurationSeconds;
      todayFatigueAlerts += trip.fatigueCount;
    }

    final int lastTripDurationSeconds = trips.isEmpty
        ? 0
        : trips.first.tripDurationSeconds;

    if (!mounted) {
      return;
    }

    setState(() {
      _todayDrivingSeconds = todayDrivingSeconds;
      _todayFatigueAlerts = todayFatigueAlerts;
      _lastTripDurationSeconds = lastTripDurationSeconds;
      _isLoading = false;
    });
  }

  String _formatDuration(int totalSeconds) {
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final String todayDriving = _isLoading
        ? '--'
        : _formatDuration(_todayDrivingSeconds);
    final String fatigueAlerts = _isLoading ? '--' : '$_todayFatigueAlerts';
    final String lastTrip = _isLoading
        ? '--'
        : _formatDuration(_lastTripDurationSeconds);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.insights_outlined, color: _accentGreen, size: 20),
            SizedBox(width: 8),
            Text(
              "Today's Statistics",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 15),

        // CARD 1
        StatCard(
          icon: Icons.timer,
          title: "Today's Driving Time",
          value: todayDriving,
          iconBgColor: Color(0xFF1E3A2F), // dark green bg
          iconColor: Color(0xFF65F58B),
        ),

        // CARD 2
        StatCard(
          icon: Icons.warning_amber_rounded,
          title: "Fatigue Alerts Count",
          value: fatigueAlerts,
          iconBgColor: Color(0xFF3A2F1E), // dark yellow bg
          iconColor: Color(0xFFFFD60A),
        ),

        // CARD 3
        StatCard(
          icon: Icons.access_time,
          title: "Last Trip Duration",
          value: lastTrip,
          iconBgColor: Color(0xFF1E2A3A), // dark blue bg
          iconColor: Color(0xFF64B5F6),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:safe_drive/services/trip_history_service.dart';
import '../widgets/history/history_trip_card.dart';
import '../widgets/history/section_card.dart';
import '../widgets/history/section_header.dart';
import '../widgets/history/stat_value_tile.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TripHistoryService _tripHistoryService = TripHistoryService();
  List<TripRecord> _recentTrips = <TripRecord>[];
  bool _isLoadingTrips = true;

  // Colors
  final Color bgColor = const Color(0xFF121212);
  final Color cardBgColor = const Color(0xFF1C1C1E);
  final Color accentYellow = const Color(0xFFFFD60A);
  final Color accentGreen = const Color(0xFF32D74B);
  final Color accentBlue = const Color(0xFF64B5F6);
  final Color accentRed = const Color(0xFFFF453A);
  final Color textGrey = const Color(0xFF8E8E93);

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    await _tripHistoryService.syncPendingTrips();
    final List<TripRecord> trips = await _tripHistoryService.loadTrips();
    if (!mounted) return;

    setState(() {
      _recentTrips = trips;
      _isLoadingTrips = false;
    });
  }

  String _formatDuration(int totalSeconds) {
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
  }

  String _formatTripDate(DateTime tripDate) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime tripDay = DateTime(tripDate.year, tripDate.month, tripDate.day);
    final Duration dayDiff = today.difference(tripDay);

    final String hour = tripDate.hour.toString().padLeft(2, '0');
    final String minute = tripDate.minute.toString().padLeft(2, '0');
    
    if (dayDiff.inDays == 0) return 'Today, $hour:$minute';
    if (dayDiff.inDays == 1) return 'Yesterday, $hour:$minute';

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[tripDate.month - 1]} ${tripDate.day}, $hour:$minute';
  }

  String _statusLabel(double fatigueScore) {
    if (fatigueScore >= 0.78) return 'High';
    if (fatigueScore >= 0.58) return 'Moderate';
    return 'Good';
  }

  Color _statusColor(double fatigueScore) {
    if (fatigueScore >= 0.78) return accentRed;
    if (fatigueScore >= 0.58) return accentYellow;
    return accentGreen;
  }

  // --- Chart Data Helper Methods ---

  List<FlSpot> _getTodayFatigueSpots() {
    final DateTime now = DateTime.now();
    final todayTrips = _recentTrips.where((trip) {
      return trip.tripDate.year == now.year &&
          trip.tripDate.month == now.month &&
          trip.tripDate.day == now.day;
    }).toList()..sort((a, b) => a.tripDate.compareTo(b.tripDate));

    if (todayTrips.isEmpty) return const [FlSpot(0, 0), FlSpot(23, 0)];

    return todayTrips.map((trip) {
      final double x = trip.tripDate.hour + (trip.tripDate.minute / 60.0);
      final double y = (trip.fatigueScore * 100).clamp(0.0, 100.0);
      return FlSpot(x, y);
    }).toList();
  }

  BarChartGroupData _makeBarData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: accentYellow,
          width: 12,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  List<BarChartGroupData> _getWeeklyAlertBars() {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    final List<double> alertsByWeekday = List.filled(7, 0);

    for (final trip in _recentTrips) {
      if (trip.tripDate.isAfter(startDate)) {
        final int index = trip.tripDate.weekday - 1; 
        alertsByWeekday[index] += trip.fatigueCount;
      }
    }
    return List.generate(7, (i) => _makeBarData(i, alertsByWeekday[i]));
  }

  // --- UI Build Methods ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme),
              const SizedBox(height: 32),
              _buildSummaryCard(),
              const SizedBox(height: 24),
              _buildLineChartCard(theme),
              const SizedBox(height: 24),
              _buildBarChartCard(theme),
              const SizedBox(height: 32),
              Text(
                'Recent Trips',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildRecentTripsList(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'History & Analytics',
          style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Track your fatigue patterns',
          style: TextStyle(color: textGrey.withValues(alpha: 0.6), fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final int totalTrips = _recentTrips.length;
    final int totalAlerts = _recentTrips.fold(0, (sum, trip) => sum + trip.fatigueCount);
    final int totalSeconds = _recentTrips.fold(0, (sum, trip) => sum + trip.tripDurationSeconds);
    final double avgFatigue = totalTrips == 0 
        ? 0 
        : (_recentTrips.map((t) => t.fatigueScore).reduce((a, b) => a + b) / totalTrips);

    return SectionCard(
      child: Column(
        children: [
          const SectionHeader(
            icon: Icons.calendar_today_outlined,
            title: 'Saved Trips Summary',
            accentColor: Color(0xFF32D74B),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: StatValueTile(label: 'Total Trips', value: '$totalTrips')),
              Expanded(child: StatValueTile(label: 'Total Alerts', value: '$totalAlerts', valueColor: accentYellow)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: StatValueTile(label: 'Driving Time', value: '${totalSeconds ~/ 3600}h')),
              Expanded(child: StatValueTile(label: 'Avg Fatigue', value: '${(avgFatigue * 100).toStringAsFixed(0)}%', valueColor: accentGreen)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTripsList() {
    if (_isLoadingTrips) return const Center(child: CircularProgressIndicator());
    if (_recentTrips.isEmpty) {
      return Text('No trips found yet.', style: TextStyle(color: textGrey));
    }
    return Column(
      children: _recentTrips.take(5).map((trip) => HistoryTripCard(
        date: _formatTripDate(trip.tripDate),
        duration: _formatDuration(trip.tripDurationSeconds),
        alerts: trip.fatigueCount.toString(),
        status: _statusLabel(trip.fatigueScore),
        statusColor: _statusColor(trip.fatigueScore),
      )).toList(),
    );
  }

  Widget _buildLineChartCard(ThemeData theme) {
    final spots = _getTodayFatigueSpots();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardBgColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_down, color: accentBlue, size: 20),
              const SizedBox(width: 8),
              const Text('Fatigue Levels Today', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text('${value.toInt()}:00', style: TextStyle(color: textGrey, fontSize: 10)),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: accentBlue,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: accentBlue.withValues(alpha: 0.1)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChartCard(ThemeData theme) {
    final barGroups = _getWeeklyAlertBars();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardBgColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Weekly Alert Summary', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 32),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: 20,
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        return Text(days[value.toInt() % 7], style: TextStyle(color: textGrey, fontSize: 10));
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
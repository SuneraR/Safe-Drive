import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:safe_drive/services/trip_history_service.dart';
import 'package:safe_drive/widgets/history/history_trip_card.dart';
import 'package:safe_drive/widgets/history/section_card.dart';
import 'package:safe_drive/widgets/history/section_header.dart';
import 'package:safe_drive/widgets/history/stat_value_tile.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TripHistoryService _tripHistoryService = TripHistoryService();
  List<TripRecord> _recentTrips = <TripRecord>[];
  bool _isLoadingTrips = true;

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
    if (!mounted) {
      return;
    }

    setState(() {
      _recentTrips = trips;
      _isLoadingTrips = false;
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

  String _formatTripDate(DateTime tripDate) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime tripDay = DateTime(tripDate.year, tripDate.month, tripDate.day);
    final Duration dayDiff = today.difference(tripDay);

    final String hour = tripDate.hour.toString().padLeft(2, '0');
    final String minute = tripDate.minute.toString().padLeft(2, '0');
    if (dayDiff.inDays == 0) {
      return 'Today, $hour:$minute';
    }
    if (dayDiff.inDays == 1) {
      return 'Yesterday, $hour:$minute';
    }

    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final String month = months[tripDate.month - 1];
    return '$month ${tripDate.day}, $hour:$minute';
  }

  String _statusLabel(double fatigueScore) {
    if (fatigueScore >= 0.78) {
      return 'High';
    }
    if (fatigueScore >= 0.58) {
      return 'Moderate';
    }
    return 'Good';
  }

  Color _statusColor(double fatigueScore) {
    if (fatigueScore >= 0.78) {
      return accentRed;
    }
    if (fatigueScore >= 0.58) {
      return accentYellow;
    }
    return accentGreen;
  }

  Widget _buildRecentTrips() {
    if (_isLoadingTrips) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_recentTrips.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'No trips found yet. Start and stop a ride to save your first trip.',
          style: TextStyle(color: textGrey),
        ),
      );
    }

    return Column(
      children: _recentTrips.take(10).map((TripRecord trip) {
        return HistoryTripCard(
          date: _formatTripDate(trip.tripDate),
          duration: _formatDuration(trip.tripDurationSeconds),
          alerts: trip.fatigueCount.toString(),
          status: _statusLabel(trip.fatigueScore),
          statusColor: _statusColor(trip.fatigueScore),
          surfaceColor: cardBgColor,
          textColor: textGrey,
        );
      }).toList(),
    );
  }

  Widget _buildSummaryCard() {
    final int totalTrips = _recentTrips.length;
    final int totalAlerts = _recentTrips.fold(
      0,
      (int sum, TripRecord trip) => sum + trip.fatigueCount,
    );
    final int totalDurationSeconds = _recentTrips.fold(
      0,
      (int sum, TripRecord trip) => sum + trip.tripDurationSeconds,
    );
    final int totalHours = totalDurationSeconds ~/ 3600;
    final double avgFatigue = totalTrips == 0
        ? 0
        : _recentTrips
                .map((TripRecord trip) => trip.fatigueScore)
                .reduce((double a, double b) => a + b) /
            totalTrips;

    return SectionCard(
      surfaceColor: cardBgColor,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            icon: Icons.calendar_today_outlined,
            title: 'Saved Trips Summary',
            accentColor: Color(0xFF32D74B),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: StatValueTile(
                  label: 'Total Trips',
                  value: totalTrips.toString(),
                  labelColor: textGrey,
                  valueColor: Colors.white,
                ),
              ),
              Expanded(
                child: StatValueTile(
                  label: 'Total Alerts',
                  value: totalAlerts.toString(),
                  labelColor: textGrey,
                  valueColor: accentYellow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: StatValueTile(
                  label: 'Driving Time',
                  value: '${totalHours}h',
                  labelColor: textGrey,
                  valueColor: Colors.white,
                ),
              ),
              Expanded(
                child: StatValueTile(
                  label: 'Avg Fatigue',
                  value: '${(avgFatigue * 100).toStringAsFixed(0)}%',
                  labelColor: textGrey,
                  valueColor: accentGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildSummaryCard(),
              const SizedBox(height: 24),
              _buildLineChartCard(),
              const SizedBox(height: 24),
              _buildBarChartCard(),
              const SizedBox(height: 32),
              const Text(
                'Recent Trips',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildRecentTrips(),
              const SizedBox(height: 80), // Bottom padding for navbar clearance
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'History & Analytics',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Track your fatigue patterns',
          style: TextStyle(color: textGrey, fontSize: 16),
        ),
      ],
    );
  }

  List<FlSpot> _todayFatigueSpots() {
    final DateTime now = DateTime.now();
    final List<TripRecord> todayTrips = _recentTrips.where((TripRecord trip) {
      return trip.tripDate.year == now.year &&
          trip.tripDate.month == now.month &&
          trip.tripDate.day == now.day;
    }).toList()
      ..sort((TripRecord a, TripRecord b) => a.tripDate.compareTo(b.tripDate));

    final List<FlSpot> spots = todayTrips.map((TripRecord trip) {
      final double x = trip.tripDate.hour + (trip.tripDate.minute / 60.0);
      final double y = (trip.fatigueScore * 100).clamp(0.0, 100.0);
      return FlSpot(x, y);
    }).toList();

    if (spots.isEmpty) {
      return const <FlSpot>[FlSpot(0, 0), FlSpot(23, 0)];
    }

    if (spots.length == 1) {
      return <FlSpot>[FlSpot(0, spots.first.y), FlSpot(23, spots.first.y)];
    }

    return spots;
  }

  double _lineChartMaxY(List<FlSpot> spots) {
    double maxY = 0;
    for (final FlSpot spot in spots) {
      if (spot.y > maxY) {
        maxY = spot.y;
      }
    }

    if (maxY <= 20) {
      return 20;
    }

    return ((maxY / 10).ceil() * 10).toDouble();
  }

  List<BarChartGroupData> _weeklyAlertBars() {
    final DateTime now = DateTime.now();
    final DateTime startDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));

    final List<double> alertsByWeekday = List<double>.filled(7, 0);
    for (final TripRecord trip in _recentTrips) {
      final DateTime date = trip.tripDate;
      final DateTime day = DateTime(date.year, date.month, date.day);
      if (day.isBefore(startDate)) {
        continue;
      }

      final int weekdayIndex = date.weekday - 1; // Monday=0 ... Sunday=6
      alertsByWeekday[weekdayIndex] += trip.fatigueCount;
    }

    return List<BarChartGroupData>.generate(7, (int index) {
      return _makeBarData(index, alertsByWeekday[index]);
    });
  }

  double _weeklyBarMaxY(List<BarChartGroupData> bars) {
    double maxY = 0;
    for (final BarChartGroupData bar in bars) {
      if (bar.barRods.isEmpty) {
        continue;
      }

      final double value = bar.barRods.first.toY;
      if (value > maxY) {
        maxY = value;
      }
    }

    if (maxY < 4) {
      return 4;
    }

    return (maxY + 1).ceilToDouble();
  }

  Widget _buildLineChartCard() {
    final List<FlSpot> spots = _todayFatigueSpots();
    final double maxY = _lineChartMaxY(spots);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_down, color: accentBlue, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Fatigue Levels Today',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 15,
                  verticalInterval: 2,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: textGrey.withOpacity(0.15),
                      strokeWidth: 1,
                      dashArray: [4, 4], // Dashed line
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: textGrey.withOpacity(0.15),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 4,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '${value.toInt().toString().padLeft(2, '0')}:00',
                            style: TextStyle(color: textGrey, fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: maxY <= 40 ? 10 : 20,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(color: textGrey, fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(
                      color: textGrey.withOpacity(0.3),
                      width: 1,
                    ),
                    left: BorderSide(
                      color: textGrey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                minX: 0,
                maxX: 23,
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: accentBlue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChartCard() {
    final List<BarChartGroupData> barGroups = _weeklyAlertBars();
    final double maxY = _weeklyBarMaxY(barGroups);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Alert Summary',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const style = TextStyle(
                          color: Color(0xFF8E8E93),
                          fontSize: 10,
                        );
                        String text;
                        switch (value.toInt()) {
                          case 0:
                            text = 'Mon';
                            break;
                          case 1:
                            text = 'Tue';
                            break;
                          case 2:
                            text = 'Wed';
                            break;
                          case 3:
                            text = 'Thu';
                            break;
                          case 4:
                            text = 'Fri';
                            break;
                          case 5:
                            text = 'Sat';
                            break;
                          case 6:
                            text = 'Sun';
                            break;
                          default:
                            text = '';
                            break;
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(text, style: style),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: maxY <= 8 ? 1 : 2,
                      reservedSize: 20,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(color: textGrey, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: maxY <= 8 ? 1 : 2,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: textGrey.withOpacity(0.15),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: textGrey.withOpacity(0.15),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(
                      color: textGrey.withOpacity(0.3),
                      width: 1,
                    ),
                    left: BorderSide(
                      color: textGrey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: accentYellow,
          width: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }
}

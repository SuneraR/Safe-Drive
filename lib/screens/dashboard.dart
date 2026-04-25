import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

import '../controllers/fatigue_monitoring_controller.dart';
import '../services/fatigue_detection_service.dart';
import '../widgets/dashboard/driver_status_card.dart';
import '../widgets/dashboard/start_ride_button.dart';
import '../widgets/dashboard/start_button.dart';
import '../widgets/dashboard/stats_section.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late final FatigueMonitoringController _fatigueController;
  late final AudioPlayer _warningPlayer;

  static const Color _bgColor = Color(0xFF121212);
  static const Color _textSecondary = Color(0xFFA0A0A0);

  @override
  void initState() {
    super.initState();

    _warningPlayer = AudioPlayer();

    _fatigueController = FatigueMonitoringController(
      service: FatigueDetectionService(),
    );
    _fatigueController.onWarning = _handleFatigueWarning;
  }

  @override
  void dispose() {
    _warningPlayer.dispose();
    _fatigueController.dispose();
    super.dispose();
  }

  Future<void> _toggleRide() async {
    final bool active = _fatigueController.state.value.isRideActive;
    if (active) {
      await _fatigueController.stopRide();
      return;
    }

    await _fatigueController.startRide();
  }

  Future<void> _handleFatigueWarning(FatigueDetectionUpdate update) async {
    if (!mounted) {
      return;
    }

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    if (await Vibration.hasVibrator() ?? false) {
      await Vibration.vibrate(duration: 600, amplitude: 255);
    } else {
      await HapticFeedback.heavyImpact();
    }

    await _warningPlayer.stop();
    await _warningPlayer.play(AssetSource('sounds/warning.mp3'));

    final bool critical = update.level == FatigueRiskLevel.critical;
    final String prefix = critical
        ? 'Critical fatigue risk'
        : 'Fatigue warning';

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: critical
              ? Colors.red.shade700
              : Colors.orange.shade800,
          duration: const Duration(seconds: 4),
          content: Text('$prefix: ${update.reason}'),
        ),
      );
  }

  Color _riskColor(FatigueRiskLevel level) {
    switch (level) {
      case FatigueRiskLevel.normal:
        return Colors.greenAccent;
      case FatigueRiskLevel.warning:
        return Colors.orangeAccent;
      case FatigueRiskLevel.critical:
        return Colors.redAccent;
    }
  }

  String _riskLabel(FatigueRiskLevel level) {
    switch (level) {
      case FatigueRiskLevel.normal:
        return 'Normal';
      case FatigueRiskLevel.warning:
        return 'Warning';
      case FatigueRiskLevel.critical:
        return 'Critical';
    }
  }

  Widget _fatigueStatusCard(FatigueMonitorState state) {
    final String scorePercent = (state.score * 100).toStringAsFixed(0);
    final Color levelColor = _riskColor(state.level);
    final String levelLabel = _riskLabel(state.level);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2B2B2D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Background Fatigue Detection',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: levelColor.withValues(alpha: 0.65)),
                ),
                child: Text(
                  levelLabel,
                  style: TextStyle(
                    color: levelColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            state.reason,
            style: const TextStyle(color: Color(0xFFCACACA), fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            'Risk score: $scorePercent%',
            style: const TextStyle(color: Color(0xFFAEAEAE), fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            state.isRideActive
                ? 'Monitoring running in dashboard background.'
                : 'Start Ride to begin passive monitoring.',
            style: const TextStyle(color: Color(0xFF8C8C8C), fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Dashboard",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Good evening, driver",
                style: TextStyle(color: _textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 32),
              const DriverStatusCard(),
              const SizedBox(height: 20),
              ValueListenableBuilder<FatigueMonitorState>(
                valueListenable: _fatigueController.state,
                builder: (BuildContext context, FatigueMonitorState state, _) {
                  return StartRideButton(
                    isRideActive: state.isRideActive,
                    onPressed: _toggleRide,
                  );
                },
              ),
              const SizedBox(height: 12),
              const StartButton(),
              const SizedBox(height: 14),
              ValueListenableBuilder<FatigueMonitorState>(
                valueListenable: _fatigueController.state,
                builder: (BuildContext context, FatigueMonitorState state, _) {
                  return _fatigueStatusCard(state);
                },
              ),
              const SizedBox(height: 24),
              const StatsSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

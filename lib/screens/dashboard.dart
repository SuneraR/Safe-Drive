import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:provider/provider.dart';
import '../controllers/fatigue_monitoring_controller.dart';
import 'app_settings_provider.dart';
import '../services/app_notification_service.dart';
import '../services/fatigue_detection_service.dart';
import '../services/ride_background_service.dart';
import '../services/trip_history_service.dart';
import '../widgets/dashboard/driver_status_card.dart';
import '../widgets/dashboard/start_ride_button.dart';
import '../widgets/dashboard/start_button.dart';
import '../widgets/dashboard/stats_section.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with WidgetsBindingObserver {
  late final AppSettingsNotifier _appSettings;
  late FatigueMonitoringController _fatigueController;
  late final AudioPlayer _warningPlayer;
  late final TripHistoryService _tripHistoryService;
  late final Future<String> _userNameFuture;

  bool _isAppForeground = true;

  DateTime? _rideStartedAt;
  int _fatigueAlertCount = 0;
  double _latestFatigueScore = 0;
  int _statsRefreshVersion = 0;

  static const Color _bgColor = Color(0xFF121212);
  static const Color _textSecondary = Color(0xFFA0A0A0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _appSettings = context.read<AppSettingsNotifier>();
    _appSettings.addListener(_handleSettingsChanged);

    _warningPlayer = AudioPlayer();
    _tripHistoryService = TripHistoryService();
    _userNameFuture = _loadUserName();

    _createFatigueController();
    Future<void>.microtask(_syncPendingTrips);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appSettings.removeListener(_handleSettingsChanged);
    _fatigueController.state.removeListener(_onFatigueStateChanged);
    unawaited(_fatigueController.dispose());
    _warningPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppForeground = state == AppLifecycleState.resumed;
  }

  void _onFatigueStateChanged() {
    _latestFatigueScore = _fatigueController.state.value.score;
  }

  void _handleSettingsChanged() {
    if (!mounted || _fatigueController.state.value.isRideActive) {
      return;
    }

    _fatigueController.state.removeListener(_onFatigueStateChanged);
    unawaited(_fatigueController.dispose());
    _createFatigueController();
    setState(() {});
  }

  void _createFatigueController() {
    _fatigueController = FatigueMonitoringController(
      service: FatigueDetectionService(
        warningThreshold: _appSettings.warningThreshold,
        criticalThreshold: _appSettings.criticalThreshold,
      ),
    );
    _fatigueController.onWarning = _handleFatigueWarning;
    _fatigueController.state.addListener(_onFatigueStateChanged);
  }

  Future<void> _syncPendingTrips() async {
    await _tripHistoryService.syncPendingTrips();
  }

  Future<String> _loadUserName() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return 'driver';
    }

    final String? authName = user.displayName?.trim();
    if (authName != null && authName.isNotEmpty) {
      return authName;
    }

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

    final String? firestoreName = snapshot.data()?['name']?.toString().trim();
    if (firestoreName != null && firestoreName.isNotEmpty) {
      return firestoreName;
    }

    final String? email = user.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }

    return 'driver';
  }

  String _greetingPrefix() {
    final int hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good morning';
    }

    if (hour < 17) {
      return 'Good afternoon';
    }

    return 'Good evening';
  }

  Future<void> _toggleRide() async {
    final bool active = _fatigueController.state.value.isRideActive;
    if (active) {
      final DateTime stoppedAt = DateTime.now();
      await _fatigueController.stopRide();
      await RideBackgroundService.instance.stop();

      final DateTime? startedAt = _rideStartedAt;
      if (startedAt != null && stoppedAt.isAfter(startedAt)) {
        await _tripHistoryService.persistTripAndUpload(
          tripDuration: stoppedAt.difference(startedAt),
          fatigueCount: _fatigueAlertCount,
          fatigueScore: _latestFatigueScore,
          tripDate: stoppedAt,
        );

        if (mounted) {
          setState(() {
            _statsRefreshVersion++;
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('Trip saved locally and upload attempted.'),
              ),
            );
        }
      }

      _rideStartedAt = null;
      return;
    }

    await RideBackgroundService.instance.start();
    await _fatigueController.startRide();
    _rideStartedAt = DateTime.now();
    _fatigueAlertCount = 0;
    _latestFatigueScore = 0;
  }

  Future<void> _handleFatigueWarning(FatigueDetectionUpdate update) async {
    _fatigueAlertCount++;

    final bool critical = update.level == FatigueRiskLevel.critical;
    final String prefix = critical
        ? 'Critical fatigue risk'
        : 'Fatigue warning';

    if (_appSettings.notificationsEnabled) {
      unawaited(
        AppNotificationService.instance.showFatigueWarning(
          title: prefix,
          body: update.reason,
          critical: critical,
        ),
      );
    }

    if (_isAppForeground) {
      if (await Vibration.hasVibrator()) {
        await Vibration.vibrate(duration: 600, amplitude: 255);
      } else {
        await HapticFeedback.heavyImpact();
      }

      if (_appSettings.alertSoundEnabled) {
        await _warningPlayer.stop();
        await _warningPlayer.play(AssetSource('sounds/warning.mp3'));
      }
    }

    if (!mounted) {
      return;
    }

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

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
              FutureBuilder<String>(
                future: _userNameFuture,
                builder:
                    (BuildContext context, AsyncSnapshot<String> snapshot) {
                      final String name = snapshot.data ?? 'driver';

                      return Text(
                        '${_greetingPrefix()}, $name',
                        style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 16,
                        ),
                      );
                    },
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
              StatsSection(key: ValueKey<int>(_statsRefreshVersion)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/fatigue_detection_service.dart';

class FatigueMonitorState {
  const FatigueMonitorState({
    required this.isRideActive,
    required this.level,
    required this.score,
    required this.reason,
    required this.lastUpdated,
  });

  factory FatigueMonitorState.initial() {
    return const FatigueMonitorState(
      isRideActive: false,
      level: FatigueRiskLevel.normal,
      score: 0,
      reason: 'Ride is not running.',
      lastUpdated: null,
    );
  }

  final bool isRideActive;
  final FatigueRiskLevel level;
  final double score;
  final String reason;
  final DateTime? lastUpdated;

  FatigueMonitorState copyWith({
    bool? isRideActive,
    FatigueRiskLevel? level,
    double? score,
    String? reason,
    DateTime? lastUpdated,
  }) {
    return FatigueMonitorState(
      isRideActive: isRideActive ?? this.isRideActive,
      level: level ?? this.level,
      score: score ?? this.score,
      reason: reason ?? this.reason,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class FatigueMonitoringController {
  FatigueMonitoringController({
    required FatigueDetectionService service,
    this.warningCooldown = const Duration(seconds: 16),
  }) : _service = service;

  final FatigueDetectionService _service;
  final Duration warningCooldown;

  final ValueNotifier<FatigueMonitorState> state =
      ValueNotifier<FatigueMonitorState>(FatigueMonitorState.initial());

  StreamSubscription<FatigueDetectionUpdate>? _updatesSub;
  DateTime? _lastWarningAt;

  Future<void> Function(FatigueDetectionUpdate update)? onWarning;

  Future<void> startRide() async {
    if (_service.isRunning) {
      return;
    }

    _updatesSub ??= _service.updates.listen(_onDetectionUpdate);
    _service.start();

    state.value = state.value.copyWith(
      isRideActive: true,
      reason: 'Monitoring background fatigue signals.',
    );
  }

  Future<void> stopRide() async {
    if (!_service.isRunning) {
      return;
    }

    await _service.stop();
    _lastWarningAt = null;
    state.value = const FatigueMonitorState(
      isRideActive: false,
      level: FatigueRiskLevel.normal,
      score: 0,
      reason: 'Ride stopped. Monitoring paused.',
      lastUpdated: null,
    );
  }

  Future<void> dispose() async {
    await _updatesSub?.cancel();
    _updatesSub = null;
    await _service.dispose();
    state.dispose();
  }

  void _onDetectionUpdate(FatigueDetectionUpdate update) {
    state.value = state.value.copyWith(
      level: update.level,
      score: update.score,
      reason: update.reason,
      lastUpdated: update.timestamp,
    );

    final bool shouldWarn =
        update.level == FatigueRiskLevel.warning ||
        update.level == FatigueRiskLevel.critical;
    if (!shouldWarn) {
      return;
    }

    final DateTime now = DateTime.now();
    if (_lastWarningAt != null &&
        now.difference(_lastWarningAt!) < warningCooldown) {
      return;
    }

    _lastWarningAt = now;
    onWarning?.call(update);
  }
}

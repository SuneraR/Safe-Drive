import 'dart:async';
import 'dart:developer' as developer;
import 'dart:isolate';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sensors_plus/sensors_plus.dart';

enum FatigueRiskLevel { normal, warning, critical }

class FatigueDetectionUpdate {
  const FatigueDetectionUpdate({
    required this.score,
    required this.level,
    required this.reason,
    required this.timestamp,
  });

  final double score;
  final FatigueRiskLevel level;
  final String reason;
  final DateTime timestamp;
}

class FatigueDetectionService {
  FatigueDetectionService({
    this.evaluationInterval = const Duration(seconds: 2),
    this.sampleInterval = const Duration(milliseconds: 120),
    this.maxWindowSamples = 90,
  });

  final Duration evaluationInterval;
  final Duration sampleInterval;
  final int maxWindowSamples;

  final StreamController<FatigueDetectionUpdate> _updatesController =
      StreamController<FatigueDetectionUpdate>.broadcast();

  final List<double> _accelerometerMagnitudeWindow = <double>[];
  final List<double> _gyroscopeMagnitudeWindow = <double>[];
  final List<double> _pitchWindow = <double>[];

  StreamSubscription<AccelerometerEvent>? _accelerometerSub;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSub;
  Timer? _evaluationTimer;

  DateTime? _lastAccelerometerSampleAt;
  DateTime? _lastGyroscopeSampleAt;

  String? _sessionId;
  DateTime? _sessionStartedAt;
  int _sessionUpdateCount = 0;
  double _sessionHighestScore = 0;
  FatigueRiskLevel _sessionHighestLevel = FatigueRiskLevel.normal;
  FatigueDetectionUpdate? _lastUpdate;

  bool _isRunning = false;
  bool _isEvaluating = false;

  Stream<FatigueDetectionUpdate> get updates => _updatesController.stream;
  bool get isRunning => _isRunning;

  void start() {
    if (_isRunning) {
      return;
    }

    _isRunning = true;
    _sessionId = DateTime.now().microsecondsSinceEpoch.toString();
    _sessionStartedAt = DateTime.now();
    _sessionUpdateCount = 0;
    _sessionHighestScore = 0;
    _sessionHighestLevel = FatigueRiskLevel.normal;
    _lastUpdate = null;
    _clearWindows();

    unawaited(_createSessionSkeleton());

    _accelerometerSub = accelerometerEventStream().listen(
      _onAccelerometerEvent,
    );
    _gyroscopeSub = gyroscopeEventStream().listen(_onGyroscopeEvent);

    _evaluationTimer = Timer.periodic(evaluationInterval, (_) {
      _evaluateWindow();
    });
  }

  Future<void> stop() async {
    if (!_isRunning) {
      return;
    }

    _isRunning = false;

    await _accelerometerSub?.cancel();
    await _gyroscopeSub?.cancel();
    _accelerometerSub = null;
    _gyroscopeSub = null;

    _evaluationTimer?.cancel();
    _evaluationTimer = null;

    await _saveSessionSummary();

    _clearWindows();
    _sessionId = null;
    _sessionStartedAt = null;
    _sessionUpdateCount = 0;
    _sessionHighestScore = 0;
    _sessionHighestLevel = FatigueRiskLevel.normal;
    _lastUpdate = null;
  }

  Future<void> dispose() async {
    await stop();
    await _updatesController.close();
  }

  void _onAccelerometerEvent(AccelerometerEvent event) {
    if (!_isRunning) {
      return;
    }

    final DateTime now = DateTime.now();
    if (_lastAccelerometerSampleAt != null &&
        now.difference(_lastAccelerometerSampleAt!) < sampleInterval) {
      return;
    }
    _lastAccelerometerSampleAt = now;

    final double magnitude = math.sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );
    final double pitch = math.atan2(
      event.x,
      math.sqrt(event.y * event.y + event.z * event.z),
    );

    _appendSample(_accelerometerMagnitudeWindow, magnitude);
    _appendSample(_pitchWindow, pitch);
  }

  void _onGyroscopeEvent(GyroscopeEvent event) {
    if (!_isRunning) {
      return;
    }

    final DateTime now = DateTime.now();
    if (_lastGyroscopeSampleAt != null &&
        now.difference(_lastGyroscopeSampleAt!) < sampleInterval) {
      return;
    }
    _lastGyroscopeSampleAt = now;

    final double magnitude = math.sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );
    _appendSample(_gyroscopeMagnitudeWindow, magnitude);
  }

  Future<void> _evaluateWindow() async {
    if (!_isRunning || _isEvaluating) {
      return;
    }

    if (_accelerometerMagnitudeWindow.length < 12 ||
        _gyroscopeMagnitudeWindow.length < 12 ||
        _pitchWindow.length < 12) {
      return;
    }

    _isEvaluating = true;

    final Map<String, Object> payload = <String, Object>{
      'accelerometer': List<double>.from(_accelerometerMagnitudeWindow),
      'gyroscope': List<double>.from(_gyroscopeMagnitudeWindow),
      'pitch': List<double>.from(_pitchWindow),
    };

    try {
      final Map<String, Object> output = await Isolate.run(
        () => _computeFatigueSignals(payload),
      );

      final FatigueRiskLevel level =
          FatigueRiskLevel.values[(output['levelIndex'] as int).clamp(
            0,
            FatigueRiskLevel.values.length - 1,
          )];

      final FatigueDetectionUpdate update = FatigueDetectionUpdate(
        score: output['score'] as double,
        level: level,
        reason: output['reason'] as String,
        timestamp: DateTime.now(),
      );

      _updatesController.add(update);
      _lastUpdate = update;
      _sessionUpdateCount++;
      if (update.score >= _sessionHighestScore) {
        _sessionHighestScore = update.score;
      }
      if (update.level.index >= _sessionHighestLevel.index) {
        _sessionHighestLevel = update.level;
      }

      await _persistUpdate(update);
    } finally {
      _isEvaluating = false;
    }
  }

  void _appendSample(List<double> window, double value) {
    window.add(value);
    if (window.length > maxWindowSamples) {
      window.removeAt(0);
    }
  }

  void _clearWindows() {
    _accelerometerMagnitudeWindow.clear();
    _gyroscopeMagnitudeWindow.clear();
    _pitchWindow.clear();
    _lastAccelerometerSampleAt = null;
    _lastGyroscopeSampleAt = null;
  }

  Future<void> _persistUpdate(FatigueDetectionUpdate update) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null || _sessionId == null) {
      developer.log(
        'Skipping fatigue update write because user/session is missing.',
        name: 'FatigueDetectionService',
      );
      return;
    }

    try {
      final String recordId = update.timestamp.microsecondsSinceEpoch
          .toString();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('fatigue_sessions')
          .doc(_sessionId)
          .collection('updates')
          .doc(recordId)
          .set(<String, Object?>{
            'uid': user.uid,
            'sessionId': _sessionId,
            'score': update.score,
            'level': update.level.name,
            'reason': update.reason,
            'timestamp': Timestamp.fromDate(update.timestamp),
            'createdAt': FieldValue.serverTimestamp(),
            'isAlert': update.level != FatigueRiskLevel.normal,
          });
    } catch (error, stackTrace) {
      // Stop the ride even if this write fails; the user-facing flow must stay responsive.
      developer.log(
        'Failed to persist fatigue update.',
        name: 'FatigueDetectionService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _createSessionSkeleton() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null || _sessionId == null) {
      developer.log(
        'Skipping fatigue session start write because user/session is missing.',
        name: 'FatigueDetectionService',
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('fatigue_sessions')
          .doc(_sessionId)
          .set(<String, Object?>{
            'uid': user.uid,
            'sessionId': _sessionId,
            'startedAt': _sessionStartedAt != null
                ? Timestamp.fromDate(_sessionStartedAt!)
                : FieldValue.serverTimestamp(),
            'status': 'active',
            'createdAt': FieldValue.serverTimestamp(),
            'updateCount': 0,
            'highestScore': 0,
            'highestLevel': FatigueRiskLevel.normal.name,
          }, SetOptions(merge: true));
    } catch (error, stackTrace) {
      developer.log(
        'Failed to create fatigue session start document.',
        name: 'FatigueDetectionService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _saveSessionSummary() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null || _sessionId == null) {
      developer.log(
        'Skipping fatigue session summary write because user/session is missing.',
        name: 'FatigueDetectionService',
      );
      return;
    }

    try {
      final FatigueDetectionUpdate? lastUpdate = _lastUpdate;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('fatigue_sessions')
          .doc(_sessionId)
          .set(<String, Object?>{
            'uid': user.uid,
            'sessionId': _sessionId,
            'startedAt': _sessionStartedAt != null
                ? Timestamp.fromDate(_sessionStartedAt!)
                : FieldValue.serverTimestamp(),
            'endedAt': FieldValue.serverTimestamp(),
            'updateCount': _sessionUpdateCount,
            'highestScore': _sessionHighestScore,
            'highestLevel': _sessionHighestLevel.name,
            'lastScore': lastUpdate?.score,
            'lastLevel': lastUpdate?.level.name,
            'lastReason': lastUpdate?.reason,
            'status': 'completed',
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (error, stackTrace) {
      // Session persistence is best-effort so stopping is never blocked.
      developer.log(
        'Failed to persist fatigue session summary.',
        name: 'FatigueDetectionService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

Map<String, Object> _computeFatigueSignals(Map<String, Object> payload) {
  final List<double> accelerometer = (payload['accelerometer'] as List<dynamic>)
      .cast<double>();
  final List<double> gyroscope = (payload['gyroscope'] as List<dynamic>)
      .cast<double>();
  final List<double> pitch = (payload['pitch'] as List<dynamic>).cast<double>();

  final List<double> accelDiff = _diff(accelerometer);

  final double gyroInstability = _clamp01(_stdDev(gyroscope) / 1.15);
  final double motionJerk = _clamp01(
    (_ratioOverThreshold(accelDiff, 1.8) * 2.1) + (_stdDev(accelDiff) / 3.5),
  );
  final double irregularSteering = _clamp01(
    (gyroInstability * 0.65) + (motionJerk * 0.35),
  );

  final double suddenBraking = _clamp01(
    (_ratioUnderThreshold(accelDiff, -2.6) * 3.5),
  );
  final double inconsistentAcceleration = _clamp01(
    _ratioOverThreshold(accelDiff, 2.3) * 2.0,
  );
  final double inconsistentSpeed = _clamp01(
    (suddenBraking * 0.55) + (inconsistentAcceleration * 0.45),
  );

  final double pitchDrift = _clamp01((_range(pitch).abs()) / 0.8);
  final double pitchBias = _clamp01(_mean(pitch).abs() / 0.55);
  final double drowsyTilt = _clamp01((pitchDrift * 0.55) + (pitchBias * 0.45));

  final double score = _clamp01(
    (irregularSteering * 0.38) +
        (inconsistentSpeed * 0.34) +
        (drowsyTilt * 0.28),
  );

  FatigueRiskLevel level = FatigueRiskLevel.normal;
  if (score >= 0.78) {
    level = FatigueRiskLevel.critical;
  } else if (score >= 0.58) {
    level = FatigueRiskLevel.warning;
  }

  String reason = 'Driver pattern stable.';
  final Map<String, double> componentMap = <String, double>{
    'Irregular steering and motion': irregularSteering,
    'Sudden braking or acceleration spikes': inconsistentSpeed,
    'Drowsy tilt posture trends': drowsyTilt,
  };
  final String topSignal = componentMap.entries.reduce((
    MapEntry<String, double> a,
    MapEntry<String, double> b,
  ) {
    return a.value >= b.value ? a : b;
  }).key;
  if (level != FatigueRiskLevel.normal) {
    reason = '$topSignal detected.';
  }

  return <String, Object>{
    'score': score,
    'levelIndex': level.index,
    'reason': reason,
  };
}

List<double> _diff(List<double> values) {
  if (values.length < 2) {
    return <double>[];
  }

  final List<double> delta = <double>[];
  for (int i = 1; i < values.length; i++) {
    delta.add(values[i] - values[i - 1]);
  }
  return delta;
}

double _mean(List<double> values) {
  if (values.isEmpty) {
    return 0;
  }
  return values.reduce((double a, double b) => a + b) / values.length;
}

double _stdDev(List<double> values) {
  if (values.length < 2) {
    return 0;
  }

  final double avg = _mean(values);
  final double variance =
      values
          .map((double value) => math.pow(value - avg, 2) as double)
          .reduce((double a, double b) => a + b) /
      values.length;
  return math.sqrt(variance);
}

double _range(List<double> values) {
  if (values.isEmpty) {
    return 0;
  }
  final double minValue = values.reduce(math.min);
  final double maxValue = values.reduce(math.max);
  return maxValue - minValue;
}

double _ratioOverThreshold(List<double> values, double threshold) {
  if (values.isEmpty) {
    return 0;
  }

  final int count = values
      .where((double value) => value.abs() >= threshold)
      .length;
  return count / values.length;
}

double _ratioUnderThreshold(List<double> values, double threshold) {
  if (values.isEmpty) {
    return 0;
  }

  final int count = values.where((double value) => value <= threshold).length;
  return count / values.length;
}

double _clamp01(double value) {
  return value.clamp(0.0, 1.0);
}

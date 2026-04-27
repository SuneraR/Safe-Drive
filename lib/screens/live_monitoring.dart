import 'dart:async';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter_tts/flutter_tts.dart';

class LiveMonitoringScreen extends StatefulWidget {
  const LiveMonitoringScreen({super.key});

  @override
  State<LiveMonitoringScreen> createState() => _LiveMonitoringScreenState();
}

class _LiveMonitoringScreenState extends State<LiveMonitoringScreen>
    with WidgetsBindingObserver {

  CameraController? _controller;
  List<CameraDescription>? cameras;

  late FaceDetector _faceDetector;
  FlutterTts flutterTts = FlutterTts();

  bool isProcessing = false;
  DateTime? lastProcessed;

  int frameSkip = 0;

  // 👁️ Eye detection
  bool eyesClosed = false;
  int closedEyeFrames = 0;

  // ⚡ Fatigue
  String fatigueStatus = "Normal";

  // ⏱️ Timer
  DateTime? eyesClosedStart;
  bool alertShown = false;

  Timer? timer;
  String? _sessionId;
  DateTime? _sessionStartedAt;
  String _lastPersistedStatus = 'Normal';
  bool _sessionSaved = false;
  
  // Yawning detection
  int _yawnCount = 0;
  bool _eyesWereClosed = false;
  DateTime? _eyesClosedTime;
  bool _yawnAlertShown = false;
  late AudioPlayer _alertPlayer;
  
  // UI Colors (matching dashboard)
  static const Color _bgColor = Color(0xFF121212);
  static const Color _cardColor = Color(0xFF1C1C1E);
  static const Color _textSecondary = Color(0xFFA0A0A0);
  static const Color _accentGreen = Color(0xFF65F58B);
  static const Color _accentOrange = Color(0xFFFFD60A);
  static const Color _accentRed = Color(0xFFFF453A);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _alertPlayer = AudioPlayer();

    initCamera();

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        performanceMode: FaceDetectorMode.fast,
      ),
    );

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      checkEyeClosure();
    });

    _sessionId = DateTime.now().microsecondsSinceEpoch.toString();
    _sessionStartedAt = DateTime.now();
    unawaited(_createLiveMonitoringSession());
  }

  Future<void> initCamera() async {
    cameras = await availableCameras();

    final frontCamera = cameras!.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    await _controller!.initialize();

    _controller!.startImageStream(processCameraImage);

    if (!mounted) return;
    setState(() {});
  }

  /// 🔥 ML PROCESS
  Future<void> processCameraImage(CameraImage image) async {
    if (isProcessing) return;

    frameSkip++;
    if (frameSkip % 3 != 0) return;

    final now = DateTime.now();
    if (lastProcessed != null &&
        now.difference(lastProcessed!).inMilliseconds < 700) {
      return;
    }

    lastProcessed = now;
    isProcessing = true;

    try {
      final bytes = Uint8List.fromList(
        image.planes.expand((plane) => plane.bytes).toList(),
      );

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation270deg,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );

      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isNotEmpty) {
        final face = faces.first;

        final left = face.leftEyeOpenProbability ?? 1.0;
        final right = face.rightEyeOpenProbability ?? 1.0;

        if (left < 0.6 && right < 0.6) {
          closedEyeFrames++;
        } else {
          closedEyeFrames = 0;
        }

        eyesClosed = closedEyeFrames > 2;
      }

      if (mounted) setState(() {});
    } catch (e) {
      print("ML ERROR: $e");
    }

    isProcessing = false;
  }

  /// 🔥 FATIGUE + ALERT LOGIC (FIXED)
  void checkEyeClosure() {
    final DateTime now = DateTime.now();

    if (eyesClosed) {
      if (eyesClosedStart == null) {
        eyesClosedStart = DateTime.now();
      }

      final duration = DateTime.now().difference(eyesClosedStart!);

      if (!_eyesWereClosed) {
        _eyesWereClosed = true;
        _eyesClosedTime = now;
      }

      setState(() {
        if (duration.inSeconds >= 5) {
          fatigueStatus = "Sleepy 😴";
        } else {
          fatigueStatus = "Drowsy 😐";
        }
      });

      if (fatigueStatus != _lastPersistedStatus) {
        _lastPersistedStatus = fatigueStatus;
        unawaited(_persistLiveMonitoringUpdate(fatigueStatus));
      }

      if (duration.inSeconds >= 5 && !alertShown) {
        alertShown = true;

        print("ALERT TRIGGERED");

        // ✅ FIXED SAFE UI CALL
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await showAlert();
          speakAlert();
        });
      }

    } else {
      setState(() {
        fatigueStatus = "Normal 😊";
      });

      if (_eyesWereClosed && _eyesClosedTime != null) {
        final eyeClosureDuration = now.difference(_eyesClosedTime!);
        if (eyeClosureDuration.inMilliseconds >= 300 && eyeClosureDuration.inMilliseconds <= 1500) {
          _yawnCount++;
          print("YAWN DETECTED: $_yawnCount");
          
          if (_yawnCount >= 5 && !_yawnAlertShown) {
            _yawnAlertShown = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _showYawnWarning();
            });
          }
          
          unawaited(_persistLiveMonitoringUpdate('yawned'));
        }
        _eyesWereClosed = false;
        _eyesClosedTime = null;
      }

      if (fatigueStatus != _lastPersistedStatus) {
        _lastPersistedStatus = fatigueStatus;
        unawaited(_persistLiveMonitoringUpdate(fatigueStatus));
      }

      eyesClosedStart = null;
      alertShown = false;
    }
  }

  Future<void> _showYawnWarning() async {
    if (!mounted) return;

    if (await Vibration.hasVibrator()) {
      await Vibration.vibrate(duration: 500, amplitude: 200);
    } else {
      await HapticFeedback.mediumImpact();
    }

    await _alertPlayer.stop();
    await _alertPlayer.setReleaseMode(ReleaseMode.loop);
    await _alertPlayer.play(AssetSource('sounds/warning.mp3'));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text(
          'Excessive Yawning Detected',
          style: TextStyle(color: _accentRed),
        ),
        content: const Text(
          'You have yawned more than 5 times. Please take a break or find a safe place to rest.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _alertPlayer.stop();
              await _alertPlayer.setReleaseMode(ReleaseMode.release);
              Navigator.of(context).pop();
              _yawnAlertShown = false;
            },
            child: const Text('OK', style: TextStyle(color: _accentGreen)),
          ),
        ],
      ),
    );
  }

  /// 🔊 VOICE ALERT
  Future<void> speakAlert() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak(
        "Driver wake up. You appear tired. Please stay alert.");
  }

  /// 🚨 ALERT UI (SAFE)
  Future<void> showAlert() async {
    if (!mounted) return;

    // Play warning sound on loop
    await _alertPlayer.stop();
    await _alertPlayer.setReleaseMode(ReleaseMode.loop);
    await _alertPlayer.play(AssetSource('sounds/warning.mp3'));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text("Wake Up!",
            style: TextStyle(color: Colors.red)),
        content: const Text(
          "You look drowsy. Please stay alert!",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _alertPlayer.stop();
              await _alertPlayer.setReleaseMode(ReleaseMode.release);
              Navigator.of(context).pop();
              alertShown = false;
            },
            child: const Text("OK",
                style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (!_sessionSaved) {
      unawaited(_saveLiveMonitoringSessionSummary());
    }
    _alertPlayer.dispose();
    timer?.cancel();
    _controller?.dispose();
    _faceDetector.close();
    flutterTts.stop();
    super.dispose();
  }

  Future<void> _createLiveMonitoringSession() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null || _sessionId == null) {
      developer.log(
        'Live monitoring session not created: user/session missing.',
        name: 'LiveMonitoringScreen',
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
            'source': 'camera_live_monitoring',
            'startedAt': _sessionStartedAt != null
                ? Timestamp.fromDate(_sessionStartedAt!)
                : FieldValue.serverTimestamp(),
            'status': 'active',
            'lastStatus': fatigueStatus,
            'updateCount': 0,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (error, stackTrace) {
      developer.log(
        'Failed to create live monitoring fatigue session.',
        name: 'LiveMonitoringScreen',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _persistLiveMonitoringUpdate(String status) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null || _sessionId == null) {
      return;
    }

    try {
      final String updateId = DateTime.now().microsecondsSinceEpoch.toString();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('fatigue_sessions')
          .doc(_sessionId)
          .collection('updates')
          .doc(updateId)
          .set(<String, Object?>{
            'uid': user.uid,
            'sessionId': _sessionId,
            'source': 'camera_live_monitoring',
            'status': status,
            'timestamp': Timestamp.fromDate(DateTime.now()),
            'createdAt': FieldValue.serverTimestamp(),
          });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('fatigue_sessions')
          .doc(_sessionId)
          .set(<String, Object?>{
            'lastStatus': status,
            'updateCount': FieldValue.increment(1),
          }, SetOptions(merge: true));
    } catch (error, stackTrace) {
      developer.log(
        'Failed to persist live monitoring fatigue update.',
        name: 'LiveMonitoringScreen',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _saveLiveMonitoringSessionSummary() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null || _sessionId == null) {
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
            'source': 'camera_live_monitoring',
            'status': 'completed',
            'lastStatus': fatigueStatus,
            'endedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      _sessionSaved = true;
    } catch (error, stackTrace) {
      developer.log(
        'Failed to save live monitoring fatigue session summary.',
        name: 'LiveMonitoringScreen',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Live Monitoring',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () async {
                      await _saveLiveMonitoringSessionSummary();
                      if (!mounted) {
                        return;
                      }
                      Navigator.pop(context);
                    },
                  )
                ],
              ),

              const SizedBox(height: 20),

              _statusSection(),

              const SizedBox(height: 20),
              
              _yawnCounterCard(),

              const SizedBox(height: 20),

              Container(
                width: 190,
                height: 280,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.greenAccent, width: 3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _controller == null ||
                        !_controller!.value.isInitialized
                    ? const Center(child: CircularProgressIndicator())
                    : CameraPreview(_controller!),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentRed,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () async {
                        await _saveLiveMonitoringSessionSummary();
                        if (!mounted) {
                          return;
                        }
                        Navigator.pop(context);
                      },
                      child: const Text("Stop Monitoring"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _yawnCounterCard() {
    final Color yawnColor = _yawnCount >= 5 ? _accentRed : _accentOrange;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: yawnColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Yawn Count',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$_yawnCount',
                style: TextStyle(
                  color: yawnColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: yawnColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _yawnCount >= 5 ? '⚠️ High' : _yawnCount > 0 ? '⚡ Active' : '✓ None',
              style: TextStyle(
                color: yawnColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusSection() {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accentGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Eye Status',
                    style: TextStyle(color: _textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    eyesClosed ? "Closed 🔴" : "Open 🟢",
                    style: TextStyle(
                      color: eyesClosed ? Colors.red : Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Container(width: 1, height: 50, color: Colors.grey),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fatigue Status',
                    style: TextStyle(color: _textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    fatigueStatus,
                    style: TextStyle(
                      color: fatigueStatus.contains("Normal")
                          ? Colors.green
                          : fatigueStatus.contains("Drowsy")
                              ? Colors.orange
                              : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
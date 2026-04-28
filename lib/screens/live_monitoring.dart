import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../services/fatigue_detector_service.dart';
import '../widgets/fatigue_gauge.dart';
import '../widgets/status_section.dart';

class LiveMonitoringScreen extends StatefulWidget {
  const LiveMonitoringScreen({super.key});

  @override
  State<LiveMonitoringScreen> createState() => _LiveMonitoringScreenState();
}

class _LiveMonitoringScreenState extends State<LiveMonitoringScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  final FatigueDetectorService _detectorService = FatigueDetectorService();
  final FlutterTts flutterTts = FlutterTts();

  bool isProcessing = false;
  DateTime? lastProcessed;
  int frameSkip = 0;

  // Eye detection
  bool eyesClosed = false;
  int closedEyeFrames = 0;

  // Yawn detection
  bool yawning = false;
  int yawnFrames = 0;

  // Fatigue
  String fatigueStatus = "Normal";

  // Timer logic
  DateTime? eyesClosedStart;
  DateTime? yawnStart;
  bool alertShown = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initCamera();

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      checkEyeClosure();
    });
  }

  Future<void> initCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras == null || cameras!.isEmpty) return;

      // Select Front camera
      final frontCamera = cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras![0],
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _controller!.initialize();
      
      if (!mounted) return;
      
      _controller!.startImageStream(processCameraImage);
      setState(() {});
    } catch (e) {
      debugPrint('Camera Init Error: $e');
    }
  }

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
      final result = await _detectorService.detectFromCameraImage(image);

      if (result.faceFound) {
        final left = result.leftEyeOpenProb;
        final right = result.rightEyeOpenProb;

        if (left < 0.6 && right < 0.6) {
          closedEyeFrames++;
        } else {
          closedEyeFrames = 0;
        }

        eyesClosed = closedEyeFrames > 2;

        if (result.yawning) {
          yawnFrames++;
        } else {
          yawnFrames = 0;
        }

        yawning = yawnFrames > 1;
      } else {
        eyesClosed = false;
        yawning = false;
        closedEyeFrames = 0;
        yawnFrames = 0;
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('ML ERROR: $e');
    }

    isProcessing = false;
  }

  void checkEyeClosure() {
    if (!mounted) return;

    final DateTime now = DateTime.now();

    if (eyesClosed) {
      eyesClosedStart ??= now;
    } else {
      eyesClosedStart = null;
    }

    if (yawning) {
      yawnStart ??= now;
    } else {
      yawnStart = null;
    }

    final Duration eyeDuration = eyesClosedStart == null
        ? Duration.zero
        : now.difference(eyesClosedStart!);
    final Duration yawnDuration = yawnStart == null
        ? Duration.zero
        : now.difference(yawnStart!);

    final bool sleepy =
        eyeDuration.inSeconds >= 5 ||
        (eyesClosed && yawnDuration.inSeconds >= 2) ||
        yawnDuration.inSeconds >= 4;
    final bool drowsy = eyesClosed || yawning;

    setState(() {
      if (sleepy) {
        fatigueStatus = "Sleepy 😴";
      } else if (drowsy) {
        fatigueStatus = "Drowsy 😐";
      } else {
        fatigueStatus = "Normal 😊";
      }
    });

    if (sleepy && !alertShown) {
      alertShown = true;
      showAlert();
      speakAlert();
    }

    if (!sleepy) {
      alertShown = false;
    }
  }

  Future<void> speakAlert() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak("Driver wake up. You appear tired. Please stay alert.");
  }

  void showAlert() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text("Wake Up!", style: TextStyle(color: Colors.red)),
        content: const Text("You look drowsy. Please stay alert!", style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              alertShown = false;
            },
            child: const Text("OK", style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    _controller?.dispose();
    _detectorService.dispose();
    flutterTts.stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Live Monitoring", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              StatusSection(
                eyesClosed: eyesClosed,
                fatigueStatus: fatigueStatus,
              ),
              const SizedBox(height: 40),
              FatigueGauge(
                fatigueStatus: fatigueStatus,
                eyesClosed: eyesClosed,
              ),
              if (_controller != null && _controller!.value.isInitialized)
                const SizedBox(height: 10), // Preview is offstage/hidden as per your requirement
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Stop Monitoring", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
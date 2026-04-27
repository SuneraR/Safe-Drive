import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

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
    if (eyesClosed) {
      if (eyesClosedStart == null) {
        eyesClosedStart = DateTime.now();
      }

      final duration = DateTime.now().difference(eyesClosedStart!);

      setState(() {
        if (duration.inSeconds >= 5) {
          fatigueStatus = "Sleepy 😴";
        } else {
          fatigueStatus = "Drowsy 😐";
        }
      });

      if (duration.inSeconds >= 5 && !alertShown) {
        alertShown = true;

        print("ALERT TRIGGERED");

        // ✅ FIXED SAFE UI CALL
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          showAlert();
          speakAlert();
        });
      }

    } else {
      setState(() {
        fatigueStatus = "Normal 😊";
      });

      eyesClosedStart = null;
      alertShown = false;
    }
  }

  /// 🔊 VOICE ALERT
  Future<void> speakAlert() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak(
        "Driver wake up. You appear tired. Please stay alert.");
  }

  /// 🚨 ALERT UI (SAFE)
  void showAlert() {
    if (!mounted) return;

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
            onPressed: () {
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
    timer?.cancel();
    _controller?.dispose();
    _faceDetector.close();
    flutterTts.stop();
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
                  const Text("Live Monitoring",
                      style: TextStyle(color: Colors.white)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),

              const SizedBox(height: 20),

              _statusSection(),

              const SizedBox(height: 40),

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

              const Spacer(),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () => Navigator.pop(context),
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

  Widget _statusSection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent),
      ),
      child: Row(
        children: [

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Eye Status",
                      style: TextStyle(color: Colors.grey)),
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
                  const Text("Fatigue Status",
                      style: TextStyle(color: Colors.grey)),
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
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class LiveMonitoringScreen extends StatefulWidget {
  const LiveMonitoringScreen({super.key});

  static const Color _bgColor = Color(0xFF121212);
  static const Color _surfaceColor = Color(0xFF1C1C1E);
  static const Color _textSecondary = Color(0xFFA0A0A0);
  static const Color _accentGreen = Color(0xFF65F58B);
  static const Color _accentYellow = Color(0xFFFFD60A);
  static const Color _accentRed = Color(0xFFFF453A);

  @override
  State<LiveMonitoringScreen> createState() => _LiveMonitoringScreenState();
}

class _LiveMonitoringScreenState extends State<LiveMonitoringScreen> {
  CameraController? _controller;
  List<CameraDescription>? cameras;

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  Future<void> initCamera() async {
    cameras = await availableCameras();

    _controller = CameraController(
      cameras![1], // front camera (change to 0 if error)
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller!.initialize();

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // 🔴 TOP BAR
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Live Monitoring",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                "Real-time fatigue tracking",
                style: TextStyle(color: _textSecondary, fontSize: 16),
              ),

              const SizedBox(height: 20),

              // ✅ STATUS SECTION
              _statusSection(),

              const SizedBox(height: 28),

              // 🎥 CAMERA FACE BOX
              Container(
                width: 200,
                height: 280,
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _controller == null || !_controller!.value.isInitialized
                    ? const Center(child: CircularProgressIndicator())
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CameraPreview(_controller!),
                      ),
              ),

              const Spacer(),

              // 🔴 BOTTOM BUTTONS
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentRed,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Stop Monitoring"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FloatingActionButton(
                    backgroundColor: _accentYellow,
                    foregroundColor: _bgColor,
                    elevation: 0,
                    onPressed: () {},
                    child: const Icon(Icons.call),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ STATUS BOX (JOINED)
  Widget _statusSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [

          // LEFT
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    children: [
                      Icon(Icons.remove_red_eye, size: 16, color: Colors.green),
                      SizedBox(width: 6),
                      Text("Eye Status",
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  SizedBox(height: 5),
                  Text("Eyes Open",
                      style: TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),

          // DIVIDER
          Container(width: 1, height: 50, color: Colors.grey),

          // RIGHT
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    children: [
                      Icon(Icons.circle, size: 10, color: _accentGreen),
                      SizedBox(width: 6),
                      Text("Fatigue Score",
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  SizedBox(height: 5),
                  Text("10%",
                      style: TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

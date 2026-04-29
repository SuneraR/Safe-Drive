import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

class SafeDriveLoading extends StatefulWidget {
  const SafeDriveLoading({
    super.key,
    this.nextScreen,
    this.displayDuration = const Duration(seconds: 2),
  });

  final Widget? nextScreen;
  final Duration displayDuration;

  @override
  State<SafeDriveLoading> createState() => _SafeDriveLoadingState();
}

class _SafeDriveLoadingState extends State<SafeDriveLoading>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late Animation<Alignment> _anim1;
  late Animation<Alignment> _anim2;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    // Controller for the first green circle
    _controller1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _anim1 =
        Tween<Alignment>(
          begin: const Alignment(-0.8, -0.5),
          end: const Alignment(0.8, 0.5),
        ).animate(
          CurvedAnimation(parent: _controller1, curve: Curves.easeInOutSine),
        );

    // Controller for the second green circle
    _controller2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _anim2 =
        Tween<Alignment>(
          begin: const Alignment(0.8, -0.8),
          end: const Alignment(-0.8, 0.8),
        ).animate(
          CurvedAnimation(parent: _controller2, curve: Curves.easeInOutSine),
        );

    if (widget.nextScreen != null) {
      _navigationTimer = Timer(widget.displayDuration, () {
        if (!mounted) {
          return;
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => widget.nextScreen!),
        );
      });
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Deep dark background
      body: Stack(
        children: [
          // 1. Animated Background Layer (The moving green circles)
          AnimatedBuilder(
            animation: _controller1,
            builder: (context, child) {
              return Align(
                alignment: _anim1.value,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.greenAccent.withOpacity(0.6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.greenAccent.withOpacity(0.4),
                        blurRadius: 50,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _controller2,
            builder: (context, child) {
              return Align(
                alignment: _anim2.value,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.lightGreen.withOpacity(0.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.lightGreen.withOpacity(0.4),
                        blurRadius: 60,
                        spreadRadius: 30,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // 2. The Glass Layer (Blurs everything behind it)
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
              child: Container(
                color: Colors.black.withOpacity(0.4), // Dark tint for the glass
              ),
            ),
          ),

          // 3. The Foreground UI Layer (Logo, Text, Loading indicator)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Custom Icon Approximation
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 10.0, right: 10.0),
                      child: Icon(
                        Icons.directions_car_outlined,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF121212), // Matches background
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.visibility_outlined,
                        color: Colors.greenAccent,
                        size: 30,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // App Name
                const Text(
                  'SafeDrive',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 60),

                // Loading Ring
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.grey,
                    ),
                    backgroundColor: Colors.grey.withOpacity(0.2),
                  ),
                ),
                const SizedBox(height: 20),

                // Loading Text
                Text(
                  'Loading...',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

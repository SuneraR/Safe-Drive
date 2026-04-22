import 'package:flutter/material.dart';
import '../widgets/dashboard/driver_status_card.dart';
import '../widgets/dashboard/start_button.dart';
import '../widgets/dashboard/stats_section.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  static const Color _bgColor = Color(0xFF121212);
  static const Color _textSecondary = Color(0xFFA0A0A0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Dashboard",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Good evening, driver",
                style: TextStyle(color: _textSecondary, fontSize: 16),
              ),
              SizedBox(height: 32),
              DriverStatusCard(),
              SizedBox(height: 20),
              StartButton(),
              SizedBox(height: 24),
              StatsSection(),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/history.dart';
import 'screens/settings.dart';
import 'screens/dashboard.dart';
import 'screens/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // 🔥 IMPORTANT
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safe Drive',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),

      // ✅ Routes for navigation
      routes: {
        '/login': (context) => const Login(),
        '/home': (context) => const RootNavigationScreen(),
      },

      // 👉 Start from Login
      home: const Login(),
    );
  }
}

/// ================= ROOT NAVIGATION =================

class RootNavigationScreen extends StatefulWidget {
  const RootNavigationScreen({super.key});

  @override
  State<RootNavigationScreen> createState() => _RootNavigationScreenState();
}

class _RootNavigationScreenState extends State<RootNavigationScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    const Dashboard(),
    const HistoryScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        child: Container(
          height: 76,
          decoration: BoxDecoration(
            color: const Color(0xFF111318),
            borderRadius: BorderRadius.circular(38),
            border: Border.all(color: Colors.black.withOpacity(0.35)),
          ),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                label: 'Home',
                selected: _currentIndex == 0,
                onTap: () => setState(() => _currentIndex = 0),
              ),
              _NavItem(
                icon: Icons.access_time,
                label: 'History',
                selected: _currentIndex == 1,
                onTap: () => setState(() => _currentIndex = 1),
              ),
              _NavItem(
                icon: Icons.settings_outlined,
                label: 'Settings',
                selected: _currentIndex == 2,
                onTap: () => setState(() => _currentIndex = 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ================= NAV ITEM =================

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color active = const Color(0xFF65F58B);
    final Color inactive = const Color(0xFF9CA3AF);

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: selected ? active : inactive),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: selected ? active : inactive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
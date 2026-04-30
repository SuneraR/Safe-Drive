import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:safe_drive/firebase_options.dart';
import 'services/app_notification_service.dart';
import 'services/ride_background_service.dart';
import 'screens/history.dart';
import 'screens/app_settings_provider.dart';
import 'screens/loading.dart';
import 'screens/settings.dart';
import 'screens/dashboard.dart';
import 'screens/login.dart';
import 'package:safe_drive/Providers/theme_provider.dart';

Future<void> _bootstrapApp() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await AppNotificationService.instance.initialize();
    await RideBackgroundService.instance.initialize();
    await AppSettingsNotifier.instance.initialize();
  } catch (_) {
    // App still runs if Firebase isn't configured in this build flavor.
  }
}

final Future<void> _bootstrapFuture = _bootstrapApp();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: AppSettingsNotifier.instance),
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
      ],
      child: Consumer<ThemeNotifier>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Safe Drive',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              scaffoldBackgroundColor: Colors.white,
              primaryColor: Colors.green,
              cardColor: const Color(0xFFF5F5F5),
              colorScheme: const ColorScheme.light(
                primary: Colors.green,
                secondary: Colors.greenAccent,
                onPrimary: Colors.white,
              ),
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Colors.black),
                bodyMedium: TextStyle(color: Colors.black87),
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF121212),
              primaryColor: const Color(0xFF65F58B),
              cardColor: const Color(0xFF1C1C1E),
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF65F58B),
                secondary: Colors.greenAccent,
                onPrimary: Colors.black,
              ),
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Colors.white),
                bodyMedium: TextStyle(color: Colors.white70),
              ),
            ),
            themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,

            // ✅ Routes for navigation
            routes: {
              '/login': (context) => const Login(),
              '/home': (context) => const RootNavigationScreen(),
            },

            // 👉 Start with the loading screen while Firebase/services boot.
            home: FutureBuilder<void>(
              future: _bootstrapFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SafeDriveLoading();
                }

                final user = FirebaseAuth.instance.currentUser;
                return user == null
                    ? const Login()
                    : const RootNavigationScreen();
              },
            ),
          );
        },
      ),
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
      body: IndexedStack(index: _currentIndex, children: _pages),

      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        child: Container(
          height: 76,
          decoration: BoxDecoration(
            color: const Color(0xFF111318),
            borderRadius: BorderRadius.circular(38),
            border: Border.all(color: Colors.black.withValues(alpha: 0.35)),
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

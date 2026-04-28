import 'package:flutter/material.dart';
import '../widgets/setting/sensitivity_selector.dart';
import '../widgets/setting/settings_action_button.dart';
import '../widgets/setting/settings_card.dart';
import '../widgets/setting/settings_info_row.dart';
import '../widgets/setting/settings_section_header.dart';
import '../widgets/setting/settings_switch_tile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _alertSound = true;
  bool _notifications = true;
  String _sensitivity = 'Medium';

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeNotifier>(context);
    final theme = Theme.of(context);
    final Color accentGreen = theme.colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Settings', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
              const SizedBox(height: 32),

              SettingsSectionHeader(icon: Icons.notifications_none, title: 'Alert Settings', accentColor: accentGreen),
              SettingsCard(
                child: Column(
                  children: [
                    SettingsSwitchTile(
                      icon: Icons.volume_up_outlined,
                      title: 'Alert Sound',
                      subtitle: 'Play sound when fatigue detected',
                      value: _alertSound,
                      accentColor: accentGreen,
                      onChanged: (val) => setState(() => _alertSound = val),
                    ),
                    SettingsSwitchTile(
                      icon: Icons.notifications_active_outlined,
                      title: 'Notifications',
                      subtitle: 'Receive trip summaries',
                      value: _notifications,
                      accentColor: accentGreen,
                      onChanged: (val) => setState(() => _notifications = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              SettingsSectionHeader(icon: Icons.shield_outlined, title: 'Sensitivity', accentColor: accentGreen),
              SettingsCard(
                child: SensitivitySelector(
                  options: const ['Low', 'Medium', 'High'],
                  selectedValue: _sensitivity,
                  accentColor: accentGreen,
                  onChanged: (val) => setState(() => _sensitivity = val),
                ),
              ),

              const SizedBox(height: 24),
              SettingsSectionHeader(icon: Icons.dark_mode_outlined, title: 'Appearance', accentColor: accentGreen),
              SettingsCard(
                child: SettingsSwitchTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark Mode',
                  subtitle: 'Reduce eye strain at night',
                  value: themeProvider.isDark,
                  accentColor: accentGreen,
                  onChanged: (val) => themeProvider.toggleTheme(val),
                ),
              ),

              const SizedBox(height: 24),
              SettingsSectionHeader(icon: Icons.info_outline, title: 'About', accentColor: Colors.grey),
              const SettingsCard(
                child: Column(
                  children: [
                    SettingsInfoRow(label: 'Version', value: '1.0.0'),
                    SettingsInfoRow(label: 'Developer', value: 'SafeDrive Team'),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              const SettingsActionButton(text: 'Privacy Policy'),
              const SizedBox(height: 12),
              SettingsActionButton(
                text: 'Sign Out',
                textColor: Colors.redAccent,
                onPressed: () => FirebaseAuth.instance.signOut(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'app_settings_provider.dart';
import 'package:safe_drive/Providers/theme_provider.dart';
import '../widgets/setting/sensitivity_selector.dart';
import '../widgets/setting/settings_action_button.dart';
import '../widgets/setting/settings_card.dart';
import '../widgets/setting/settings_info_row.dart';
import '../widgets/setting/settings_section_header.dart';
import '../widgets/setting/settings_switch_tile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _showPrivacyPolicy() async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Privacy Policy'),
          content: const SingleChildScrollView(
            child: Text(
              'SafeDrive uses sensor data, notifications, and local trip history to detect fatigue and improve driving safety. '
              'Your ride data may be stored locally and, when signed in, synced to Firebase for your account. '
              'You can disable notifications and alert sound from Settings at any time.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeNotifier, AppSettingsNotifier>(
      builder: (context, themeProvider, appSettings, _) {
        final theme = Theme.of(context);
        final Color accentGreen = theme.colorScheme.primary;

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 24.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SettingsSectionHeader(
                    icon: Icons.notifications_none,
                    title: 'Alert Settings',
                    accentColor: accentGreen,
                  ),
                  SettingsCard(
                    child: Column(
                      children: [
                        SettingsSwitchTile(
                          icon: Icons.volume_up_outlined,
                          title: 'Alert Sound',
                          subtitle: 'Play sound when fatigue detected',
                          value: appSettings.alertSoundEnabled,
                          accentColor: accentGreen,
                          onChanged: (val) {
                            appSettings.setAlertSoundEnabled(val);
                          },
                        ),
                        SettingsSwitchTile(
                          icon: Icons.notifications_active_outlined,
                          title: 'Notifications',
                          subtitle: 'Receive trip summaries',
                          value: appSettings.notificationsEnabled,
                          accentColor: accentGreen,
                          onChanged: (val) {
                            appSettings.setNotificationsEnabled(val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SettingsSectionHeader(
                    icon: Icons.shield_outlined,
                    title: 'Sensitivity',
                    accentColor: accentGreen,
                  ),
                  SettingsCard(
                    child: SensitivitySelector(
                      options: const ['Low', 'Medium', 'High'],
                      selectedValue: appSettings.sensitivityLabel,
                      accentColor: accentGreen,
                      onChanged: (val) {
                        appSettings.setSensitivity(val);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  SettingsSectionHeader(
                    icon: Icons.dark_mode_outlined,
                    title: 'Appearance',
                    accentColor: accentGreen,
                  ),
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
                  SettingsSectionHeader(
                    icon: Icons.info_outline,
                    title: 'About',
                    accentColor: Colors.grey,
                  ),
                  const SettingsCard(
                    child: Column(
                      children: [
                        SettingsInfoRow(label: 'Version', value: '1.0.0'),
                        SettingsInfoRow(
                          label: 'Developer',
                          value: 'SafeDrive Team',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SettingsActionButton(
                    text: 'Privacy Policy',
                    onPressed: _showPrivacyPolicy,
                  ),
                  const SizedBox(height: 12),
                  SettingsActionButton(
                    text: 'Sign Out',
                    textColor: Colors.redAccent,
                    onPressed: _signOut,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

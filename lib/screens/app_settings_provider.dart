import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppSensitivity { low, medium, high }

class AppSettingsNotifier extends ChangeNotifier {
  AppSettingsNotifier._();

  static final AppSettingsNotifier instance = AppSettingsNotifier._();

  static const String _alertSoundKey = 'alertSoundEnabled';
  static const String _notificationsKey = 'notificationsEnabled';
  static const String _sensitivityKey = 'fatigueSensitivity';

  bool _initialized = false;
  bool _alertSoundEnabled = true;
  bool _notificationsEnabled = true;
  AppSensitivity _sensitivity = AppSensitivity.medium;

  bool get alertSoundEnabled => _alertSoundEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  AppSensitivity get sensitivity => _sensitivity;

  String get sensitivityLabel {
    switch (_sensitivity) {
      case AppSensitivity.low:
        return 'Low';
      case AppSensitivity.medium:
        return 'Medium';
      case AppSensitivity.high:
        return 'High';
    }
  }

  double get warningThreshold {
    switch (_sensitivity) {
      case AppSensitivity.low:
        return 0.64;
      case AppSensitivity.medium:
        return 0.58;
      case AppSensitivity.high:
        return 0.52;
    }
  }

  double get criticalThreshold {
    switch (_sensitivity) {
      case AppSensitivity.low:
        return 0.84;
      case AppSensitivity.medium:
        return 0.78;
      case AppSensitivity.high:
        return 0.70;
    }
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _alertSoundEnabled = prefs.getBool(_alertSoundKey) ?? true;
    _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
    _sensitivity = _parseSensitivity(
      prefs.getString(_sensitivityKey) ?? 'Medium',
    );
    _initialized = true;
    notifyListeners();
  }

  Future<void> setAlertSoundEnabled(bool value) async {
    await initialize();
    if (_alertSoundEnabled == value) {
      return;
    }

    _alertSoundEnabled = value;
    notifyListeners();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_alertSoundKey, value);
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await initialize();
    if (_notificationsEnabled == value) {
      return;
    }

    _notificationsEnabled = value;
    notifyListeners();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, value);
  }

  Future<void> setSensitivity(String value) async {
    await initialize();
    final AppSensitivity parsed = _parseSensitivity(value);
    if (_sensitivity == parsed) {
      return;
    }

    _sensitivity = parsed;
    notifyListeners();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sensitivityKey, sensitivityLabel);
  }

  AppSensitivity _parseSensitivity(String value) {
    switch (value.toLowerCase()) {
      case 'low':
        return AppSensitivity.low;
      case 'high':
        return AppSensitivity.high;
      default:
        return AppSensitivity.medium;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  bool _isDark = true;
  String _selectedVehicle = "Not Selected"; // New variable

  bool get isDark => _isDark;
  String get selectedVehicle => _selectedVehicle; // Getter

  ThemeNotifier() {
    _loadFromPrefs();
  }

  // Toggle Theme
  void toggleTheme(bool value) async {
    _isDark = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
  }

  // Update Vehicle
  void updateVehicle(String vehicleName) async {
    _selectedVehicle = vehicleName;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedVehicle', vehicleName);
  }

  // Load everything from storage
  void _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool('darkMode') ?? true;
    _selectedVehicle = prefs.getString('selectedVehicle') ?? "Not Selected";
    notifyListeners();
  }
}
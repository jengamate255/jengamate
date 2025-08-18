import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService with ChangeNotifier {
  static const String _themePreferenceKey = 'theme_preference';
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themePreferenceKey) ?? 0;
    _themeMode = ThemeMode.values[themeIndex];
    notifyListeners();
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themePreferenceKey, _themeMode.index);
  }

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _saveTheme();
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _saveTheme();
    notifyListeners();
  }

  void setLightTheme() {
    _themeMode = ThemeMode.light;
    _saveTheme();
    notifyListeners();
  }

  void setDarkTheme() {
    _themeMode = ThemeMode.dark;
    _saveTheme();
    notifyListeners();
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': _themeMode.toString(),
    };
  }

  void fromJson(Map<String, dynamic> json) {
    if (json['themeMode'] != null) {
      _themeMode = json['themeMode'] == 'ThemeMode.dark'
          ? ThemeMode.dark
          : ThemeMode.light;
      notifyListeners();
    }
  }
}
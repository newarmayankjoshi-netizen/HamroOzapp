import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  ThemeController._private();
  static final ThemeController instance = ThemeController._private();

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString('themeMode') ?? 'system';
    themeMode.value = _fromString(s);
  }

  ThemeMode _fromString(String s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
    }
    // Fallback to system if an unexpected string is encountered.
    return ThemeMode.system;
  }

  String _toString(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  Future<void> setThemeMode(ThemeMode m) async {
    themeMode.value = m;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', _toString(m));
  }

  // convenience to set from string
  Future<void> setThemeModeFromString(String s) async {
    await setThemeMode(_fromString(s));
  }
}

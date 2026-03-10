import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController {
  LocaleController._private();
  static final LocaleController instance = LocaleController._private();

  final ValueNotifier<Locale?> locale = ValueNotifier<Locale?>(null);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString('language') ?? 'english';
    locale.value = _fromString(s);
  }

  Locale _fromString(String s) {
    switch (s) {
      case 'nepali':
      case 'nepalI':
        return const Locale('ne');
      case 'english':
      default:
        return const Locale('en');
    }
  }

  String _toString(Locale? l) {
    if (l == null) return 'english';
    if (l.languageCode == 'ne') return 'nepali';
    return 'english';
  }

  Future<void> setLocale(Locale? l) async {
    locale.value = l;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', _toString(l));
  }
}

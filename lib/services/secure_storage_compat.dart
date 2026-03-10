import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A best-effort secure storage wrapper.
///
/// On macOS debug/ad-hoc signed builds, Keychain operations can fail with
/// `errSecMissingEntitlement` (surfacing as PlatformException code `-34018`).
///
/// To keep the app functional in that environment, this wrapper falls back to
/// `SharedPreferences` only for macOS when that specific error occurs.
class SecureStorageCompat {
  SecureStorageCompat({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;

  bool _isMissingEntitlement(PlatformException e) {
    final message = e.message ?? '';
    return e.code == '-34018' || message.contains('entitlement');
  }

  Future<String?> read(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } on PlatformException catch (e) {
      if (Platform.isMacOS && _isMissingEntitlement(e)) {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(key);
      }
      rethrow;
    }
  }

  Future<void> write(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } on PlatformException catch (e) {
      if (Platform.isMacOS && _isMissingEntitlement(e)) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(key, value);
        return;
      }
      rethrow;
    }
  }

  Future<void> delete(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } on PlatformException catch (e) {
      if (Platform.isMacOS && _isMissingEntitlement(e)) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(key);
        return;
      }
      rethrow;
    }
  }

  Future<void> deleteAll() async {
    try {
      await _secureStorage.deleteAll();
    } on PlatformException catch (e) {
      if (Platform.isMacOS && _isMissingEntitlement(e)) {
        // SharedPreferences has no scoped deleteAll. Avoid nuking all prefs.
        return;
      }
      rethrow;
    }
  }
}

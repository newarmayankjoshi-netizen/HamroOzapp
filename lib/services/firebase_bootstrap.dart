// ignore_for_file: deprecated_member_use
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb, kDebugMode, debugPrint;
import 'package:firebase_app_check/firebase_app_check.dart';

import '../firebase_options.dart';

class FirebaseBootstrap {
  static bool _attempted = false;
  static bool _ready = false;
  static bool _inProgress = false;
  static Object? _lastError;

  static bool _authAttempted = false;
  static bool _authReady = false;
  static Object? _lastAuthError;

  static bool get isReady => _ready;
  static bool get inProgress => _inProgress;
  static bool get attempted => _attempted;
  static Object? get lastError => _lastError;

  static bool get isAuthReady => _authReady;
  static bool get authAttempted => _authAttempted;
  static Object? get lastAuthError => _lastAuthError;

  static Future<void> tryInit({bool force = false}) async {
    if (_inProgress) return;
    if (_attempted && !force) return;
    if (force) {
      _attempted = false;
      _ready = false;
      _lastError = null;
    }

    _attempted = true;
    _inProgress = true;

    try {
      // Prefer native config (google-services.json / GoogleService-Info.plist) when present.
      // This avoids hard-crashing Apple targets when placeholder FlutterFire options are used.
      await Firebase.initializeApp();
      // Activate App Check in debug/dev to prevent placeholder-token uploads being rejected.
      // Use the debug provider during development so uploads get valid App Check tokens.
      try {
        if (!kIsWeb) {
          await FirebaseAppCheck.instance.activate(
            androidProvider: AndroidProvider.debug,
            appleProvider: AppleProvider.debug,
          );
          try {
            // Diagnostic: fetch the App Check token and log length/prefix so we can
            // verify the full JWT is being produced on the client.
            final tokenResult = await FirebaseAppCheck.instance.getToken(true);
            String? token;
            try {
              token = (tokenResult as dynamic)?.token as String?;
            } catch (_) {
              if (tokenResult is String) token = tokenResult;
            }
            if (token != null) {
              debugPrint('AppCheck token length: ${token.length}');
              debugPrint('AppCheck token prefix: ${token.substring(0, token.length < 40 ? token.length : 40)}');
              if (kDebugMode) {
                // Debug-only: print the full token so you can register it in
                // Firebase Console → App Check → Add debug token. Only enabled
                // in debug builds to avoid exposing the token in production.
                try {
                  debugPrint('FULL APP CHECK TOKEN (debug only): $token');
                } catch (_) {}
              }
            } else {
              debugPrint('AppCheck.getToken returned null token');
            }
          } catch (err) {
            try {
              debugPrint('Failed to read AppCheck token: $err');
            } catch (_) {}
          }
          // Log for diagnostics so startup logs show App Check status.
          // Use debugPrint to avoid heavy logging in production.
          try {
            debugPrint('Firebase App Check: activated debug provider');
          } catch (_) {}
        }
      } catch (err) {
        try {
          debugPrint('Firebase App Check activation failed: $err');
        } catch (_) {}
      }
      _ready = true;
      _lastError = null;
    } catch (e) {
      _lastError = e;
      try {
        // Fallback to FlutterFire options (once configured via `flutterfire configure`).
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        try {
          if (!kIsWeb) {
            await FirebaseAppCheck.instance.activate(
              androidProvider: AndroidProvider.debug,
              appleProvider: AppleProvider.debug,
            );
            try {
              debugPrint('Firebase App Check: activated debug provider (fallback init)');
            } catch (_) {}
          }
        } catch (err) {
          try {
            debugPrint('Firebase App Check activation failed during fallback init: $err');
          } catch (_) {}
        }
        _ready = true;
        _lastError = null;
      } catch (e) {
        _ready = false;
        _lastError = e;
      }
    } finally {
      _inProgress = false;
    }
  }

  /// Ensures there is a Firebase Auth user available.
  ///
  /// Uses anonymous sign-in as a minimal default so Firestore/Storage rules
  /// that require `request.auth != null` can work without additional setup.
  static Future<void> ensureSignedIn() async {
    if (!_ready) return;
    if (_authAttempted && _authReady) return;

    _authAttempted = true;
    try {
      final auth = FirebaseAuth.instance;
      // Do not use anonymous sign-in. If there is no signed-in user, leave
      // the app signed out so developers can control auth flows explicitly.
      if (auth.currentUser == null) {
        _authReady = false;
      } else {
        // If the existing user is anonymous, remove it to avoid persistent
        // anonymous accounts from being stored on-device.
        if (auth.currentUser!.isAnonymous) {
          try {
            await auth.currentUser!.delete();
          } catch (delErr) {
            try {
              debugPrint('Failed to delete anonymous user: $delErr');
            } catch (_) {}
          }
          try {
            await auth.signOut();
          } catch (_) {}
          _authReady = false;
        } else {
          _authReady = true;
        }
      }
      _lastAuthError = null;
    } catch (e) {
      _authReady = false;
      _lastAuthError = e;
    }
  }

  static String prettyAuthError() {
    final e = _lastAuthError;
    if (e == null) return '';
    return e.toString();
  }

  static String authSetupHint() {
    final raw = prettyAuthError();
    final e = raw.toLowerCase();
    final hints = <String>[];

    if (e.contains('operation-not-allowed') || e.contains('anonymous') && e.contains('disabled')) {
      hints.add('Enable Anonymous sign-in in Firebase Console → Authentication → Sign-in method.');
    }

    // Apple keychain/sandbox entitlement issues often show up as keychain/errSec errors.
    final looksLikeKeychain = e.contains('keychain') || e.contains('errsec') || e.contains('-34018') || e.contains('missingentitlement');
    if (looksLikeKeychain) {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        hints.addAll([
          'iOS quick checklist:',
          '- Enable Keychain Sharing',
          '- Add the same access group to all targets',
          '- Clean build → reinstall app',
        ]);
      }
      if (defaultTargetPlatform == TargetPlatform.macOS) {
        hints.addAll([
          'macOS quick checklist:',
          '- Enable App Sandbox',
          '- Enable Keychain Access',
          '- Ensure correct App Identifier Prefix',
        ]);
      }
    }

    return hints.join('\n');
  }
}

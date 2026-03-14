import 'dart:io';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'services/security_service.dart';
import 'services/firebase_bootstrap.dart';
import 'services/secure_storage_compat.dart';
import 'widgets/app_logo.dart';
import 'terms_of_service_page.dart';
import 'privacy_policy_page.dart';
import 'main.dart';
import 'package:hamro_oz/l10n/app_localizations.dart';

// Simple user object for current user access
class CurrentUser {
  final String? email;
  final String? role;

  CurrentUser({this.email, this.role});
}

class VerificationPendingPage extends StatefulWidget {
  final String email;

  const VerificationPendingPage({super.key, required this.email});

  @override
  State<VerificationPendingPage> createState() =>
      _VerificationPendingPageState();
}

class _VerificationPendingPageState extends State<VerificationPendingPage> {
  bool _isChecking = false;
  bool _isResending = false;

  Future<void> _checkVerified() async {
    setState(() => _isChecking = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        final verified =
            FirebaseAuth.instance.currentUser?.emailVerified ?? false;
        if (verified) {
          // Mark in Firestore that the user's email is verified
          try {
            final uid = FirebaseAuth.instance.currentUser?.uid;
            if (uid != null) {
              await FirebaseFirestore.instance.collection('users').doc(uid).set(
                {'emailVerified': true},
                SetOptions(merge: true),
              );
            }
          } catch (e) {
            debugPrint('Failed to mark emailVerified in Firestore: $e');
          }

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email verified — you can now sign in'),
            ),
          );
          Navigator.of(context).pop();
          return;
        }
      }
    } catch (e) {
      debugPrint('verification check error: $e');
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _isResending = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verification email resent')),
          );
        }
      }
    } catch (e) {
      debugPrint('resend verification error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to resend verification email')),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify your email')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'A verification email was sent to',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                widget.email,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              Text(
                'Please open the email and click the verification link. After verifying, tap "I have verified".',
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _isChecking ? null : _checkVerified,
                      child: _isChecking
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('I have verified'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isResending ? null : _resend,
                      child: _isResending
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Resend email'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Global user state
class AuthState {
  static String? _currentUserId;
  static String? _currentUserEmail;
  static String? _currentUserName;
  static bool _isLoggedIn = false;
  static String? _sessionToken;
  static const _secureStorage = FlutterSecureStorage();
  static final _secureStorageCompat = SecureStorageCompat(
    secureStorage: _secureStorage,
  );

  static String? get currentUserId => _currentUserId;
  static String? get currentUserEmail => _currentUserEmail;
  static String? get currentUserName => _currentUserName;
  static bool get isLoggedIn => _isLoggedIn;
  static String? get sessionToken => _sessionToken;
  static bool get isAdmin => _currentUserEmail == 'hamroozapp@gmail.com';

  // Add currentUser getter for compatibility
  static CurrentUser? get currentUser {
    if (!_isLoggedIn || _currentUserEmail == null) return null;
    return CurrentUser(
      email: _currentUserEmail,
      role: _currentUserEmail == 'hamroozapp@gmail.com' ? 'Admin' : 'User',
    );
  }

  static Future<void> login(String userId, String email, String name) async {
    _currentUserId = userId;
    _currentUserEmail = email;
    _currentUserName = name;
    _isLoggedIn = true;
    _sessionToken ??= _generateSessionToken();

    // For admin users, also sign in with Firebase Auth anonymously
    if (email == 'hamroozapp@gmail.com') {
      try {
        await FirebaseAuth.instance.signInAnonymously();
      } catch (e) {
        // If anonymous sign-in fails, try to continue without it
        debugPrint('Firebase Auth sign-in failed for admin: $e');
      }
    }
  }

  static Future<void> logout() async {
    _currentUserId = null;
    _currentUserEmail = null;
    _currentUserName = null;
    _isLoggedIn = false;
    _sessionToken = null;
    await _clearStoredSession();
    await AuthService.signOut();

    // Also sign out from Firebase Auth
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      // Ignore Firebase Auth sign out errors
    }
  }

  static Future<void> persistSession() async {
    if (!_isLoggedIn || _currentUserId == null || _currentUserEmail == null) {
      return;
    }
    _sessionToken ??= _generateSessionToken();
    await _secureStorageCompat.write('session_token', _sessionToken!);
    await _secureStorageCompat.write('session_user_id', _currentUserId!);
    await _secureStorageCompat.write('session_email', _currentUserEmail!);
    await _secureStorageCompat.write('session_name', _currentUserName ?? '');
    await _secureStorageCompat.write(
      'session_last_login',
      DateTime.now().toIso8601String(),
    );
  }

  static Future<bool> restoreSession() async {
    try {
      final token = await _secureStorageCompat.read('session_token');
      final userId = await _secureStorageCompat.read('session_user_id');
      final email = await _secureStorageCompat.read('session_email');
      final name = await _secureStorageCompat.read('session_name');
      final lastLoginStr = await _secureStorageCompat.read(
        'session_last_login',
      );

      if (token == null || userId == null || email == null) {
        return false;
      }

      // Check if session is expired (24 hours)
      if (lastLoginStr != null) {
        final lastLogin = DateTime.parse(lastLoginStr);
        final now = DateTime.now();
        if (now.difference(lastLogin) > const Duration(hours: 24)) {
          await _clearStoredSession();
          return false;
        }
      }

      _currentUserId = userId;
      _currentUserEmail = email;
      _currentUserName = name;
      _isLoggedIn = true;
      _sessionToken = token;

      // Fetch user data from Firestore and populate local cache
      try {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        if (snap.exists) {
          final data = snap.data() ?? {};
          final user = User(
            id: userId,
            email: email,
            passwordHash: '', // Not stored/needed for session restore
            name: (data['name'] as String?) ?? name ?? '',
            phone: data['phone'] as String?,
            state: data['state'] as String?,
            location: data['location'] as String?,
            role: (data['role'] as String?) ?? 'User',
            birthday: data['birthday'] != null
                ? (data['birthday'] is Timestamp
                      ? (data['birthday'] as Timestamp).toDate()
                      : DateTime.tryParse(data['birthday'].toString()))
                : null,
            profilePicture: data['profilePicture'] as String?,
            bio: data['bio'] as String?,
            languages: (data['languages'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList(),
            badges:
                (data['badges'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                const [],
            rating: (data['rating'] as num?)?.toDouble(),
            ratingCount: data['ratingCount'] as int?,
            showPhone: (data['showPhone'] as bool?) ?? false,
            showEmail: (data['showEmail'] as bool?) ?? false,
            createdAt: data['createdAt'] != null
                ? (data['createdAt'] is Timestamp
                      ? (data['createdAt'] as Timestamp).toDate()
                      : DateTime.tryParse(data['createdAt'].toString()) ??
                            DateTime.now())
                : DateTime.now(),
          );
          AuthService.upsertUser(user);
          // Update cached name if different from Firestore
          if (user.name.isNotEmpty && user.name != _currentUserName) {
            _currentUserName = user.name;
          }
        }
      } catch (e) {
        // Best-effort: continue even if Firestore fetch fails
        debugPrint('Failed to fetch user data on session restore: $e');
      }

      return true;
    } catch (e) {
      // If there's any error restoring session, clear it
      await _clearStoredSession();
      return false;
    }
  }

  static Future<void> _clearStoredSession() async {
    await _secureStorageCompat.delete('session_token');
    await _secureStorageCompat.delete('session_user_id');
    await _secureStorageCompat.delete('session_email');
    await _secureStorageCompat.delete('session_name');
    await _secureStorageCompat.delete('session_last_login');
  }

  static String _generateSessionToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }
}

// In-memory user database (in real app, use backend)
class User {
  final String id;
  final String email;
  final String passwordHash; // Hashed password, not plain text
  final String name;
  final String? phone;
  final String? state;
  final String? location;
  final String role; // Student, Worker, Landlord, Employer
  final DateTime? birthday;
  final String? profilePicture; // Base64 encoded image or file path
  final String? bio;
  final List<String>? languages;
  final List<String> badges; // verified, trusted
  final double? rating;
  final int? ratingCount;
  final bool showPhone;
  final bool showEmail;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.name,
    this.phone,
    this.state,
    this.location,
    this.role = 'Worker',
    this.birthday,
    this.profilePicture,
    this.bio,
    this.languages,
    this.badges = const [],
    this.rating,
    this.ratingCount,
    this.showPhone = false,
    this.showEmail = false,
    required this.createdAt,
  });
}

class AuthService {
  // Hash password using bcrypt
  static String _hashPassword(String password) {
    return BCrypt.hashpw(password, BCrypt.gensalt());
  }

  // Verify password using bcrypt
  static bool _verifyPassword(String password, String hash) {
    return BCrypt.checkpw(password, hash);
  }

  // Rate limiting for login attempts
  static final Map<String, List<DateTime>> _loginAttempts = {};
  static const int _maxLoginAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 15);

  static final Map<String, User> _users = {
    // Demo account removed
  };

  static Future<String?> registerUser(
    String email,
    String password,
    String name,
    String phone,
    String state,
  ) async {
    // Local duplicate check
    if (_users.containsKey(email)) {
      return 'email-already-registered-local'; // User already exists locally
    }

    // Check for prohibited content
    final securityService = SecurityService();
    if (securityService.containsProhibitedContent(name) ||
        securityService.containsProhibitedContent(phone)) {
      return 'prohibited-content'; // Prohibited content detected
    }

    try {
      // Create the Firebase Auth user
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUid = cred.user?.uid;
      if (firebaseUid == null) {
        return 'unknown-error';
      }

      // Save profile to Firestore under `users/{uid}`
      final profile = {
        'email': email,
        'name': name,
        'phone': phone,
        'state': state,
        'emailVerified': false,
        'role': 'Worker',
        'badges': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUid)
          .set(profile);

      // Update local in-memory map
      _users[email] = User(
        id: firebaseUid,
        email: email,
        passwordHash: _hashPassword(password),
        name: name,
        phone: phone,
        state: state,
        location: null,
        role: 'Worker',
        badges: const [],
        rating: null,
        ratingCount: null,
        showPhone: false,
        showEmail: false,
        createdAt: DateTime.now(),
      );

      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase createUser error: ${e.code} ${e.message}');
      return e
          .code; // return specific error code like 'weak-password' or 'invalid-email'
    } catch (e) {
      debugPrint('Unexpected registerUser error: $e');
      return 'unknown-error';
    }
  }

  static User? loginUser(String email, String password) {
    // Check for rate limiting
    final now = DateTime.now();
    if (_loginAttempts.containsKey(email)) {
      final attempts = _loginAttempts[email]!;
      // Remove old attempts outside lockout window
      attempts.removeWhere((time) => now.difference(time) > _lockoutDuration);

      if (attempts.length >= _maxLoginAttempts) {
        // Account is locked due to too many failed attempts
        return null;
      }
    }

    if (!_users.containsKey(email)) {
      // Record failed attempt
      _loginAttempts.putIfAbsent(email, () => []).add(now);
      return null; // User not found
    }

    final user = _users[email]!;
    // Verify password using bcrypt
    if (!_verifyPassword(password, user.passwordHash)) {
      // Record failed attempt
      _loginAttempts.putIfAbsent(email, () => []).add(now);
      return null; // Wrong password
    }

    // Clear failed attempts on successful login
    _loginAttempts.remove(email);
    return user;
  }

  // Check if account is locked
  static bool isAccountLocked(String email) {
    if (!_loginAttempts.containsKey(email)) return false;

    final now = DateTime.now();
    final attempts = _loginAttempts[email]!;
    attempts.removeWhere((time) => now.difference(time) > _lockoutDuration);

    return attempts.length >= _maxLoginAttempts;
  }

  // Get remaining lockout time
  static Duration? getRemainingLockoutTime(String email) {
    if (!isAccountLocked(email)) return null;

    final attempts = _loginAttempts[email]!;
    final oldestAttempt = attempts.reduce((a, b) => a.isBefore(b) ? a : b);
    final lockoutEnd = oldestAttempt.add(_lockoutDuration);
    final remaining = lockoutEnd.difference(DateTime.now());

    return remaining.isNegative ? null : remaining;
  }

  static User? getUserById(String userId) {
    for (final user in _users.values) {
      if (user.id == userId) {
        return user;
      }
    }
    return null;
  }

  static void upsertUser(User user) {
    _users[user.email] = user;
  }

  static void upsertUsers(Iterable<User> users) {
    for (final user in users) {
      _users[user.email] = user;
    }
  }

  static Future<User?> signInWithGoogle() async {
    try {
      // Ensure Firebase is initialized (important for web)
      await FirebaseBootstrap.tryInit();
      if (!FirebaseBootstrap.isReady) {
        throw Exception(
          'Firebase is not configured for this platform.\n'
          'On web, run `flutterfire configure --platforms=web` or add your Firebase config to `web/index.html`.\n'
          'Alternatively use email/password sign-in for web development.'
        );
      }
      UserCredential userCredential;

      if (kIsWeb) {
        // For web, use Firebase Auth popup
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential = await FirebaseAuth.instance.signInWithPopup(
          googleProvider,
        );
      } else if (Platform.isMacOS) {
        // macOS uses Desktop OAuth with client secret configured in Info.plist
        final GoogleSignIn googleSignIn = GoogleSignIn.instance;

        // Initialize Google Sign-In
        await googleSignIn.initialize();

        // Authenticate the user (this shows the account chooser)
        final GoogleSignInAccount googleUser = await googleSignIn.authenticate();

        // Get authentication tokens (includes idToken)
        final GoogleSignInAuthentication googleAuth = googleUser.authentication;

        // For Firebase, we need both idToken and accessToken
        final List<String> scopes = [
          'https://www.googleapis.com/auth/userinfo.email',
          'https://www.googleapis.com/auth/userinfo.profile',
        ];

        GoogleSignInClientAuthorization? authorization;
        try {
          authorization = await googleUser.authorizationClient.authorizationForScopes(scopes);
        } catch (e) {
          authorization = await googleUser.authorizationClient.authorizeScopes(scopes);
        }

        if (authorization == null) {
          throw Exception('Failed to obtain authorization tokens');
        }

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: authorization.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      } else {
        // For mobile (Android/iOS), use google_sign_in package to present account chooser
        final GoogleSignIn googleSignIn = GoogleSignIn.instance;

        // Initialize Google Sign-In
        await googleSignIn.initialize();

        // Authenticate the user (this shows the account chooser)
        final GoogleSignInAccount googleUser = await googleSignIn
            .authenticate();

        // Get authentication tokens (includes idToken)
        final GoogleSignInAuthentication googleAuth = googleUser.authentication;

        // For Firebase, we need both idToken and accessToken
        // Try to get existing authorization first
        final List<String> scopes = [
          'https://www.googleapis.com/auth/userinfo.email',
          'https://www.googleapis.com/auth/userinfo.profile',
        ];

        GoogleSignInClientAuthorization? authorization;
        try {
          authorization = await googleUser.authorizationClient
              .authorizationForScopes(scopes);
        } catch (e) {
          // If scopes not granted, request them
          authorization = await googleUser.authorizationClient.authorizeScopes(
            scopes,
          );
        }

        if (authorization == null) {
          // This shouldn't happen, but handle it just in case
          throw Exception('Failed to obtain authorization tokens');
        }

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: authorization.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );
      }

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) return null;

      final firebaseUserId = firebaseUser.uid;
      final email = firebaseUser.email!;

      // Check if user already exists in local database
      if (_users.containsKey(email)) {
        // Update the existing user with Firebase UID if different
        final existingUser = _users[email]!;
        final userName = firebaseUser.displayName ?? existingUser.name;
        if (existingUser.id != firebaseUserId) {
          _users[email] = User(
            id: firebaseUserId, // Use Firebase UID
            email: email,
            passwordHash: existingUser.passwordHash,
            name: userName,
            phone: firebaseUser.phoneNumber ?? existingUser.phone,
            state: existingUser.state,
            location: existingUser.location,
            role: existingUser.role,
            birthday: existingUser.birthday,
            profilePicture: existingUser.profilePicture,
            bio: existingUser.bio,
            languages: existingUser.languages,
            badges: existingUser.badges,
            rating: existingUser.rating,
            ratingCount: existingUser.ratingCount,
            showPhone: existingUser.showPhone,
            showEmail: existingUser.showEmail,
            createdAt: existingUser.createdAt,
          );
        }
        // Ensure Firestore has the user profile (in case user signed up before this fix)
        await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUserId)
            .set({
              'email': email,
              'name': userName,
              'profilePicture':
                  firebaseUser.photoURL ?? existingUser.profilePicture,
            }, SetOptions(merge: true));
        return _users[email];
      }

      // Create new user account with Firebase UID
      final userName = firebaseUser.displayName ?? 'Google User';
      final newUser = User(
        id: firebaseUserId, // Use Firebase UID as the user ID
        email: email,
        passwordHash: _hashPassword(
          'oauth_${DateTime.now().millisecondsSinceEpoch}',
        ),
        name: userName,
        phone: firebaseUser.phoneNumber ?? '',
        state: 'NSW',
        createdAt: DateTime.now(),
      );

      _users[email] = newUser;

      // Save profile to Firestore for notifications and other features
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUserId)
            .set({
              'email': email,
              'name': userName,
              'phone': firebaseUser.phoneNumber ?? '',
              'state': 'NSW',
              'role': 'Worker',
              'badges': <String>[],
              'createdAt': FieldValue.serverTimestamp(),
              'profilePicture': firebaseUser.photoURL,
            }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Failed to save user to Firestore (new): $e');
      }

      return newUser;
    } catch (error) {
      debugPrint('Google sign-in error: $error');
      return null;
    }
  }

  // Sign in with Apple
  static Future<User?> signInWithApple() async {
    try {
      // Ensure Firebase is initialized (important for web)
      await FirebaseBootstrap.tryInit();
      if (!FirebaseBootstrap.isReady) {
        throw Exception(
          'Firebase is not configured for this platform.\n'
          'On web, run `flutterfire configure --platforms=web` or add your Firebase config to `web/index.html`.\n'
          'Alternatively use email/password sign-in for web development.'
        );
      }
      UserCredential userCredential;

      if (kIsWeb) {
        // For web, use Firebase Auth popup
        final appleProvider = AppleAuthProvider();
        appleProvider.addScope('email');
        appleProvider.addScope('name');
        userCredential = await FirebaseAuth.instance.signInWithPopup(
          appleProvider,
        );
      } else if (Platform.isMacOS) {
        // macOS Apple Sign-In requires proper code signing and entitlements.
        // For local development without proper signing, use email/password sign-in.
        throw Exception(
          'Apple Sign-In on macOS requires Apple Developer code signing and entitlements. '
          'Please use email/password sign-in for local development, '
          'or set up proper code signing with an Apple Developer account.'
        );
      } else {
        // For mobile (Android/iOS), use signInWithProvider
        final appleProvider = AppleAuthProvider();
        appleProvider.addScope('email');
        appleProvider.addScope('name');
        userCredential = await FirebaseAuth.instance.signInWithProvider(
          appleProvider,
        );
      }

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) return null;

      final firebaseUserId = firebaseUser.uid;
      final email =
          firebaseUser.email ??
          'apple_${firebaseUser.uid}@privaterelay.appleid.com';

      // Check if user already exists in local database
      if (_users.containsKey(email)) {
        // Update the existing user with Firebase UID if different
        final existingUser = _users[email]!;
        final userName = firebaseUser.displayName ?? existingUser.name;
        if (existingUser.id != firebaseUserId) {
          _users[email] = User(
            id: firebaseUserId, // Use Firebase UID
            email: email,
            passwordHash: existingUser.passwordHash,
            name: userName,
            phone: firebaseUser.phoneNumber ?? existingUser.phone,
            state: existingUser.state,
            location: existingUser.location,
            role: existingUser.role,
            birthday: existingUser.birthday,
            profilePicture: existingUser.profilePicture,
            bio: existingUser.bio,
            languages: existingUser.languages,
            badges: existingUser.badges,
            rating: existingUser.rating,
            ratingCount: existingUser.ratingCount,
            showPhone: existingUser.showPhone,
            showEmail: existingUser.showEmail,
            createdAt: existingUser.createdAt,
          );
        }
        // Ensure Firestore has the user profile (in case user signed up before this fix)
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(firebaseUserId)
              .set({
                'email': email,
                'name': userName,
                'profilePicture':
                    firebaseUser.photoURL ?? existingUser.profilePicture,
              }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Failed to save Apple user to Firestore (existing): $e');
        }
        return _users[email];
      }

      // Create new user account with Firebase UID
      final userName = firebaseUser.displayName ?? 'Apple User';
      final newUser = User(
        id: firebaseUserId, // Use Firebase UID as the user ID
        email: email,
        passwordHash: _hashPassword(
          'oauth_${DateTime.now().millisecondsSinceEpoch}',
        ),
        name: userName,
        phone: firebaseUser.phoneNumber ?? '',
        state: 'NSW',
        createdAt: DateTime.now(),
      );

      _users[email] = newUser;

      // Save profile to Firestore for notifications and other features
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUserId)
            .set({
              'email': email,
              'name': userName,
              'phone': firebaseUser.phoneNumber ?? '',
              'state': 'NSW',
              'role': 'Worker',
              'badges': <String>[],
              'createdAt': FieldValue.serverTimestamp(),
              'profilePicture': firebaseUser.photoURL,
            }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Failed to save Apple user to Firestore (new): $e');
      }

      return newUser;
    } catch (error) {
      debugPrint('Apple sign-in error: $error');
      return null;
    }
  }

  // Sign out from OAuth providers
  static Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      // Ignore errors
    }
  }

  // Update user profile
  static Future<bool> updateUserProfile({
    required String userId,
    required String name,
    String? phone,
    String? state,
    String? location,
    String? role,
    DateTime? birthday,
    String? profilePicture,
    String? bio,
    List<String>? languages,
    List<String>? badges,
    bool? showPhone,
    bool? showEmail,
  }) async {
    try {
      // Find user by ID
      User? userToUpdate;
      String? userEmail;

      for (var entry in _users.entries) {
        if (entry.value.id == userId) {
          userToUpdate = entry.value;
          userEmail = entry.key;
          break;
        }
      }

      if (userToUpdate == null || userEmail == null) {
        return false;
      }

      // Create updated user
      final updatedUser = User(
        id: userToUpdate.id,
        email: userToUpdate.email,
        passwordHash: userToUpdate.passwordHash,
        name: name,
        phone: phone,
        state: state,
        location: location ?? userToUpdate.location,
        role: role ?? userToUpdate.role,
        birthday: birthday,
        profilePicture: profilePicture,
        bio: bio,
        languages: languages,
        badges: badges ?? userToUpdate.badges,
        rating: userToUpdate.rating,
        ratingCount: userToUpdate.ratingCount,
        showPhone: showPhone ?? userToUpdate.showPhone,
        showEmail: showEmail ?? userToUpdate.showEmail,
        createdAt: userToUpdate.createdAt,
      );

      // Update in map
      _users[userEmail] = updatedUser;
      return true;
    } catch (e) {
      return false;
    }
  }

  // Change password
  static Future<bool> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _users[email];
      if (user == null) {
        return false;
      }

      // Verify current password
      if (!_verifyPassword(currentPassword, user.passwordHash)) {
        return false;
      }

      // Update with new password
      final updatedUser = User(
        id: user.id,
        email: user.email,
        passwordHash: _hashPassword(newPassword),
        name: user.name,
        phone: user.phone,
        state: user.state,
        createdAt: user.createdAt,
      );

      _users[email] = updatedUser;
      return true;
    } catch (e) {
      return false;
    }
  }
}

class LoginPage extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const LoginPage({super.key, this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();

    // Check if account is locked
    if (AuthService.isAccountLocked(email)) {
      final remaining = AuthService.getRemainingLockoutTime(email);
      if (remaining != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Too many failed login attempts. Please try again in ${remaining.inMinutes} minutes.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    final user = AuthService.loginUser(email, _passwordController.text);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (user != null) {
      try {
        AuthState.login(user.id, user.email, user.name);
        await AuthState.persistSession();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome back, ${user.name}!'),
            backgroundColor: Colors.green,
          ),
        );

        // If no callback provided, navigate to HomePage
        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!();
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => HomePage()),
            (route) => false,
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid email or password'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      setState(() => _isLoading = true);

      final user = await AuthService.signInWithGoogle();

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (user != null) {
        AuthState.login(user.id, user.email, user.name);
        await AuthState.persistSession();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome, ${user.name}!'),
            backgroundColor: Colors.green,
          ),
        );

        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!();
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => HomePage()),
            (route) => false,
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google sign-in failed or was cancelled'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign-in error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleAppleSignIn() async {
    try {
      setState(() => _isLoading = true);

      final user = await AuthService.signInWithApple();

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (user != null) {
        AuthState.login(user.id, user.email, user.name);
        await AuthState.persistSession();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome, ${user.name}!'),
            backgroundColor: Colors.green,
          ),
        );

        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!();
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => HomePage()),
            (route) => false,
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Apple sign-in failed or was cancelled'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign-in error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Removed unused variable 'theme'

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // Logo/Title
                  const AppLogoSvg(size: 80, showText: true),

                  const SizedBox(height: 24),

                  // Email Field
                  TextFormField(
                    key: const ValueKey('login_email'),
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText:
                          AppLocalizations.of(context)?.emailLabel ??
                          'Email Address *',
                      hintText:
                          AppLocalizations.of(context)?.emailHint ??
                          'your.email@example.com',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!securityService.isValidEmail(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    key: const ValueKey('login_password'),
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText:
                          AppLocalizations.of(context)?.passwordLabel ??
                          'Password *',
                      hintText:
                          AppLocalizations.of(context)?.passwordHint ??
                          'Enter your password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => _showPassword = !_showPassword);
                        },
                      ),
                    ),
                    obscureText: !_showPassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 8),

                  // Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(context)?.passwordResetSent ??
                                  'Password reset link sent to your email',
                            ),
                          ),
                        );
                      },
                      child: const Text('Forgot Password?'),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Login Button
                  FilledButton(
                    key: const ValueKey('login_submit'),
                    onPressed: _isLoading ? null : _handleLogin,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            AppLocalizations.of(context)?.signIn ?? 'Sign In',
                          ),
                  ),

                  const SizedBox(height: 16),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          AppLocalizations.of(context)?.newUser ?? 'New User?',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300])),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Register Button
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RegisterPage(
                            onRegisterSuccess: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Registration successful! Please login.',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: Text(
                      AppLocalizations.of(context)?.createAccount ??
                          'Create Account',
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          AppLocalizations.of(context)?.or ?? 'OR',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300])),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Google Sign-In Button
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    icon: Icon(Icons.g_mobiledata, size: 28),
                    label: Text(
                      AppLocalizations.of(context)?.continueWithGoogle ??
                          'Continue with Google',
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      foregroundColor: Colors.black87,
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Apple Sign-In Button (only show on iOS/macOS)
                  if (!kIsWeb && (Platform.isIOS || Platform.isMacOS))
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleAppleSignIn,
                      icon: const Icon(Icons.apple, size: 24),
                      label: Text(
                        AppLocalizations.of(context)?.continueWithApple ??
                            'Continue with Apple',
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        foregroundColor: Colors.black87,
                        side: BorderSide(color: Colors.grey[300]!),
                        backgroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  final VoidCallback onRegisterSuccess;

  const RegisterPage({super.key, required this.onRegisterSuccess});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _emailErrorText;
  String? _passwordErrorText;
  String _selectedState = 'NSW';
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;
  bool _agreeToTerms = false;

  final List<String> _australianStates = [
    'NSW',
    'VIC',
    'QLD',
    'SA',
    'WA',
    'TAS',
    'ACT',
    'NT',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() {
      if (_emailErrorText != null) {
        setState(() => _emailErrorText = null);
      }
    });
    _passwordController.addListener(() {
      if (_passwordErrorText != null) {
        setState(() => _passwordErrorText = null);
      }
    });
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.pleaseAgreeTerms ??
                'Please agree to Terms and Conditions',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();

    // Check Firebase Auth for existing account with this email using REST lookup
    try {
      final apiKey = Firebase.app().options.apiKey;
      if (apiKey.isNotEmpty) {
        final uri = Uri.parse(
          'https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=$apiKey',
        );
        final resp = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': [email],
          }),
        );

        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body);
          if (data is Map &&
              data['users'] != null &&
              (data['users'] as List).isNotEmpty) {
            setState(() {
              _isLoading = false;
              _emailErrorText =
                  AppLocalizations.of(context)?.emailAlreadyRegistered ??
                  'Email already registered. Please login.';
            });
            if (!mounted) return;
            _formKey.currentState?.validate();
            return;
          }
        } else {
          debugPrint(
            'accounts:lookup returned ${resp.statusCode}: ${resp.body}',
          );
        }
      }
    } catch (e) {
      // Non-fatal: continue to local registration if network/auth lookup fails
      debugPrint('accounts:lookup error: $e');
    }

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    final err = await AuthService.registerUser(
      email,
      _passwordController.text,
      _nameController.text.trim(),
      _phoneController.text.trim(),
      _selectedState,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (err == null) {
      // Send email verification and show verification pending UI
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && !user.emailVerified) {
          await user.sendEmailVerification();
        }
      } catch (e) {
        debugPrint('sendEmailVerification error: $e');
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => VerificationPendingPage(email: email),
        ),
      );
    } else {
      // Map common Firebase error codes to inline field errors
      if (err == 'weak-password') {
        setState(() {
          _passwordErrorText = 'Password is too weak';
        });
      } else if (err == 'invalid-email') {
        setState(() {
          _emailErrorText = 'Please enter a valid email address';
        });
      } else if (err == 'email-already-in-use' ||
          err == 'email-already-registered-local') {
        setState(() {
          _emailErrorText =
              AppLocalizations.of(context)?.emailAlreadyRegistered ??
              'Email already registered. Please login.';
        });
      } else {
        setState(() {
          _emailErrorText =
              AppLocalizations.of(context)?.emailAlreadyRegistered ??
              'Email already registered. Please login.';
        });
      }

      _formKey.currentState?.validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.createAccount ?? 'Create Account',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // Full Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      hintText: 'Your full name',
                      prefixIcon: Icon(Icons.person_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your full name';
                      }
                      if (value.length < 3) {
                        return 'Name must be at least 3 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText:
                          AppLocalizations.of(context)?.emailLabel ??
                          'Email Address *',
                      hintText:
                          AppLocalizations.of(context)?.emailHint ??
                          'your.email@example.com',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (_emailErrorText != null) return _emailErrorText;
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!securityService.isValidEmail(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Phone
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number *',
                      hintText: '+61 2 1234 5678',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      if (!securityService.isValidPhoneNumber(value)) {
                        return 'Please enter a valid Australian phone number';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // State
                  DropdownButtonFormField<String>(
                    initialValue: _selectedState,
                    decoration: const InputDecoration(
                      labelText: 'State/Territory *',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    items: _australianStates.map((state) {
                      return DropdownMenuItem(value: state, child: Text(state));
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedState = value!);
                    },
                  ),

                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText:
                          AppLocalizations.of(context)?.passwordLabel ??
                          'Password *',
                      hintText:
                          AppLocalizations.of(context)?.passwordHint ??
                          'Create a strong password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => _showPassword = !_showPassword);
                        },
                      ),
                      helperText:
                          'At least 6 characters, with letters and numbers',
                    ),
                    obscureText: !_showPassword,
                    validator: (value) {
                      if (_passwordErrorText != null) return _passwordErrorText;
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return AppLocalizations.of(
                              context,
                            )?.passwordTooShort(6) ??
                            'Password must be at least 6 characters';
                      }
                      if (!value.contains(RegExp(r'[0-9]'))) {
                        return 'Password must contain at least one number';
                      }
                      if (!value.contains(RegExp(r'[a-zA-Z]'))) {
                        return 'Password must contain at least one letter';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Confirm Password
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password *',
                      hintText: 'Re-enter your password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(
                            () => _showConfirmPassword = !_showConfirmPassword,
                          );
                        },
                      ),
                    ),
                    obscureText: !_showConfirmPassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Terms and Conditions
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _agreeToTerms,
                        onChanged: (value) {
                          setState(() => _agreeToTerms = value!);
                        },
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color,
                              ),
                              children: [
                                TextSpan(text: 'I agree to the '),
                                TextSpan(
                                  text:
                                      AppLocalizations.of(
                                        context,
                                      )?.termsOfService ??
                                      'Terms of Service',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const TermsOfServicePage(),
                                        ),
                                      );
                                    },
                                ),
                                TextSpan(text: ' and '),
                                TextSpan(
                                  text:
                                      AppLocalizations.of(
                                        context,
                                      )?.privacyPolicy ??
                                      'Privacy Policy',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const PrivacyPolicyPage(),
                                        ),
                                      );
                                    },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Register Button
                  FilledButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            AppLocalizations.of(context)?.createAccount ??
                                'Create Account',
                          ),
                  ),

                  const SizedBox(height: 16),

                  // Back to Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account? '),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          AppLocalizations.of(context)?.signIn ?? 'Sign In',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

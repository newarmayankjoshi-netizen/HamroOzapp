/// Security Configuration Guide
/// 
/// This file documents how to securely configure your app with API credentials
/// 
/// NEVER commit actual API keys to version control!
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'secure_storage_compat.dart';

// Hardcoded credentials (use only for local/dev builds; avoid committing secrets)
const String _adzunaAppId = '2e6f4bda';
const String _adzunaAppKey = '48d22d2c5d219d42562c14a45e1aa2c7';

String? getHardcodedAdzunaAppId() {
  if (_adzunaAppId.isEmpty || _adzunaAppId == 'REPLACE_WITH_YOUR_APP_ID') {
    return null;
  }
  return _adzunaAppId;
}

String? getHardcodedAdzunaAppKey() {
  if (_adzunaAppKey.isEmpty || _adzunaAppKey == 'REPLACE_WITH_YOUR_APP_KEY') {
    return null;
  }
  return _adzunaAppKey;
}

/// Initialize secure credentials on app startup
/// Call this once from main.dart before running the app
Future<void> initializeSecurityCredentials() async {
  const secureStorage = FlutterSecureStorage();
  final secureStorageCompat = SecureStorageCompat(secureStorage: secureStorage);
  
  // Check if credentials already exist
  final existingAppId = await secureStorageCompat.read('adzuna_app_id');
  
  if (existingAppId == null) {
    // Note: For production deployments, consider getting credentials from:
    // 1. Environment variables
    // 2. Secure configuration server
    // 3. Firebase Remote Config with encryption
    // 4. Apple Keychain / Android Keystore via native code
    
    // PLACEHOLDER VALUES - Replace with your actual credentials
    const String appId = _adzunaAppId;
    const String appKey = _adzunaAppKey;
    
    if (appId == 'REPLACE_WITH_YOUR_APP_ID' || appKey == 'REPLACE_WITH_YOUR_APP_KEY') {
      debugPrint('⚠️  WARNING: API credentials not configured!');
      debugPrint('📝 Please set your Adzuna API credentials:');
      debugPrint('   1. Sign up at: https://developer.adzuna.com/signup');
      debugPrint('   2. Get your APP_ID and APP_KEY');
      debugPrint('   3. Update initializeSecurityCredentials() with your credentials');
      debugPrint('   4. Never commit credentials to version control!');
      return;
    }
    
    // Store credentials securely
    try {
      await secureStorageCompat.write('adzuna_app_id', appId);
      await secureStorageCompat.write('adzuna_app_key', appKey);
      debugPrint('✅ Security credentials initialized successfully');
    } on PlatformException catch (e) {
      if (e.code == '-34018' || e.message?.contains('entitlement') == true) {
        debugPrint('⚠️  Secure storage unavailable on this macOS build. Skipping keychain write.');
        debugPrint('   The app will continue to run, but API credentials are not persisted.');
        return;
      }
      rethrow;
    }
  } else {
    debugPrint('✅ Security credentials already configured');
  }
}

/// Best Practices for Securing Your App
/// 
/// 1. API KEYS & SECRETS
///    - Never hardcode API keys in source code
///    - Use flutter_secure_storage for sensitive data
///    - Rotate keys regularly
///    - Use different keys for development/production
///    - Monitor API key usage for unauthorized access
///
/// 2. HTTPS & NETWORK SECURITY
///    - Always use HTTPS (verify with BASE_URL in code)
///    - Implement certificate pinning for critical APIs
///    - Validate SSL certificates
///    - Use secure HTTP headers
///
/// 3. DATA ENCRYPTION
///    - Encrypt sensitive data at rest (phone, email, location)
///    - Use encryption library for local data storage
///    - Store encryption keys securely (not in code)
///
/// 4. INPUT VALIDATION
///    - Validate all user inputs
///    - Sanitize input to prevent injection attacks
///    - Set reasonable length limits
///    - Check data types and ranges
///
/// 5. AUTHENTICATION & AUTHORIZATION
///    - Implement proper user authentication
///    - Use secure token storage
///    - Implement token expiration and refresh
///    - Validate user permissions before allowing actions
///
/// 6. SENSITIVE DATA HANDLING
///    - Mask sensitive data in logs (emails, phone, tokens)
///    - Clear sensitive data from memory when not needed
///    - Don't share sensitive data via insecure channels
///    - Use secure storage for credentials
///
/// 7. PERMISSIONS & ACCESS CONTROL
///    - Request only necessary permissions
///    - Implement role-based access control (RBAC)
///    - Log access to sensitive operations
///    - Validate permissions on every request
///
/// 8. CODE SECURITY
///    - Keep dependencies updated (flutter pub upgrade)
///    - Use analysis_options.yaml for code analysis
///    - Obfuscate code in production builds
///    - Implement error handling without exposing internals
///
/// 9. MONITORING & LOGGING
///    - Log security events (failed auth, unauthorized access)
///    - Don't log sensitive data
///    - Monitor for suspicious activity
///    - Set up alerts for security issues
///
/// 10. SECURE STORAGE PLATFORMS
///    - Android: Android Keystore system
///    - iOS: Keychain Services
///    - Both: flutter_secure_storage abstracts these
///    - Web: Not recommended for storing secrets
///
/// ENVIRONMENT SETUP FOR PRODUCTION
/// 
/// Set environment variables instead of hardcoding:
/// 
/// export ADZUNA_APP_ID="your_app_id_here"
/// export ADZUNA_APP_KEY="your_app_key_here"
/// 
/// Then read from environment in your app initialization

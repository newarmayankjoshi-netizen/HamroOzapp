import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;

import 'secure_storage_compat.dart';

/// Security Service for handling sensitive data, encryption, and authentication
class SecurityService {
  static final _secureStorage = const FlutterSecureStorage();
  static final _secureStorageCompat = SecureStorageCompat(
    secureStorage: _secureStorage,
  );
  static final _encryptionKey = encrypt.Key.fromLength(32);

  // ==================== SECURE STORAGE ====================

  /// Store sensitive data securely (encrypted)
  Future<void> storeSecureData(String key, String value) async {
    if (key.isEmpty || value.isEmpty) {
      throw Exception('Key and value cannot be empty');
    }
    final encryptedValue = encryptData(value);
    await _secureStorageCompat.write(key, encryptedValue);
  }

  /// Retrieve sensitive data from secure storage (decrypt)
  Future<String?> getSecureData(String key) async {
    if (key.isEmpty) {
      throw Exception('Key cannot be empty');
    }
    final encryptedValue = await _secureStorageCompat.read(key);
    if (encryptedValue == null || encryptedValue.isEmpty) return null;
    return decryptData(encryptedValue);
  }

  /// Delete sensitive data
  Future<void> deleteSecureData(String key) async {
    if (key.isEmpty) {
      throw Exception('Key cannot be empty');
    }
    await _secureStorageCompat.delete(key);
  }

  /// Clear all secure storage
  Future<void> clearSecureStorage() async {
    await _secureStorageCompat.deleteAll();
  }

  // ==================== ENCRYPTION ====================

  /// Encrypt sensitive string data
  String encryptData(String plainText) {
    assert(plainText.isNotEmpty, 'Plain text cannot be empty');
    if (plainText.isEmpty) {
      throw Exception('Plain text cannot be empty');
    }
    final iv = encrypt.IV.fromSecureRandom(16);
    final cipher = encrypt.Encrypter(encrypt.AES(_encryptionKey));
    final encrypted = cipher.encrypt(plainText, iv: iv);
    
    // Store IV with encrypted data
    return '${encrypted.base64}:${iv.base64}';
  }

  /// Decrypt sensitive string data
  String decryptData(String encryptedText) {
    assert(encryptedText.isNotEmpty && encryptedText.contains(':'), 'Invalid encrypted data format');
    if (encryptedText.isEmpty || !encryptedText.contains(':')) {
      throw Exception('Invalid encrypted data format');
    }
    
    try {
      final parts = encryptedText.split(':');
      final encrypted = encrypt.Encrypted.fromBase64(parts[0]);
      final iv = encrypt.IV.fromBase64(parts[1]);
      final cipher = encrypt.Encrypter(encrypt.AES(_encryptionKey));
      
      return cipher.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw Exception('Decryption failed: ${e.toString()}');
    }
  }

  // ==================== INPUT VALIDATION ====================

  /// Validate email format
  bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Validate phone number (Australian format)
  bool isValidPhoneNumber(String phone) {
    if (phone.isEmpty) return false;
    // Remove common separators
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    // Australian phone: +61 or 0, followed by 9 digits
    final phoneRegex = RegExp(r'^(\+61|0)[0-9]{9}$');
    return phoneRegex.hasMatch(cleaned);
  }

  /// Sanitize user input to prevent injection attacks
  String sanitizeInput(String input, {int maxLength = 500}) {
    if (input.isEmpty) return '';

    // Remove potentially dangerous characters
    final sanitized = input
        .replaceAll(RegExp(r'[<>\"]'), '') // Remove HTML/script tags
        .replaceAll(RegExp(r"[;'`]"), '') // Remove SQL injection chars
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '') // Remove control chars
        .trim();

    // Limit length
    return sanitized.length > maxLength
        ? sanitized.substring(0, maxLength)
        : sanitized;
  }

  // ==================== CONTENT FILTERING ====================

  /// Basic prohibited content detection (spam/scam signals)
  static const List<String> _prohibitedTerms = [
    'gift card',
    'wire transfer',
    'western union',
    'moneygram',
    'crypto',
    'bitcoin',
    'usdt',
    'bank details',
    'card number',
    'cvv',
    'pin code',
    'otp',
    'verification code',
    'passport',
    'tfn',
    'tax file number',
  ];

  /// Returns a list of prohibited terms detected in input
  List<String> findProhibitedTerms(String input) {
    if (input.isEmpty) return [];
    final normalized = input.toLowerCase();
    return _prohibitedTerms
        .where((term) => normalized.contains(term))
        .toList();
  }

  /// Quick boolean check for prohibited content
  bool containsProhibitedContent(String input) {
    return findProhibitedTerms(input).isNotEmpty;
  }

  /// Validate price input
  bool isValidPrice(String price) {
    if (price.isEmpty) return false;
    try {
      final value = double.parse(price);
      return value > 0 && value < 1000000; // Reasonable limits
    } catch (e) {
      return false;
    }
  }

  /// Validate latitude/longitude coordinates
  bool isValidCoordinate(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }

  // ==================== API SECURITY ====================

  /// Create secure HTTP headers for API requests
  Map<String, String> getSecureHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'NepalAustraliaApp/1.0',
      'X-Requested-With': 'XMLHttpRequest',
    };
  }

  /// Validate API response before processing
  bool isValidJsonResponse(String responseBody) {
    if (responseBody.isEmpty) return false;
    try {
      jsonDecode(responseBody);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ==================== AUTHENTICATION ====================

  /// Hash a password for secure storage
  String hashPassword(String password) {
    if (password.isEmpty) {
      throw Exception('Password cannot be empty');
    }
    // In production, use proper password hashing library (bcrypt, argon2)
    // This is a simplified example
    return Base64Codec().encode(utf8.encode(password));
  }

  /// Verify password against hash
  bool verifyPassword(String password, String hash) {
    if (password.isEmpty || hash.isEmpty) return false;
    try {
      final decoded = utf8.decode(Base64Codec().decode(hash));
      return decoded == password;
    } catch (e) {
      return false;
    }
  }

  // ==================== SENSITIVE DATA MASKING ====================

  /// Mask email for display (e.g., user****@example.com)
  String maskEmail(String email) {
    if (!isValidEmail(email)) return email;
    final parts = email.split('@');
    final masked = '${parts[0].substring(0, 4)}****';
    return '$masked@${parts[1]}';
  }

  /// Mask phone number for display (e.g., +61 *** *** 1234)
  String maskPhoneNumber(String phone) {
    if (!isValidPhoneNumber(phone)) return phone;
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final start = cleaned.substring(0, 3);
    final end = cleaned.substring(cleaned.length - 4);
    return '$start *** *** $end';
  }

  /// Sanitize sensitive data from logs
  String maskSensitiveData(String data) {
    // Remove API keys
    data = data.replaceAll(RegExp(r'app_key[=:]\s*\w+'), 'app_key=****');
    data = data.replaceAll(RegExp(r'app_id[=:]\s*\w+'), 'app_id=****');
    // Remove auth tokens
    data = data.replaceAll(RegExp(r'authorization[=:]\s*\w+'), 'authorization=****');
    return data;
  }
}

// Global instance
final securityService = SecurityService();

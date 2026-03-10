// ignore_for_file: dead_code, dead_null_aware_expression, unnecessary_null_comparison

// verbose upload logging is gated to debug builds only
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth_page.dart';
import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

/// Lightweight verification helper service for this app copy.
class VerificationService {
  static final _db = FirebaseFirestore.instance;

  // Allowed/accepted document types
  static const allowedTypes = <String>{
    'passport',
    'aus_driver_license',
    'aus_photo_id',
    'international_passport',
    'immicard',
  };

  // Types that should be auto-rejected on the client
  static const autoRejectTypes = <String>{
    'student_id',
    'bank_card',
    'library_card',
    'medicare_card',
  };

  static Future<String> submitDocument({
    required String userId,
    required String type,
    required File file,
  }) async {
    if (autoRejectTypes.contains(type)) {
      throw Exception('Selected document type is not acceptable for verification.');
    }
    final submissionId = _db.collection('users').doc(userId).collection('id_submissions').doc().id;

    final storagePath = 'verification/$userId/$submissionId.jpg';

    // Try upload with the default configured storage instance first, then
    // attempt a common fallback bucket name if the upload or download fails.
    final bucketCandidates = <String>[];
    // Read bucket/project safely (some SDK versions have nullable types).
    try {
      final b = Firebase.app().options.storageBucket ?? '';
      if (b.isNotEmpty) bucketCandidates.add(b);
    } catch (_) {}

    // Add canonical fallback: PROJECT_ID.appspot.com
    try {
      final pid = Firebase.app().options.projectId ?? '';
      if (pid.isNotEmpty) {
        final canonical = '$pid.appspot.com';
        if (!bucketCandidates.contains(canonical)) bucketCandidates.add(canonical);
      }
    } catch (_) {}

    String? url;
    Exception? lastError;
    for (final bucket in bucketCandidates) {
      try {
        if (kDebugMode) debugPrint('VerificationService: attempting upload to bucket="$bucket" path="$storagePath"');
        final storage = FirebaseStorage.instanceFor(bucket: bucket);
        final ref = storage.ref(storagePath);
        final uploadTask = ref.putFile(file);
        final snapshot = await uploadTask.whenComplete(() {});
        if (kDebugMode) debugPrint('VerificationService: upload snapshot state=${snapshot.state} bytesTransferred=${snapshot.bytesTransferred} totalBytes=${snapshot.totalBytes}');
        if (snapshot.state != TaskState.success) {
          throw Exception('Upload did not complete successfully (state=${snapshot.state})');
        }

        // Confirm object exists by fetching metadata before download URL.
        try {
          final meta = await ref.getMetadata();
          if (kDebugMode) debugPrint('VerificationService: metadata fetched; size=${meta.size} contentType=${meta.contentType}');
        } catch (mErr) {
          if (kDebugMode) debugPrint('VerificationService: metadata fetch failed: $mErr');
          rethrow;
        }

        url = await ref.getDownloadURL();
        if (kDebugMode) {
          // Shorten URL for logs to avoid exposing long tokens in logs
          final shortUrl = url.length > 120 ? '${url.substring(0, 120)}...' : url;
          debugPrint('VerificationService: downloadUrl=$shortUrl');
        }
        lastError = null;
        break;
      } catch (e) {
        lastError = Exception('Bucket "$bucket" failed: $e');
        if (kDebugMode) debugPrint('VerificationService: bucket "$bucket" failed with exception: $e');
        // try next candidate
      }
    }

    if (url == null) {
      throw Exception('Failed to upload to any storage bucket. Last error: $lastError');
    }

    // Attach the submitting user's display name or email as ownerName so
    // admin UIs can show a friendly name without needing additional reads.
    String? ownerName;
    try {
      final fUser = FirebaseAuth.instance.currentUser;
      if (fUser != null && (fUser.displayName != null || fUser.email != null)) {
        ownerName = fUser.displayName ?? fUser.email;
      } else {
        // Fall back to app's AuthState which may hold the canonical user name/email
        ownerName = AuthState.currentUserName ?? AuthState.currentUserEmail;
      }
    } catch (_) {
      ownerName ??= AuthState.currentUserName ?? AuthState.currentUserEmail;
    }

    final doc = {
      'type': type,
      'imageUrl': url,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (ownerName != null) {
      doc['ownerName'] = ownerName;
    }

    // Debug: log what ownerName we will write and the current auth state
    try {
      debugPrint('VerificationService.submitDocument ownerName=$ownerName firebaseUid=${FirebaseAuth.instance.currentUser?.uid} firebaseDisplayName=${FirebaseAuth.instance.currentUser?.displayName} authStateId=${AuthState.currentUserId} authStateName=${AuthState.currentUserName} authStateEmail=${AuthState.currentUserEmail}');
    } catch (_) {}

    await _db.collection('users').doc(userId).collection('id_submissions').doc(submissionId).set(doc);

    await _db.collection('users').doc(userId).set({
      'verificationSummary': {
        'lastSubmissionId': submissionId,
        'lastStatus': 'pending',
        'lastSubmittedAt': FieldValue.serverTimestamp(),
      }
    }, SetOptions(merge: true));

    return submissionId;
  }

  static Future<DocumentSnapshot<Map<String, dynamic>>?> getLatestSubmission(String userId) async {
    final q = await _db.collection('users').doc(userId).collection('id_submissions').orderBy('createdAt', descending: true).limit(1).get();
    if (q.docs.isEmpty) return null;
    return q.docs.first;
  }

  static Future<bool> canPost(String userId) async {
    final snap = await _db.collection('users').doc(userId).get();
    if (!snap.exists) return false;
    final data = snap.data() ?? {};
    final level = (data['contributorLevel'] ?? 0) as int;
    return level >= 2;
  }

  static Future<void> setContributorLevel(String userId, int level, {String? reviewerId}) async {
    await _db.collection('users').doc(userId).set({
      'contributorLevel': level,
      'verifiedBadge': level >= 2,
    }, SetOptions(merge: true));

    await _db.collection('admin').doc('verification_audit').collection(userId).add({
      'level': level,
      'reviewerId': reviewerId,
      'at': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> pendingSubmissionsStream() {
    return _db.collectionGroup('id_submissions').where('status', isEqualTo: 'pending').orderBy('createdAt', descending: true).snapshots();
  }
}

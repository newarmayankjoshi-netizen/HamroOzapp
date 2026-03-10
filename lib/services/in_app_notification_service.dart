import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

/// Service for managing user notifications.
/// 
/// Database structure:
/// notifications/{recipientUserId}/user_notifications/{notificationId}/
///   - type: string (new_follower, new_listing, etc.)
///   - fromUserId: string
///   - title: string
///   - body: string
///   - read: boolean
///   - createdAt: timestamp
///   - data: map (additional data like listingId, listingType, etc.)
class InAppNotificationService {
  static CollectionReference<Map<String, dynamic>> _userNotifications(String userId) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .doc(userId)
        .collection('user_notifications');
  }

  /// Create a notification for a user.
  static Future<bool> createNotification({
    required String recipientUserId,
    required String type,
    required String title,
    required String body,
    String? fromUserId,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _userNotifications(recipientUserId).add({
        'type': type,
        'fromUserId': fromUserId,
        'title': title,
        'body': body,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        'data': data ?? {},
      });
      return true;
    } catch (e, st) {
      developer.log(
        'InAppNotificationService: createNotification failed: $e',
        name: 'InAppNotificationService',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  /// Mark a notification as read.
  static Future<bool> markAsRead(String userId, String notificationId) async {
    try {
      await _userNotifications(userId).doc(notificationId).update({
        'read': true,
      });
      return true;
    } catch (e) {
      developer.log(
        'InAppNotificationService: markAsRead failed: $e',
        name: 'InAppNotificationService',
        error: e,
      );
      return false;
    }
  }

  /// Mark all notifications as read.
  static Future<bool> markAllAsRead(String userId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final unread = await _userNotifications(userId)
          .where('read', isEqualTo: false)
          .get();
      
      for (final doc in unread.docs) {
        batch.update(doc.reference, {'read': true});
      }
      
      await batch.commit();
      return true;
    } catch (e) {
      developer.log(
        'InAppNotificationService: markAllAsRead failed: $e',
        name: 'InAppNotificationService',
        error: e,
      );
      return false;
    }
  }

  /// Delete a notification.
  static Future<bool> deleteNotification(String userId, String notificationId) async {
    try {
      await _userNotifications(userId).doc(notificationId).delete();
      return true;
    } catch (e) {
      developer.log(
        'InAppNotificationService: deleteNotification failed: $e',
        name: 'InAppNotificationService',
        error: e,
      );
      return false;
    }
  }

  /// Delete all notifications for a user.
  static Future<bool> deleteAllNotifications(String userId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final all = await _userNotifications(userId).get();
      
      for (final doc in all.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      return true;
    } catch (e) {
      developer.log(
        'InAppNotificationService: deleteAllNotifications failed: $e',
        name: 'InAppNotificationService',
        error: e,
      );
      return false;
    }
  }

  /// Stream notifications for a user.
  static Stream<QuerySnapshot<Map<String, dynamic>>> streamNotifications(String userId) {
    return _userNotifications(userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Get unread notification count.
  static Future<int> getUnreadCount(String userId) async {
    try {
      final snap = await _userNotifications(userId)
          .where('read', isEqualTo: false)
          .count()
          .get();
      return snap.count ?? 0;
    } catch (e) {
      developer.log(
        'InAppNotificationService: getUnreadCount failed: $e',
        name: 'InAppNotificationService',
        error: e,
      );
      return 0;
    }
  }

  /// Stream unread notification count.
  static Stream<int> streamUnreadCount(String userId) {
    return _userNotifications(userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }
}

/// Notification types enum.
class NotificationType {
  static const String newFollower = 'new_follower';
  static const String newRoom = 'new_room';
  static const String newJob = 'new_job';
  static const String newItem = 'new_item';
  static const String newReview = 'new_review';
  static const String verificationApproved = 'verification_approved';
  static const String verificationRejected = 'verification_rejected';
  static const String newMessage = 'new_message';
}

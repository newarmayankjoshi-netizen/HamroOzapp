import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

/// Service for managing user follow relationships.
/// 
/// Database structure:
/// user_follows/{followerId}_{followedId}/
///   - followerId: string (the user who is following)
///   - followedId: string (the user being followed)
///   - createdAt: timestamp
///   - notifyOnNewListing: boolean
class FollowService {
  static final CollectionReference<Map<String, dynamic>> _coll =
      FirebaseFirestore.instance.collection('user_follows');

  static String _docId(String followerId, String followedId) =>
      '${followerId}_$followedId';

  /// Check if [followerId] is following [followedId].
  static Future<bool> isFollowing(String followerId, String followedId) async {
    final id = _docId(followerId, followedId);
    try {
      final doc = await _coll.doc(id).get();
      return doc.exists;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        developer.log(
          'FollowService: isFollowing read permission denied for $id',
          name: 'FollowService',
          error: e,
        );
        return false;
      }
      rethrow;
    }
  }

  /// Follow a user.
  static Future<bool> follow(
    String followerId,
    String followedId, {
    bool notifyOnNewListing = true,
  }) async {
    if (followerId == followedId) return false; // Can't follow yourself
    
    final id = _docId(followerId, followedId);
    final data = {
      'followerId': followerId,
      'followedId': followedId,
      'notifyOnNewListing': notifyOnNewListing,
      'createdAt': FieldValue.serverTimestamp(),
    };
    try {
      developer.log(
        'FollowService: creating follow doc=$id',
        name: 'FollowService',
      );
      await _coll.doc(id).set(data);
      
      // Also update follower/following counts on user documents
      await _updateCounts(followerId, followedId, increment: true);
      
      return true;
    } catch (e, st) {
      developer.log(
        'FollowService: follow failed: $e',
        name: 'FollowService',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  /// Unfollow a user.
  static Future<bool> unfollow(String followerId, String followedId) async {
    final id = _docId(followerId, followedId);
    try {
      developer.log(
        'FollowService: deleting follow doc=$id',
        name: 'FollowService',
      );
      await _coll.doc(id).delete();
      
      // Update follower/following counts
      await _updateCounts(followerId, followedId, increment: false);
      
      return true;
    } catch (e, st) {
      developer.log(
        'FollowService: unfollow failed: $e',
        name: 'FollowService',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  /// Toggle follow status.
  static Future<bool> toggleFollow(
    String followerId,
    String followedId, {
    bool notifyOnNewListing = true,
  }) async {
    if (followerId == followedId) return false;
    
    final isCurrentlyFollowing = await isFollowing(followerId, followedId);
    if (isCurrentlyFollowing) {
      return unfollow(followerId, followedId);
    } else {
      return follow(followerId, followedId, notifyOnNewListing: notifyOnNewListing);
    }
  }

  /// Get count of followers for a user.
  static Future<int> getFollowerCount(String userId) async {
    try {
      final snap = await _coll.where('followedId', isEqualTo: userId).count().get();
      return snap.count ?? 0;
    } catch (e) {
      developer.log(
        'FollowService: getFollowerCount failed: $e',
        name: 'FollowService',
        error: e,
      );
      return 0;
    }
  }

  /// Get count of users that [userId] is following.
  static Future<int> getFollowingCount(String userId) async {
    try {
      final snap = await _coll.where('followerId', isEqualTo: userId).count().get();
      return snap.count ?? 0;
    } catch (e) {
      developer.log(
        'FollowService: getFollowingCount failed: $e',
        name: 'FollowService',
        error: e,
      );
      return 0;
    }
  }

  /// Stream of users following [userId] (followers).
  /// Note: Returns unordered results to avoid requiring a composite index.
  /// Client-side sorting can be done if needed.
  static Stream<QuerySnapshot<Map<String, dynamic>>> streamFollowers(String userId) {
    return _coll
        .where('followedId', isEqualTo: userId)
        .snapshots();
  }

  /// Stream of users that [userId] is following.
  /// Note: Returns unordered results to avoid requiring a composite index.
  static Stream<QuerySnapshot<Map<String, dynamic>>> streamFollowing(String userId) {
    return _coll
        .where('followerId', isEqualTo: userId)
        .snapshots();
  }

  /// Get list of follower user IDs.
  static Future<List<String>> getFollowerIds(String userId) async {
    try {
      final snap = await _coll.where('followedId', isEqualTo: userId).get();
      return snap.docs.map((d) => d.data()['followerId'] as String).toList();
    } catch (e) {
      developer.log(
        'FollowService: getFollowerIds failed: $e',
        name: 'FollowService',
        error: e,
      );
      return [];
    }
  }

  /// Get list of user IDs that [userId] is following.
  static Future<List<String>> getFollowingIds(String userId) async {
    try {
      final snap = await _coll.where('followerId', isEqualTo: userId).get();
      return snap.docs.map((d) => d.data()['followedId'] as String).toList();
    } catch (e) {
      developer.log(
        'FollowService: getFollowingIds failed: $e',
        name: 'FollowService',
        error: e,
      );
      return [];
    }
  }

  /// Update notification preference for a follow relationship.
  static Future<bool> updateNotificationPreference(
    String followerId,
    String followedId, {
    required bool notifyOnNewListing,
  }) async {
    final id = _docId(followerId, followedId);
    try {
      await _coll.doc(id).update({
        'notifyOnNewListing': notifyOnNewListing,
      });
      return true;
    } catch (e) {
      developer.log(
        'FollowService: updateNotificationPreference failed: $e',
        name: 'FollowService',
        error: e,
      );
      return false;
    }
  }

  /// Update follower/following counts on user documents.
  static Future<void> _updateCounts(
    String followerId,
    String followedId, {
    required bool increment,
  }) async {
    final usersRef = FirebaseFirestore.instance.collection('users');
    final delta = increment ? 1 : -1;
    
    try {
      // Update following count for the follower
      await usersRef.doc(followerId).set({
        'followingCount': FieldValue.increment(delta),
      }, SetOptions(merge: true));
      
      // Update follower count for the followed user
      await usersRef.doc(followedId).set({
        'followerCount': FieldValue.increment(delta),
      }, SetOptions(merge: true));
    } catch (e) {
      developer.log(
        'FollowService: _updateCounts failed: $e',
        name: 'FollowService',
        error: e,
      );
    }
  }
}

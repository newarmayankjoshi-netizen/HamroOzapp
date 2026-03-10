import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

class BookmarkService {
  static final CollectionReference<Map<String, dynamic>> _coll = FirebaseFirestore.instance.collection('bookmarks');

  static String _docId(String userId, String targetType, String targetId) => '${userId}_${targetType}_$targetId';

  static Future<bool> isBookmarked(String userId, String targetType, String targetId) async {
    final id = _docId(userId, targetType, targetId);
    try {
      final doc = await _coll.doc(id).get();
      return doc.exists;
    } on FirebaseException catch (e) {
      // Permission denied when reading the bookmark should be treated as
      // "not bookmarked" on the client (the user may be allowed to create
      // or delete but not read in some rule configurations). Log and
      // return false so the UI remains usable.
      if (e.code == 'permission-denied') {
        developer.log('BookmarkService: isBookmarked read permission denied for $id; treating as not bookmarked', name: 'BookmarkService', error: e);
        return false;
      }
      rethrow;
    }
  }
  static Future<bool> setBookmark(String userId, String targetType, String targetId, {String? title}) async {
    final id = _docId(userId, targetType, targetId);
    final data = {
      'userId': userId,
      'targetType': targetType,
      'targetId': targetId,
      'title': title ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    };
    try {
      developer.log('BookmarkService: creating bookmark doc=$id data=$data', name: 'BookmarkService');
      await _coll.doc(id).set(data);
      return true;
    } catch (e, st) {
      developer.log('BookmarkService: setBookmark failed: $e', name: 'BookmarkService', error: e, stackTrace: st);
      return false;
    }
  }

  static Future<bool> removeBookmark(String userId, String targetType, String targetId) async {
    final id = _docId(userId, targetType, targetId);
    try {
      developer.log('BookmarkService: deleting bookmark doc=$id', name: 'BookmarkService');
      await _coll.doc(id).delete();
      return true;
    } catch (e, st) {
      developer.log('BookmarkService: removeBookmark failed: $e', name: 'BookmarkService', error: e, stackTrace: st);
      return false;
    }
  }

  static Future<bool> toggleBookmark(String userId, String targetType, String targetId, {String? title}) async {
    final id = _docId(userId, targetType, targetId);
    try {
      // Try to read the doc first. In some security rule configurations the
      // client may not be allowed to read a non-existing doc (permission-denied
      // on `get()`), while create is still permitted. Handle that case by
      // attempting a create when a read fails with permission issues.
      try {
        final doc = await _coll.doc(id).get();
        if (doc.exists) {
          developer.log('BookmarkService: toggle -> deleting existing bookmark $id', name: 'BookmarkService');
          await doc.reference.delete();
          return true;
        } else {
          final data = {
            'userId': userId,
            'targetType': targetType,
            'targetId': targetId,
            'title': title ?? '',
            'createdAt': FieldValue.serverTimestamp(),
          };
          developer.log('BookmarkService: toggle -> creating bookmark doc=$id data=$data', name: 'BookmarkService');
          await _coll.doc(id).set(data);
          return true;
        }
      } on FirebaseException catch (e) {
        // If read is denied but the user is allowed to create, try creating.
        if (e.code == 'permission-denied') {
          developer.log('BookmarkService: read permission denied for $id, attempting create', name: 'BookmarkService', error: e);
          final data = {
            'userId': userId,
            'targetType': targetType,
            'targetId': targetId,
            'title': title ?? '',
            'createdAt': FieldValue.serverTimestamp(),
          };
          await _coll.doc(id).set(data);
          return true;
        }
        rethrow;
      }
    } catch (e, st) {
      developer.log('BookmarkService: toggleBookmark failed: $e', name: 'BookmarkService', error: e, stackTrace: st);
      return false;
    }
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamBookmarks(String userId) {
    return _coll.where('userId', isEqualTo: userId).orderBy('createdAt', descending: true).snapshots();
  }
}

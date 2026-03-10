import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class UserStats {
  final int roomsPosted;
  final int jobsPosted;
  final int eventsPosted;
  final int itemsForSale;
  final int itemsSold;

  const UserStats({
    required this.roomsPosted,
    required this.jobsPosted,
    required this.eventsPosted,
    required this.itemsForSale,
    required this.itemsSold,
  });
}

class UserStatsService {
  static Future<UserStats?> tryLoad(String userId) async {
    if (Firebase.apps.isEmpty) return null;

    try {
      final db = FirebaseFirestore.instance;

        final roomsSnap = await db
          .collection('community_rooms')
          .where('createdBy', isEqualTo: userId)
          .get();

      final jobsSnap = await db
          .collection('community_jobs')
          .where('createdBy', isEqualTo: userId)
          .get();

        final eventsSnap = await db
          .collection('community_events')
          .where('createdBy', isEqualTo: userId)
          .get();

      final itemsSnap = await db
          .collection('marketplace_items')
          .where('sellerId', isEqualTo: userId)
          .get();

      final itemsDocs = itemsSnap.docs;
      final itemsSold = itemsDocs.where((d) {
        final data = d.data();
        final value = data['isClosed'];
        return value is bool && value;
      }).length;

      final itemsForSale = itemsDocs.length - itemsSold;

      return UserStats(
        roomsPosted: roomsSnap.docs.length,
        jobsPosted: jobsSnap.docs.length,
        eventsPosted: eventsSnap.docs.length,
        itemsForSale: itemsForSale < 0 ? 0 : itemsForSale,
        itemsSold: itemsSold,
      );
    } catch (_) {
      return null;
    }
  }
}

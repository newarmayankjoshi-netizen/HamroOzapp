import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth_page.dart';
import '../../services/firebase_bootstrap.dart';
import 'owner_models.dart';
import 'owner_storage.dart';

abstract class OwnerRestaurantRepository {
  static OwnerRestaurantRepository get instance {
    if (FirebaseBootstrap.isReady && _currentOwnerKey().isNotEmpty) {
      return _FirebaseOwnerRestaurantRepository();
    }
    return _LocalOwnerRestaurantRepository();
  }

  static String _currentOwnerKey() {
    final email = (AuthState.currentUserEmail ?? '').trim();
    if (email.isNotEmpty) return email.toLowerCase();
    return (AuthState.currentUserId ?? '').trim();
  }

  Future<List<OwnerRestaurantProfile>> loadMyRestaurants();
  Future<void> upsert(OwnerRestaurantProfile profile);
  Future<void> deleteById(String id);

  Future<void> incrementProfileView(String restaurantId);
  Future<void> incrementMenuItemView(String restaurantId, String menuItemId);
  Future<int> getProfileViews(String restaurantId);
  Future<int> getMenuItemViews(String restaurantId, String menuItemId);
  Future<void> incrementBookingClick(String restaurantId);
  Future<void> incrementOrderClick(String restaurantId);
}

class _LocalOwnerRestaurantRepository implements OwnerRestaurantRepository {
  static const _kLegacyClaimedByKey = 'owner_restaurants_legacy_claimed_by_v1';

  String get _ownerKey => OwnerRestaurantRepository._currentOwnerKey();

  @override
  Future<List<OwnerRestaurantProfile>> loadMyRestaurants() async {
    final userId = _ownerKey;
    final profiles = await OwnerRestaurantStorage.loadProfiles();

    if (userId.isEmpty) return const [];

    // Backward-compat: migrate legacy profiles (ownerUserId missing) once.
    final legacy = profiles.where((p) => p.ownerUserId.trim().isEmpty).toList();
    if (legacy.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final claimedBy = (prefs.getString(_kLegacyClaimedByKey) ?? '').trim();

      if (claimedBy.isEmpty || claimedBy == userId) {
        if (claimedBy.isEmpty) {
          await prefs.setString(_kLegacyClaimedByKey, userId);
        }
        for (final p in legacy) {
          await OwnerRestaurantStorage.upsertProfile(
            p.copyWith(ownerUserId: userId),
          );
        }
        final migrated = await OwnerRestaurantStorage.loadProfiles();
        return migrated.where((p) => p.ownerUserId == userId).toList();
      }
    }

    return profiles.where((p) => p.ownerUserId == userId).toList();
  }

  @override
  Future<void> upsert(OwnerRestaurantProfile profile) async {
    final userId = _ownerKey;
    final owned = profile.ownerUserId.isNotEmpty
        ? profile
        : profile.copyWith(ownerUserId: userId);
    await OwnerRestaurantStorage.upsertProfile(owned);
  }

  @override
  Future<void> deleteById(String id) => OwnerRestaurantStorage.deleteProfile(id);

  @override
  Future<void> incrementProfileView(String restaurantId) =>
      OwnerRestaurantStorage.incrementProfileView(restaurantId);

  @override
  Future<void> incrementMenuItemView(String restaurantId, String menuItemId) =>
      OwnerRestaurantStorage.incrementMenuItemView(restaurantId, menuItemId);

  @override
  Future<int> getProfileViews(String restaurantId) =>
      OwnerRestaurantStorage.getProfileViews(restaurantId);

  @override
  Future<int> getMenuItemViews(String restaurantId, String menuItemId) =>
      OwnerRestaurantStorage.getMenuItemViews(restaurantId, menuItemId);

  @override
  Future<void> incrementBookingClick(String restaurantId) async {
    // Local demo only; not tracked.
  }

  @override
  Future<void> incrementOrderClick(String restaurantId) async {
    // Local demo only; not tracked.
  }
}

class _FirebaseOwnerRestaurantRepository implements OwnerRestaurantRepository {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('owner_restaurants');

  String get _uid => OwnerRestaurantRepository._currentOwnerKey();

  @override
  Future<List<OwnerRestaurantProfile>> loadMyRestaurants() async {
    final query = await _col.where('ownerUserId', isEqualTo: _uid).get();
    return query.docs
        .map((d) => OwnerRestaurantProfile.fromJson(d.data()))
        .toList();
  }

  @override
  Future<void> upsert(OwnerRestaurantProfile profile) async {
    final owned = profile.ownerUserId == _uid
        ? profile
        : profile.copyWith(ownerUserId: _uid);

    await _col.doc(owned.id).set(
          owned.toJson(),
          SetOptions(merge: true),
        );
  }

  @override
  Future<void> deleteById(String id) async {
    await _col.doc(id).delete();
  }

  @override
  Future<void> incrementProfileView(String restaurantId) async {
    await _col.doc(restaurantId).set(
      {
        'analytics': {
          'profileViews': FieldValue.increment(1),
        },
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> incrementMenuItemView(String restaurantId, String menuItemId) async {
    await _col.doc(restaurantId).set(
      {
        'analytics': {
          'menuItemViews': {
            menuItemId: FieldValue.increment(1),
          },
        },
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<int> getProfileViews(String restaurantId) async {
    final snap = await _col.doc(restaurantId).get();
    final data = snap.data();
    final analytics = (data?['analytics'] as Map?) ?? const {};
    return (analytics['profileViews'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<int> getMenuItemViews(String restaurantId, String menuItemId) async {
    final snap = await _col.doc(restaurantId).get();
    final data = snap.data();
    final analytics = (data?['analytics'] as Map?) ?? const {};
    final menuViews = (analytics['menuItemViews'] as Map?) ?? const {};
    return (menuViews[menuItemId] as num?)?.toInt() ?? 0;
  }

  @override
  Future<void> incrementBookingClick(String restaurantId) async {
    await _col.doc(restaurantId).set(
      {
        'analytics': {
          'bookingClicks': FieldValue.increment(1),
        },
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> incrementOrderClick(String restaurantId) async {
    await _col.doc(restaurantId).set(
      {
        'analytics': {
          'orderClicks': FieldValue.increment(1),
        },
      },
      SetOptions(merge: true),
    );
  }
}

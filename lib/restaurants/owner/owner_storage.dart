import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'owner_models.dart';

class OwnerRestaurantStorage {
  static const _kProfilesKey = 'owner_restaurants_profiles_v1';
  static const _kAnalyticsKey = 'owner_restaurants_analytics_v1';

  static Future<List<OwnerRestaurantProfile>> loadProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kProfilesKey);
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      return OwnerRestaurantProfile.listFromJsonString(raw);
    } catch (_) {
      return const [];
    }
  }

  static Future<void> saveProfiles(List<OwnerRestaurantProfile> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kProfilesKey,
      OwnerRestaurantProfile.listToJsonString(profiles),
    );
  }

  static Future<void> upsertProfile(OwnerRestaurantProfile profile) async {
    final profiles = (await loadProfiles()).toList();
    final index = profiles.indexWhere((p) => p.id == profile.id);
    if (index >= 0) {
      profiles[index] = profile;
    } else {
      profiles.add(profile);
    }
    await saveProfiles(profiles);
  }

  static Future<void> deleteProfile(String id) async {
    final profiles = (await loadProfiles()).where((p) => p.id != id).toList();
    await saveProfiles(profiles);
  }

  // --- Analytics (local demo) ---

  static Future<Map<String, dynamic>> loadAnalyticsMap() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kAnalyticsKey);
    if (raw == null || raw.trim().isEmpty) return <String, dynamic>{};
    try {
      return _decodeMap(raw);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static Map<String, dynamic> _decodeMap(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return <String, dynamic>{};
    return decoded.map(
      (key, value) => MapEntry(key.toString(), value),
    );
  }

  static String _encodeMap(Map<String, dynamic> map) {
    return jsonEncode(map);
  }

  static Future<void> incrementProfileView(String restaurantId) async {
    final prefs = await SharedPreferences.getInstance();
    final analytics = await loadAnalyticsMap();
    final r = Map<String, dynamic>.from(
      (analytics[restaurantId] as Map?) ?? <String, dynamic>{},
    );
    r['profileViews'] = ((r['profileViews'] as num?)?.toInt() ?? 0) + 1;
    analytics[restaurantId] = r;
    await prefs.setString(_kAnalyticsKey, _encodeMap(analytics));
  }

  static Future<void> incrementMenuItemView(
    String restaurantId,
    String menuItemId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final analytics = await loadAnalyticsMap();
    final r = Map<String, dynamic>.from(
      (analytics[restaurantId] as Map?) ?? <String, dynamic>{},
    );
    final menuViews = Map<String, dynamic>.from(
      (r['menuItemViews'] as Map?) ?? <String, dynamic>{},
    );
    menuViews[menuItemId] = ((menuViews[menuItemId] as num?)?.toInt() ?? 0) + 1;
    r['menuItemViews'] = menuViews;
    analytics[restaurantId] = r;
    await prefs.setString(_kAnalyticsKey, _encodeMap(analytics));
  }

  static Future<int> getProfileViews(String restaurantId) async {
    final analytics = await loadAnalyticsMap();
    final r = (analytics[restaurantId] as Map?) ?? const <String, dynamic>{};
    return (r['profileViews'] as num?)?.toInt() ?? 0;
  }

  static Future<int> getMenuItemViews(
    String restaurantId,
    String menuItemId,
  ) async {
    final analytics = await loadAnalyticsMap();
    final r = (analytics[restaurantId] as Map?) ?? const <String, dynamic>{};
    final menuViews = (r['menuItemViews'] as Map?) ?? const <String, dynamic>{};
    return (menuViews[menuItemId] as num?)?.toInt() ?? 0;
  }
}

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:hamro_oz/utils/map_utils.dart';

class Restaurant {
  final String name;
  final double latitude;
  final double longitude;
  final String? address;
  final String? phone;

  Restaurant({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
    this.phone,
  });

  String get location {
    // Determine location based on latitude/longitude
    if (latitude >= -38.0 && latitude <= -33.0 && longitude >= 150.0 && longitude <= 154.0) {
      return 'Sydney, NSW';
    } else if (latitude >= -38.5 && latitude <= -37.0 && longitude >= 144.0 && longitude <= 146.0) {
      return 'Melbourne, VIC';
    } else if (latitude >= -27.5 && latitude <= -27.0 && longitude >= 152.5 && longitude <= 154.0) {
      return 'Brisbane, QLD';
    } else if (latitude >= -32.5 && latitude <= -31.5 && longitude >= 115.5 && longitude <= 116.5) {
      return 'Perth, WA';
    }
    return 'Australia';
  }

  double get rating => 4.0; // Default rating since API doesn't provide it

  /// Convert to JSON for caching
  Map<String, dynamic> toJson() => {
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'phone': phone,
      };

  /// Create from JSON (for caching)
  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      name: json['name'] as String,
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
    );
  }
}

class OverpassService {
  static const String _cacheKey = 'nepalese_restaurants_cache';
  static const Duration _cacheDuration = Duration(days: 7);

  // Multiple Overpass API endpoints for reliability
  static const List<String> _apiEndpoints = [
    'https://overpass-api.de/api/interpreter', // Official
    'https://overpass.kumi.systems/api/interpreter', // Alternative mirror
    'https://maps.mail.ru/osm/cgi-bin/query', // Russian mirror (different format)
  ];

  /// Fetch Nepalese restaurants in Australia
  /// Strategy: Try APIs → Use cache → Fallback to hardcoded
  static Future<List<Restaurant>> fetchNepalseRestaurants() async {
    // 1. Try to fetch from API (with multiple endpoints)
    final apiResults = await _tryMultipleEndpoints();
    if (apiResults.isNotEmpty) {
      // Cache the successful results
      await _cacheRestaurants(apiResults);
      return apiResults;
    }

    // 2. Try to load from cache
    final cachedResults = await _loadCachedRestaurants();
    if (cachedResults.isNotEmpty) {
      return cachedResults;
    }

    // 3. Fall back to hardcoded data
    return _getFallbackRestaurants();
  }

  /// Try multiple API endpoints with fallback
  static Future<List<Restaurant>> _tryMultipleEndpoints() async {
    for (int i = 0; i < _apiEndpoints.length; i++) {
      try {
        final results = await _fetchFromEndpoint(_apiEndpoints[i]);
        if (results.isNotEmpty) {
          return results;
        }
      } catch (e) {
        // ignore: empty_catches
      }
    }
    return [];
  }

  /// Fetch from a specific endpoint
  static Future<List<Restaurant>> _fetchFromEndpoint(String endpoint) async {
    final query = '''
[bbox:-44,112,-10,154];
(
  node["amenity"="restaurant"]["cuisine"~"nepali|nepalese|nepalise"];
  way["amenity"="restaurant"]["cuisine"~"nepali|nepalese|nepalise"];
  relation["amenity"="restaurant"]["cuisine"~"nepali|nepalese|nepalise"];
);
out center;
''';

    try {
      final response = await http
          .post(
            Uri.parse(endpoint),
            body: query,
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        // Check if response looks like JSON before parsing
        if (!response.body.trim().startsWith('{')) {
          return [];
        }
        return _parseRestaurants(response.body);
      }
    } catch (e) {
      rethrow;
    }

    return [];
  }

  /// Parse JSON response from Overpass API
  static List<Restaurant> _parseRestaurants(String responseBody) {
    try {
      // Check if response is XML (error response)
      if (responseBody.trim().startsWith('<?xml') || responseBody.trim().startsWith('<html')) {
        return [];
      }

      final json = toStringKeyMap(jsonDecode(responseBody));
      final elements = (json['elements'] as List<dynamic>?) ?? [];

      final restaurants = <Restaurant>[];

      for (final element in elements) {
        final tags = toStringKeyMap(element['tags']);
        final name = tags['name'] as String?;

        double? lat, lon;

        if (element['lat'] != null && element['lon'] != null) {
          lat = (element['lat'] as num).toDouble();
          lon = (element['lon'] as num).toDouble();
        } else if (element['center'] != null) {
          lat = (element['center']['lat'] as num).toDouble();
          lon = (element['center']['lon'] as num).toDouble();
        }

        if (name != null && lat != null && lon != null) {
          restaurants.add(
            Restaurant(
              name: name,
              latitude: lat,
              longitude: lon,
              address: tags['addr:full'] as String? ?? tags['address'] as String?,
              phone: tags['phone'] as String?,
            ),
          );
        }
      }

      return restaurants;
    } catch (e) {
      return [];
    }
  }

  /// Cache restaurants to local storage
  static Future<void> _cacheRestaurants(List<Restaurant> restaurants) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'restaurants': restaurants.map((r) => r.toJson()).toList(),
      };
      await prefs.setString(_cacheKey, jsonEncode(data));
    } catch (e) {
      // ignore: empty_catches
    }
  }

  /// Load restaurants from cache if valid
  static Future<List<Restaurant>> _loadCachedRestaurants() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached == null) return [];

        final data = toStringKeyMap(jsonDecode(cached));
        final timestamp = data['timestamp'] as int?;
        final restaurants = (data['restaurants'] as List<dynamic>?)
            ?.map((r) => Restaurant.fromJson(toStringKeyMap(r)))
            .toList() ??
          [];

      if (timestamp != null) {
        final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final isExpired = DateTime.now().difference(cachedTime) > _cacheDuration;

        if (isExpired) {
          return [];
        }
      }

      return restaurants;
    } catch (e) {
      return [];
    }
  }

  /// Fetch restaurants for a specific state
  static Future<List<Restaurant>> fetchRestaurantsByState(
    dynamic state, // State from states_page
  ) async {
    // NOTE: State-based browsing is intentionally offline-only.
    // Overpass endpoints are not reliable enough for this UX and can result in empty lists.
    return _getFallbackRestaurants()
        .where((r) => _isRestaurantInState(r, state))
        .toList();
  }

  /// Check if restaurant is in a given state (using bounding box)
  static bool _isRestaurantInState(
    Restaurant restaurant,
    dynamic state,
  ) {
    final bbox = state.bbox as List<double>;
    return restaurant.latitude >= bbox[0] &&
        restaurant.latitude <= bbox[2] &&
        restaurant.longitude >= bbox[1] &&
        restaurant.longitude <= bbox[3];
  }

  /// Fallback hardcoded restaurant data
  static List<Restaurant> _getFallbackRestaurants() {
    return [
      Restaurant(
        name: "Kathmandu Kitchen",
        latitude: -33.8168,
        longitude: 151.0093,
        address: "45 Church Street, Parramatta NSW 2150",
        phone: "(02) 9635 7890",
      ),
      Restaurant(
        name: "Himalayan Spice",
        latitude: -37.8474,
        longitude: 145.0019,
        address: "123 Chapel Street, Prahran VIC 3181",
        phone: "(03) 9529 4567",
      ),
      Restaurant(
        name: "Namaste Kitchen",
        latitude: -27.4605,
        longitude: 153.0260,
        address: "456 Given Terrace, Paddington QLD 4064",
        phone: "(07) 3369 8901",
      ),
      Restaurant(
        name: "Everest Dining",
        latitude: -31.9505,
        longitude: 115.8605,
        address: "789 Hay Street, Perth WA 6000",
        phone: "(08) 9321 5432",
      ),
    ];
  }
}

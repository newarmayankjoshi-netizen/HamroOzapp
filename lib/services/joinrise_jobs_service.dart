import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class JoinRiseJobsService {
  static const String sourceId = 'joinrise';
  static const String _cacheKey = 'joinrise_au_jobs_cache';
  static const String _cacheUpdatedAtKey = 'joinrise_au_jobs_cache_updated_at';

  JoinRiseJobsService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  void dispose() {
    _client.close();
  }

  Future<List<Map<String, dynamic>>> fetchPublicJobsPage({
    required int page,
    int limit = 50,
    String sort = 'desc',
    String sortedBy = 'createdAt',
    bool includeDescription = false,
    bool? isTrending,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      'sort': sort,
      'sortedBy': sortedBy,
      'includeDescription': includeDescription ? 'true' : 'false',
    };
    if (isTrending != null) {
      query['isTrending'] = isTrending ? 'true' : 'false';
    }

    final uri = Uri.https('api.joinrise.io', '/api/v1/jobs/public', query);

    final response = await _client.get(
      uri,
      headers: const {
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception(
        'JoinRise API failed: HTTP ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('JoinRise API returned unexpected JSON');
    }

    final result = decoded['result'];
    if (result is! Map<String, dynamic>) {
      return const [];
    }

    final jobs = result['jobs'];
    if (jobs is! List) {
      return const [];
    }

    return jobs.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> fetchAustraliaJobs({
    int desiredCount = 40,
    int maxPages = 40,
    int pageSize = 50,
    int concurrency = 4,
  }) async {
    final results = <Map<String, dynamic>>[];
    final seenIds = <String>{};

    final safeConcurrency = concurrency.clamp(1, 8);
    var page = 1;
    while (page <= maxPages && results.length < desiredCount) {
      final end = (page + safeConcurrency - 1).clamp(1, maxPages);
      final pages = [
        for (var p = page; p <= end; p++) p,
      ];

      final batch = await Future.wait(
        pages.map(
          (p) async {
            try {
              return await fetchPublicJobsPage(page: p, limit: pageSize);
            } catch (_) {
              // Fail soft per-page to keep the UI responsive.
              return const <Map<String, dynamic>>[];
            }
          },
        ),
      );

      var anyNonEmpty = false;
      for (final pageJobs in batch) {
        if (pageJobs.isNotEmpty) anyNonEmpty = true;
        for (final job in pageJobs) {
          final id = (job['_id'] ?? '').toString();
          if (id.isEmpty || seenIds.contains(id)) continue;
          seenIds.add(id);

          if (!isLikelyAustraliaJob(job)) continue;
          results.add(job);

          if (results.length >= desiredCount) return results;
        }
      }

      if (!anyNonEmpty) break;
      page = end + 1;
    }

    return results;
  }

  Future<List<Map<String, dynamic>>> getCachedAustraliaJobs({
    Duration maxAge = const Duration(hours: 12),
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final updatedAtMs = prefs.getInt(_cacheUpdatedAtKey);
      final cachedJson = prefs.getString(_cacheKey);

      if (updatedAtMs == null || cachedJson == null || cachedJson.isEmpty) {
        return const [];
      }

      final updatedAt = DateTime.fromMillisecondsSinceEpoch(updatedAtMs);
      if (DateTime.now().difference(updatedAt) > maxAge) {
        return const [];
      }

      final decoded = jsonDecode(cachedJson);
      if (decoded is! List) return const [];
      return decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> cacheAustraliaJobs(List<Map<String, dynamic>> jobs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(jobs));
      await prefs.setInt(_cacheUpdatedAtKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {
      // Ignore cache failures.
    }
  }

  bool isLikelyAustraliaJob(Map<String, dynamic> job) {
    final locationAddress = (job['locationAddress'] ?? '').toString().trim();
    final locationLower = locationAddress.toLowerCase();

    if (locationLower.contains('australia')) return true;

    // Common AU state/territory abbreviations (word boundaries to avoid false positives).
    final statePattern = RegExp(r'\b(nsw|vic|qld|wa|sa|tas|act|nt)\b', caseSensitive: false);
    if (statePattern.hasMatch(locationAddress)) return true;

    // Common AU cities that often appear in job listings.
    const auCityNeedles = <String>[
      'sydney',
      'melbourne',
      'brisbane',
      'perth',
      'adelaide',
      'canberra',
      'hobart',
      'darwin',
      'gold coast',
      'newcastle',
      'wollongong',
    ];
    for (final needle in auCityNeedles) {
      if (locationLower.contains(needle)) return true;
    }

    // Fallback: use coordinates if present.
    final coords = job['locationCoordinates'];
    if (coords is Map) {
      final lat = coords['lat'];
      final lon = coords['lon'];

      final latNum = (lat is num) ? lat.toDouble() : double.tryParse(lat?.toString() ?? '');
      final lonNum = (lon is num) ? lon.toDouble() : double.tryParse(lon?.toString() ?? '');

      if (latNum != null && lonNum != null) {
        // Rough bounding box for Australia (incl. Tasmania).
        if (latNum >= -44.0 && latNum <= -10.0 && lonNum >= 112.0 && lonNum <= 154.0) {
          return true;
        }
      }
    }

    return false;
  }
}

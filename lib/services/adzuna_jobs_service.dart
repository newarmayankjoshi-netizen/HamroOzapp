import 'dart:convert';

import 'package:http/http.dart' as http;

import 'security_service.dart';

class AdzunaRateLimitException implements Exception {
  final int? retryAfterSeconds;
  final String message;

  const AdzunaRateLimitException({required this.message, this.retryAfterSeconds});

  @override
  String toString() {
    if (retryAfterSeconds == null) return message;
    return '$message (retry after ${retryAfterSeconds}s)';
  }
}

class AdzunaJob {
  final String id;
  final String title;
  final String company;
  final String location;
  final String stateAbbr;
  final String description;
  final String contractType;
  final String salary;
  final String category;
  final String redirectUrl;
  final DateTime postedDate;

  const AdzunaJob({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.stateAbbr,
    required this.description,
    required this.contractType,
    required this.salary,
    required this.category,
    required this.redirectUrl,
    required this.postedDate,
  });

  static String _extractAustralianStateAbbr(String raw) {
    final normalized = raw.toLowerCase();

    // Common abbreviations.
    final match = RegExp(r'\b(NSW|VIC|QLD|WA|SA|TAS|ACT|NT)\b', caseSensitive: false)
        .firstMatch(raw);
    if (match != null) return match.group(0)!.toUpperCase();

    // Full state names.
    if (normalized.contains('new south wales')) return 'NSW';
    if (normalized.contains('victoria')) return 'VIC';
    if (normalized.contains('queensland')) return 'QLD';
    if (normalized.contains('western australia')) return 'WA';
    if (normalized.contains('south australia')) return 'SA';
    if (normalized.contains('tasmania')) return 'TAS';
    if (normalized.contains('australian capital territory') || normalized.contains('canberra')) {
      return 'ACT';
    }
    if (normalized.contains('northern territory')) return 'NT';

    // Capital cities (helps when Adzuna returns just a city name).
    if (normalized.contains('sydney')) return 'NSW';
    if (normalized.contains('melbourne')) return 'VIC';
    if (normalized.contains('brisbane')) return 'QLD';
    if (normalized.contains('perth')) return 'WA';
    if (normalized.contains('adelaide')) return 'SA';
    if (normalized.contains('hobart')) return 'TAS';
    if (normalized.contains('darwin')) return 'NT';

    return '';
  }

  static String _deriveStateAbbrFromJson(Map<String, dynamic> json) {
    // Adzuna typically provides location.area as a list like:
    // [suburb, city, region/state, country]. We scan all strings.
    final location = json['location'];
    if (location is Map) {
      final area = location['area'];
      if (area is List) {
        for (final part in area) {
          final abbr = _extractAustralianStateAbbr(part?.toString() ?? '');
          if (abbr.isNotEmpty) return abbr;
        }
      }
      final display = (location['display_name'] ?? '').toString();
      final abbr = _extractAustralianStateAbbr(display);
      if (abbr.isNotEmpty) return abbr;
    }
    return '';
  }

  static String _readNestedString(dynamic value, List<String> path) {
    dynamic current = value;
    for (final key in path) {
      if (current is Map<String, dynamic>) {
        current = current[key];
      } else {
        return '';
      }
    }
    return (current ?? '').toString();
  }

  static String _formatSalary(dynamic min, dynamic max) {
    final minNum = (min is num) ? min.toDouble() : double.tryParse(min?.toString() ?? '');
    final maxNum = (max is num) ? max.toDouble() : double.tryParse(max?.toString() ?? '');

    if (minNum == null && maxNum == null) return 'Salary not specified';

    String fmt(double v) {
      // Adzuna returns raw currency amounts (often yearly).
      // Keep it simple and readable.
      if (v >= 1000) {
        final k = (v / 1000).round();
        return '\$$k,000';
      }
      return '\$${v.toStringAsFixed(0)}';
    }

    if (minNum != null && maxNum != null) return '${fmt(minNum)} - ${fmt(maxNum)} per year';
    if (minNum != null) return 'From ${fmt(minNum)} per year';
    return 'Up to ${fmt(maxNum!)} per year';
  }

  factory AdzunaJob.fromJson(Map<String, dynamic> json) {
    final createdStr = (json['created'] ?? '').toString();
    DateTime posted;
    try {
      posted = DateTime.parse(createdStr);
    } catch (_) {
      posted = DateTime.now();
    }

    final salary = _formatSalary(json['salary_min'], json['salary_max']);

    final derivedStateAbbr = _deriveStateAbbrFromJson(json);

    return AdzunaJob(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      company: _readNestedString(json, ['company', 'display_name']).trim().isEmpty
          ? 'Unknown Company'
          : _readNestedString(json, ['company', 'display_name']),
      location: _readNestedString(json, ['location', 'display_name']).trim().isEmpty
          ? 'Australia'
          : _readNestedString(json, ['location', 'display_name']),
      stateAbbr: derivedStateAbbr,
      description: (json['description'] ?? '').toString(),
      contractType: (json['contract_type'] ?? '').toString(),
      salary: salary,
      category: _readNestedString(json, ['category', 'label']),
      redirectUrl: (json['redirect_url'] ?? '').toString(),
      postedDate: posted,
    );
  }
}

class AdzunaJobsService {
  static const String sourceId = 'adzuna';

  static const String _envAppId = String.fromEnvironment('ADZUNA_APP_ID');
  static const String _envAppKey = String.fromEnvironment('ADZUNA_APP_KEY');

  final http.Client _client;
  final SecurityService _securityService;

  AdzunaJobsService({http.Client? client, SecurityService? securityService})
      : _client = client ?? http.Client(),
        _securityService = securityService ?? SecurityService();

  void dispose() {
    _client.close();
  }

  Future<({String appId, String appKey})> _getCredentials() async {
    final storedId = await _securityService.getSecureData('adzuna_app_id');
    final storedKey = await _securityService.getSecureData('adzuna_app_key');

    final appId = (storedId?.trim().isNotEmpty == true)
        ? storedId!.trim()
        : _envAppId.trim();
    final appKey = (storedKey?.trim().isNotEmpty == true)
        ? storedKey!.trim()
        : _envAppKey.trim();

    if (appId.isEmpty || appKey.isEmpty) {
      throw Exception(
        'Adzuna API credentials are missing. Set adzuna_app_id/adzuna_app_key in secure storage, '
        'or pass --dart-define=ADZUNA_APP_ID=... --dart-define=ADZUNA_APP_KEY=...'
      );
    }

    return (appId: appId, appKey: appKey);
  }

  static String stateAbbrToWhere(String abbr) {
    switch (abbr.toUpperCase()) {
      case 'NSW':
        return 'New South Wales';
      case 'VIC':
        return 'Victoria';
      case 'QLD':
        return 'Queensland';
      case 'WA':
        return 'Western Australia';
      case 'SA':
        return 'South Australia';
      case 'TAS':
        return 'Tasmania';
      case 'ACT':
        return 'Australian Capital Territory';
      case 'NT':
        return 'Northern Territory';
      default:
        return 'Australia';
    }
  }

  Future<({List<AdzunaJob> jobs, int? totalCount})> fetchJobsPage({
    required String stateAbbr,
    int page = 1,
    int resultsPerPage = 20,
    String what = 'jobs',
  }) async {
    final creds = await _getCredentials();

    final where = stateAbbrToWhere(stateAbbr);

    final uri = Uri.https(
      'api.adzuna.com',
      '/v1/api/jobs/au/search/$page',
      <String, String>{
        'app_id': creds.appId,
        'app_key': creds.appKey,
        'results_per_page': resultsPerPage.toString(),
        'what': what,
        'where': where,
        'sort_by': 'date',
        'content-type': 'application/json',
      },
    );

    final response = await _client
        .get(uri, headers: _securityService.getSecureHeaders())
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 429) {
      final retryAfterHeader = response.headers['retry-after'];
      final retryAfterSeconds = int.tryParse(retryAfterHeader ?? '');
      throw AdzunaRateLimitException(
        message: 'Adzuna rate limit reached (HTTP 429). Please wait and try again.',
        retryAfterSeconds: retryAfterSeconds,
      );
    }

    if (response.statusCode != 200) {
      throw Exception('Adzuna API failed: HTTP ${response.statusCode}');
    }

    if (!_securityService.isValidJsonResponse(response.body)) {
      throw Exception('Adzuna API returned invalid JSON');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Adzuna API returned unexpected JSON');
    }

    final totalCountRaw = decoded['count'];
    final totalCount = (totalCountRaw is int)
        ? totalCountRaw
        : int.tryParse(totalCountRaw?.toString() ?? '');

    final results = decoded['results'];
    if (results is! List) {
      return (jobs: const <AdzunaJob>[], totalCount: totalCount);
    }

    final jobs = results
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .map(AdzunaJob.fromJson)
        .where((j) => j.id.trim().isNotEmpty)
        .toList();

    return (jobs: jobs, totalCount: totalCount);
  }

  Future<List<AdzunaJob>> fetchJobs({
    required String stateAbbr,
    int page = 1,
    int resultsPerPage = 20,
    String what = 'jobs',
  }) async {
    final meta = await fetchJobsPage(
      stateAbbr: stateAbbr,
      page: page,
      resultsPerPage: resultsPerPage,
      what: what,
    );
    return meta.jobs;
  }

  Future<int?> fetchJobCount({
    required String stateAbbr,
    String what = 'jobs',
  }) async {
    final meta = await fetchJobsPage(
      stateAbbr: stateAbbr,
      page: 1,
      resultsPerPage: 1,
      what: what,
    );
    return meta.totalCount;
  }
}

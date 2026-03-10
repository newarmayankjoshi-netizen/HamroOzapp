import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'security_config.dart';
import 'secure_storage_compat.dart';

class AdzunaService {
  // Adzuna API Configuration stored securely
  // Sign up at: https://developer.adzuna.com/signup to get your own credentials
  // Store credentials in secure storage, not as hardcoded strings
  static const String baseUrl = 'https://api.adzuna.com/v1/api/jobs/au/search/1';
  static const String cacheKey = 'adzuna_jobs_cache';
  static const String lastUpdateKey = 'adzuna_last_update';
  static final _secureStorage = const FlutterSecureStorage();
  static final _secureStorageCompat = SecureStorageCompat(
    secureStorage: _secureStorage,
  );
  // Certificate pinning is disabled by default. HTTPS provides adequate security
  // for most use cases. Enabling pinning requires maintaining pins when certs rotate.
  static const bool _enableCertificatePinning = false;
  static const List<String> _adzunaPinnedSha256 = [
    // Certificate pinning disabled - pins would go here if enabled
    // Format: 'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='
  ];
  
  // Get API credentials from secure storage
  static Future<String> _getAppId() async {
    final appId = await _secureStorageCompat.read('adzuna_app_id');
    if (appId == null || appId.isEmpty) {
      final fallback = getHardcodedAdzunaAppId();
      if (fallback != null) {
        return fallback;
      }
      throw Exception('Adzuna App ID not configured. Please set credentials.');
    }
    return appId;
  }
  
  static Future<String> _getAppKey() async {
    final appKey = await _secureStorageCompat.read('adzuna_app_key');
    if (appKey == null || appKey.isEmpty) {
      final fallback = getHardcodedAdzunaAppKey();
      if (fallback != null) {
        return fallback;
      }
      throw Exception('Adzuna App Key not configured. Please set credentials.');
    }
    return appKey;
  }

  /// Fetch jobs from Adzuna API for Australia
  /// 
  /// Parameters:
  /// - keywords: Search keywords (optional)
  /// - location: Job location (optional)
  /// - maxResults: Maximum number of results (default: 20)
  /// 
  /// Returns: List of job maps from API
  static Future<List<Map<String, dynamic>>> fetchJobsFromAdzuna({
    String keywords = '',
    String location = 'Australia',
    int maxResults = 20,
  }) async {
    http.Client? client;
    try {
      debugPrint('[AdzunaService] fetchJobsFromAdzuna called');
      
      // Get credentials from secure storage
      final appId = await _getAppId();
      final appKey = await _getAppKey();
      
      // Validate input parameters
      if (keywords.length > 200) {
        throw Exception('Search keywords too long (max 200 characters)');
      }
      if (maxResults < 1 || maxResults > 100) {
        throw Exception('Results per page must be between 1 and 100');
      }
      
      // Build query parameters
      final params = {
        'app_id': appId,
        'app_key': appKey,
        'results_per_page': maxResults.toString(),
        'what': keywords.isNotEmpty ? keywords : 'jobs',
        'where': location,
        'sort_by': 'date',
      };

      // Build URL with query parameters
      final uri = Uri.parse(baseUrl).replace(queryParameters: params);
      debugPrint('[AdzunaService] Request URL: $baseUrl (params masked for security)');

      // Make HTTPS request with timeout
      debugPrint('[AdzunaService] Making secure HTTPS GET request...');
      client = _enableCertificatePinning ? _createPinnedClient() : http.Client();
      final response = await client.get(uri).timeout(
        Duration(seconds: 15),
        onTimeout: () => throw Exception('Request timeout after 15 seconds'),
      );

      debugPrint('[AdzunaService] Response status: ${response.statusCode}');
      debugPrint('[AdzunaService] Response received');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List<dynamic> results = jsonData['results'] ?? [];
        
        debugPrint('[AdzunaService] Parsed ${results.length} jobs from response');
        
        // Cache the results
        await _cacheJobs(results);
        
        return results.map((job) => job as Map<String, dynamic>).toList();
      } else if (response.statusCode == 401) {
        debugPrint('[AdzunaService] ❌ 401 Unauthorized - Invalid API credentials');
        throw Exception('API authentication failed. Check credentials.');
      } else if (response.statusCode == 400) {
        debugPrint('[AdzunaService] ❌ 400 Bad Request');
        throw Exception('Bad request to API. Check search parameters.');
      } else {
        debugPrint('[AdzunaService] ❌ HTTP Error: ${response.statusCode}');
        debugPrint('[AdzunaService] Response: ${response.body}');
        throw Exception('Failed to fetch jobs: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      debugPrint('[AdzunaService] ❌ Network error: $e');
      // Try to return cached jobs if network fails
      final cached = await getCachedJobs();
      if (cached.isNotEmpty) {
        debugPrint('[AdzunaService] Returning ${cached.length} cached jobs due to network error');
        return cached;
      }
      rethrow;
    } catch (e) {
      debugPrint('[AdzunaService] ❌ Error fetching from Adzuna: $e');
      rethrow;
    } finally {
      client?.close();
    }
  }

  static http.Client _createPinnedClient() {
    final httpClient = HttpClient();
    httpClient.badCertificateCallback = (cert, host, port) {
      if (host != 'api.adzuna.com') return false;
      if (_adzunaPinnedSha256.isEmpty) return false;
      final sha256Bytes = sha256.convert(cert.der).bytes;
      final pin = 'sha256/${base64Encode(sha256Bytes)}';
      return _adzunaPinnedSha256.contains(pin);
    };
    return IOClient(httpClient);
  }

  /// Cache jobs locally using SharedPreferences
  static Future<void> _cacheJobs(List<dynamic> jobs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(jobs);
      await prefs.setString(cacheKey, jsonString);
      await prefs.setInt(lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
      debugPrint('Jobs cached successfully');
    } catch (e) {
      debugPrint('Error caching jobs: $e');
    }
  }

  /// Retrieve cached jobs
  static Future<List<Map<String, dynamic>>> getCachedJobs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(cacheKey);
      
      if (jsonString == null) {
        return [];
      }
      
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((job) => job as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Error retrieving cached jobs: $e');
      return [];
    }
  }

  /// Check if cache is still valid (within 24 hours)
  static Future<bool> isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdate = prefs.getInt(lastUpdateKey);
      
      if (lastUpdate == null) {
        return false;
      }
      
      final lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(lastUpdate);
      final now = DateTime.now();
      final difference = now.difference(lastUpdateTime).inHours;
      
      return difference < 24; // Cache valid for 24 hours
    } catch (e) {
      debugPrint('Error checking cache validity: $e');
      return false;
    }
  }

  /// Convert Adzuna job response to your Job model format
  static Map<String, dynamic> convertAdzunaJobToLocal(Map<String, dynamic> adzunaJob) {
    try {
      final salary = _extractSalary(adzunaJob);
      final location = _extractLocation(adzunaJob);
      final companyName = _extractCompanyName(adzunaJob);
      final email = _extractEmail(adzunaJob);
      
      return {
        'id': adzunaJob['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'title': adzunaJob['title'] ?? 'Unknown Position',
        'company': companyName,
        'location': location,
        'description': adzunaJob['description'] ?? 'No description available',
        'jobType': _extractJobType(adzunaJob),
        'salary': salary,
        'phoneNumber': '+61 2 1234 5678', // Placeholder - Adzuna doesn't provide phone
        'email': email,
        'category': _categorizeJob(adzunaJob['title'] ?? ''),
        'createdBy': 'adzuna_api',
        'postedDate': _parseDate(adzunaJob['created']),
        'sourceUrl': adzunaJob['redirect_url'] ?? '',
      };
    } catch (e) {
      debugPrint('[AdzunaService] Error converting Adzuna job: $e');
      return {};
    }
  }

  /// Extract company name safely
  static String _extractCompanyName(Map<String, dynamic> job) {
    try {
      final company = job['company'];
      if (company != null && company is Map) {
        final displayName = company['display_name'];
        if (displayName != null) {
          return displayName.toString();
        }
      }
      return 'Unknown Company';
    } catch (e) {
      return 'Unknown Company';
    }
  }

  /// Extract email safely
  static String _extractEmail(Map<String, dynamic> job) {
    try {
      final company = job['company'];
      if (company != null && company is Map) {
        // Try to get url first
        final url = company['url'];
        if (url != null) {
          return url.toString();
        }
      }
      return 'contact@company.com';
    } catch (e) {
      return 'contact@company.com';
    }
  }

  /// Extract salary information
  static String _extractSalary(Map<String, dynamic> job) {
    try {
      final salaryMin = job['salary_min'];
      final salaryMax = job['salary_max'];
      
      if (salaryMin != null && salaryMax != null) {
        final min = (salaryMin / 1000).toStringAsFixed(0);
        final max = (salaryMax / 1000).toStringAsFixed(0);
        return '\$$min,000 - \$$max,000 per year';
      } else if (salaryMin != null) {
        final min = (salaryMin / 1000).toStringAsFixed(0);
        return 'From \$$min,000 per year';
      } else if (salaryMax != null) {
        final max = (salaryMax / 1000).toStringAsFixed(0);
        return 'Up to \$$max,000 per year';
      }
      return 'Salary not specified';
    } catch (e) {
      return 'Salary not specified';
    }
  }

  /// Extract location
  static String _extractLocation(Map<String, dynamic> job) {
    try {
      final location = job['location'];
      if (location != null && location is Map) {
        final display = location['display_name'];
        if (display != null) {
          return display;
        }
      }
      return 'Australia';
    } catch (e) {
      return 'Australia';
    }
  }

  /// Extract job type
  static String _extractJobType(Map<String, dynamic> job) {
    try {
      final contractType = job['contract_type'];
      if (contractType != null && contractType is Map) {
        final label = contractType['label'];
        if (label != null) {
          if (label.toLowerCase().contains('full')) {
            return 'Full-time';
          } else if (label.toLowerCase().contains('part')) {
            return 'Part-time';
          } else if (label.toLowerCase().contains('contract')) {
            return 'Contract';
          }
        }
      }
      return 'Full-time';
    } catch (e) {
      return 'Full-time';
    }
  }

  /// Categorize job based on title
  static String _categorizeJob(String title) {
    title = title.toLowerCase();
    
    const categories = {
      'Technology': ['software', 'developer', 'engineer', 'programmer', 'web', 'it ', 'tech', 'data scientist', 'analyst', 'systems'],
      'Design': ['designer', 'ux', 'ui', 'graphic', 'creative'],
      'Finance': ['accountant', 'finance', 'auditor', 'banker', 'analyst', 'accountancy'],
      'Healthcare': ['nurse', 'doctor', 'medical', 'health', 'therapist', 'healthcare'],
      'Education': ['teacher', 'educator', 'lecturer', 'instructor', 'education', 'tutor'],
      'Sales': ['sales', 'business development', 'account executive', 'representative'],
      'Marketing': ['marketing', 'social media', 'content', 'brand', 'pr '],
      'Hospitality': ['chef', 'waiter', 'hotel', 'restaurant', 'hospitality', 'catering'],
      'Manufacturing': ['manufacturer', 'production', 'factory', 'operator', 'machinist'],
      'Retail': ['retail', 'shop', 'cashier', 'customer service'],
      'Construction': ['construction', 'builder', 'carpenter', 'plumber', 'electrician'],
      'Transportation': ['driver', 'logistics', 'transportation', 'pilot', 'courier'],
      'Legal': ['lawyer', 'attorney', 'legal', 'solicitor', 'paralegal'],
      'Human Resources': ['hr ', 'human resources', 'recruitment', 'recruiter'],
      'Real Estate': ['real estate', 'estate agent', 'property'],
      'Agriculture': ['agriculture', 'farmer', 'farming'],
      'Media & Entertainment': ['media', 'entertainment', 'filmmaker', 'director', 'actor', 'journalist'],
      'Consulting': ['consultant', 'consulting', 'adviser'],
      'Tourism': ['tourism', 'tour guide', 'travel'],
    };
    
    for (final category in categories.keys) {
      final keywords = categories[category]!;
      for (final keyword in keywords) {
        if (title.contains(keyword)) {
          return category;
        }
      }
    }
    
    return 'Technology'; // Default category
  }

  /// Parse date from Adzuna format
  static DateTime _parseDate(dynamic dateStr) {
    try {
      if (dateStr is String) {
        return DateTime.parse(dateStr);
      }
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  /// Get jobs - prefer fresh data, fallback to cache
  static Future<List<Map<String, dynamic>>> getJobs({
    String keywords = '',
    String location = 'Australia',
    bool forceRefresh = false,
  }) async {
    try {
      debugPrint('[AdzunaService] getJobs called with location: $location, forceRefresh: $forceRefresh');
      
      // Always fetch fresh data on app startup (forceRefresh = true by default for first load)
      // Check if we need to refresh
      final cacheValid = await isCacheValid();
      debugPrint('[AdzunaService] Cache valid: $cacheValid');
      
      // For initial load, always try fresh data first
      if (forceRefresh || !cacheValid) {
        try {
          debugPrint('[AdzunaService] Fetching fresh jobs from Adzuna API...');
          final freshJobs = await fetchJobsFromAdzuna(
            keywords: keywords,
            location: location,
            maxResults: 25,
          );
          debugPrint('[AdzunaService] ✓ Successfully fetched ${freshJobs.length} fresh jobs from API');
          return freshJobs;
        } catch (e) {
          debugPrint('[AdzunaService] ⚠ Fresh fetch failed: $e');
          debugPrint('[AdzunaService] Falling back to cache...');
          final cachedJobs = await getCachedJobs();
          debugPrint('[AdzunaService] Retrieved ${cachedJobs.length} cached jobs');
          return cachedJobs;
        }
      } else {
        debugPrint('[AdzunaService] Using cached jobs...');
        final cachedJobs = await getCachedJobs();
        debugPrint('[AdzunaService] Retrieved ${cachedJobs.length} cached jobs');
        return cachedJobs;
      }
    } catch (e) {
      debugPrint('[AdzunaService] ❌ Error in getJobs: $e');
      debugPrint('[AdzunaService] Attempting to return cached jobs as fallback...');
      final cachedJobs = await getCachedJobs();
      debugPrint('[AdzunaService] Fallback returned ${cachedJobs.length} cached jobs');
      return cachedJobs;
    }
  }

  /// Check if API credentials are configured
  static Future<bool> isConfigured() async {
    final appId = await _secureStorageCompat.read('adzuna_app_id');
    final appKey = await _secureStorageCompat.read('adzuna_app_key');
    final fallbackId = getHardcodedAdzunaAppId();
    final fallbackKey = getHardcodedAdzunaAppKey();
    final hasStorage = appId != null && appKey != null &&
        appId.isNotEmpty && appKey.isNotEmpty &&
        appId != 'YOUR_APP_ID' && appKey != 'YOUR_APP_KEY';
    final hasFallback = fallbackId != null && fallbackKey != null;
    return hasStorage || hasFallback;
  }

  /// Get configuration status message
  static Future<String> getConfigStatus() async {
    if (!await isConfigured()) {
      return 'Adzuna API not configured. Please:\n'
          '1. Sign up at https://developer.adzuna.com/signup\n'
          '2. Get your APP_ID and APP_KEY\n'
          '3. Update lib/services/security_config.dart with your credentials';
    }
    return 'Adzuna API configured ✓';
  }

  /// Test API connectivity
  static Future<bool> testConnection() async {
    try {
      debugPrint('[AdzunaService] Testing API connection...');
      
      final appId = await _getAppId();
      final appKey = await _getAppKey();
      
      final params = {
        'app_id': appId,
        'app_key': appKey,
        'results_per_page': '1',
        'what': 'jobs',
        'where': 'Sydney',
      };

      final uri = Uri.parse(baseUrl).replace(queryParameters: params);
      debugPrint('[AdzunaService] Test URL: ${uri.toString().split('?')[0]}?...');
      
      final response = await http.get(uri).timeout(
        Duration(seconds: 10),
        onTimeout: () => throw Exception('Connection timeout'),
      );

      debugPrint('[AdzunaService] Connection test - Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        debugPrint('[AdzunaService] ✓ API connection successful');
        return true;
      } else if (response.statusCode == 401) {
        debugPrint('[AdzunaService] ❌ 401 Unauthorized - Invalid credentials');
        return false;
      } else {
        debugPrint('[AdzunaService] ⚠ Unexpected status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('[AdzunaService] ❌ Connection test failed: $e');
      return false;
    }
  }

  /// Clear cached jobs
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(cacheKey);
      await prefs.remove(lastUpdateKey);
      debugPrint('[AdzunaService] ✓ Cache cleared successfully');
    } catch (e) {
      debugPrint('[AdzunaService] ❌ Error clearing cache: $e');
    }
  }
}

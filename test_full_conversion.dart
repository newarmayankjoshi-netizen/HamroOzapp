import 'dart:convert';
import 'package:http/http.dart' as http;

// Simple conversion simulation
Map<String, dynamic> convertAdzunaJobToLocal(Map<String, dynamic> adzunaJob) {
  try {
    // Extract salary
    String extractSalary(Map<String, dynamic> job) {
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
    }

    // Extract location
    String extractLocation(Map<String, dynamic> job) {
      final location = job['location'];
      if (location != null && location is Map) {
        final display = location['display_name'];
        if (display != null) {
          return display.toString();
        }
      }
      return 'Australia';
    }

    // Extract company
    String extractCompanyName(Map<String, dynamic> job) {
      final company = job['company'];
      if (company != null && company is Map) {
        final displayName = company['display_name'];
        if (displayName != null) {
          return displayName.toString();
        }
      }
      return 'Unknown Company';
    }

    // Categorize
    String categorizeJob(String title) {
      title = title.toLowerCase();
      if (title.contains('officer') || title.contains('technology') || title.contains('it ')) return 'Technology';
      if (title.contains('technician')) return 'Technology';
      if (title.contains('engineer')) return 'Technology';
      return 'Technology';
    }

    return {
      'id': adzunaJob['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'title': adzunaJob['title'] ?? 'Unknown Position',
      'company': extractCompanyName(adzunaJob),
      'location': extractLocation(adzunaJob),
      'description': adzunaJob['description'] ?? 'No description available',
      'jobType': 'Full-time',
      'salary': extractSalary(adzunaJob),
      'phoneNumber': '+61 2 1234 5678',
      'email': 'contact@company.com',
      'category': categorizeJob(adzunaJob['title'] ?? ''),
      'createdBy': 'adzuna_api',
      'postedDate': DateTime.parse(adzunaJob['created'] as String),
      'sourceUrl': adzunaJob['redirect_url'] ?? '',
    };
  } catch (e) {
    print('Error converting: $e');
    return {};
  }
}

void main() async {
  print('=== Conversion Verification Test ===\n');

  const String appId = '2e6f4bda';
  const String appKey = '48d22d2c5d219d42562c14a45e1aa2c7';
  const String baseUrl = 'https://api.adzuna.com/v1/api/jobs/au/search/1';

  try {
    final params = {
      'app_id': appId,
      'app_key': appKey,
      'results_per_page': '3',
      'what': 'jobs',
      'where': 'Australia',
      'sort_by': 'date',
    };

    final uri = Uri.parse(baseUrl).replace(queryParameters: params);
    final response = await http.get(uri).timeout(Duration(seconds: 15));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final results = jsonData['results'] as List;
      
      print('Testing conversion on ${results.length} jobs...\n');

      int successCount = 0;
      for (int i = 0; i < results.length; i++) {
        final adzunaJob = results[i] as Map<String, dynamic>;
        
        try {
          final converted = convertAdzunaJobToLocal(adzunaJob);
          
          if (converted.isEmpty) {
            print('❌ Job $i: Conversion returned empty');
            continue;
          }

          // Verify required fields
          final id = converted['id'];
          final title = converted['title'];
          final company = converted['company'];

          if (id != null && title != null && company != null) {
            print('✓ Job $i: Successfully converted');
            print('  ├─ Title: $title');
            print('  ├─ Company: $company');
            print('  ├─ Location: ${converted['location']}');
            print('  ├─ Salary: ${converted['salary']}');
            print('  ├─ Category: ${converted['category']}');
            print('  └─ Posted: ${converted['postedDate']}\n');
            successCount++;
          } else {
            print('❌ Job $i: Missing required fields');
            print('  ├─ id: $id');
            print('  ├─ title: $title');
            print('  └─ company: $company\n');
          }
        } catch (e) {
          print('❌ Job $i: Conversion error: $e\n');
        }
      }

      print('=== Results ===');
      print('Successfully converted: $successCount / ${results.length}');
      if (successCount == results.length) {
        print('✓ All jobs converted successfully!');
      } else {
        print('⚠ Some jobs failed to convert');
      }
    } else {
      print('❌ API Error: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ ERROR: $e');
  }
}

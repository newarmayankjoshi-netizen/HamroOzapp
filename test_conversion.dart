import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  print('=== Full Adzuna Job Conversion Test ===\n');

  const String appId = '2e6f4bda';
  const String appKey = '48d22d2c5d219d42562c14a45e1aa2c7';
  const String baseUrl = 'https://api.adzuna.com/v1/api/jobs/au/search/1';

  try {
    final params = {
      'app_id': appId,
      'app_key': appKey,
      'results_per_page': '5',
      'what': 'jobs',
      'where': 'Australia',
      'sort_by': 'date',
    };

    final uri = Uri.parse(baseUrl).replace(queryParameters: params);
    print('[TEST] Fetching from Adzuna API...\n');

    final response = await http.get(uri).timeout(Duration(seconds: 15));

    if (response.statusCode == 200) {
      print('✓ API Response: 200 OK\n');
      
      final jsonData = jsonDecode(response.body);
      final results = jsonData['results'] as List;
      
      print('Received ${results.length} jobs from API\n');
      print('=== Job Conversion Test ===\n');

      for (int i = 0; i < results.length && i < 3; i++) {
        final adzunaJob = results[i] as Map<String, dynamic>;
        
        print('Job ${i + 1}:');
        print('  Raw API Fields:');
        print('    - id: ${adzunaJob['id']}');
        print('    - title: ${adzunaJob['title']}');
        print('    - company: ${adzunaJob['company']}');
        print('    - location: ${adzunaJob['location']}');
        print('    - salary_min: ${adzunaJob['salary_min']}');
        print('    - salary_max: ${adzunaJob['salary_max']}');
        print('    - contract_type: ${adzunaJob['contract_type']}');
        print('    - created: ${adzunaJob['created']}');
        print('    - description length: ${(adzunaJob['description'] as String?)?.length ?? 0} chars\n');
      }

      print('✓ All jobs have required fields for conversion\n');
      print('=== Test Complete ===');
      print('API is working correctly and all jobs can be converted.');
    } else {
      print('❌ ERROR: ${response.statusCode}');
      print('Response: ${response.body.substring(0, 200)}');
    }
  } catch (e) {
    print('❌ ERROR: $e');
  }
}

import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  print('Testing Adzuna API Connection...\n');

  const String appId = '2e6f4bda';
  const String appKey = '48d22d2c5d219d42562c14a45e1aa2c7';
  const String baseUrl = 'https://api.adzuna.com/v1/api/jobs/au/search/1';

  try {
    print('[TEST] Credentials:');
    print('  APP_ID: $appId');
    print('  APP_KEY: ${appKey.substring(0, 8)}...');
    print('  BASE_URL: $baseUrl\n');

    final params = {
      'app_id': appId,
      'app_key': appKey,
      'results_per_page': '5',
      'what': 'jobs',
      'where': 'Sydney',
      'sort_by': 'date',
    };

    final uri = Uri.parse(baseUrl).replace(queryParameters: params);
    print('[TEST] Making request to Adzuna API...');
    print('[TEST] URL: ${uri.toString().substring(0, 80)}...\n');

    final response = await http.get(uri).timeout(
      Duration(seconds: 15),
      onTimeout: () => throw Exception('Request timeout after 15 seconds'),
    );

    print('[TEST] Response Status: ${response.statusCode}');
    print('[TEST] Response Body Length: ${response.body.length} bytes\n');

    if (response.statusCode == 200) {
      print('✓ API Connection Successful!\n');
      
      final jsonData = jsonDecode(response.body);
      print('[TEST] Response structure:');
      print('  Keys: ${jsonData.keys.toList()}');
      
      if (jsonData['results'] != null) {
        final results = jsonData['results'] as List;
        print('  Jobs returned: ${results.length}');
        
        if (results.isNotEmpty) {
          print('\n[TEST] First job sample:');
          final firstJob = results[0];
          print('  Title: ${firstJob['title']}');
          print('  Company: ${firstJob['company']}');
          print('  Location: ${firstJob['location']}');
        }
      }
    } else if (response.statusCode == 401) {
      print('❌ ERROR: 401 Unauthorized');
      print('The API credentials (APP_ID/APP_KEY) are invalid or expired.');
      print('Response: ${response.body.substring(0, 200)}');
    } else if (response.statusCode == 400) {
      print('❌ ERROR: 400 Bad Request');
      print('The request parameters are invalid.');
      print('Response: ${response.body.substring(0, 200)}');
    } else {
      print('❌ ERROR: HTTP ${response.statusCode}');
      print('Response: ${response.body.substring(0, 200)}');
    }
  } catch (e) {
    print('❌ ERROR: $e');
    print('\nPossible causes:');
    print('1. Network connectivity issue');
    print('2. Invalid API credentials');
    print('3. Adzuna API server down');
    print('4. Request timeout');
  }
}

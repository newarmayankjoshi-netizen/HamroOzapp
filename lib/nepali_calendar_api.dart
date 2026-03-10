import 'dart:convert';
import 'package:http/http.dart' as http;

class NepaliCalendarApi {
  static Future<Map<String, dynamic>?> fetchMonth(int year, int month) async {
    final url = 'https://nepalicalendarapi.com/api/?year=$year&month=$month';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
  }
}

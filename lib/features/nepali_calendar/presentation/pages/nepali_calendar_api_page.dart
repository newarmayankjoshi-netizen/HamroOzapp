import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NepaliCalendarApiPage extends StatefulWidget {
  const NepaliCalendarApiPage({super.key});

  @override
  State<NepaliCalendarApiPage> createState() => _NepaliCalendarApiPageState();
}

class _NepaliCalendarApiPageState extends State<NepaliCalendarApiPage> {
  Map<String, dynamic>? calendarData;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchCalendarData();
  }

  Future<void> fetchCalendarData() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      // Replace with actual API endpoint
      final response = await http.get(Uri.parse('https://nepalicalendarapi.com/api/v1/today'));
      if (response.statusCode == 200) {
        calendarData = json.decode(response.body);
      } else {
        error = 'Failed to load calendar data.';
      }
    } catch (e) {
      error = e.toString();
    }
    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nepali Calendar API')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : calendarData == null
                  ? const Center(child: Text('No data'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text('Nepali Date: ${calendarData!['nepali_date'] ?? 'N/A'}', style: TextStyle(fontSize: 18)),
                        SizedBox(height: 8),
                        Text('Festival: ${calendarData!['festival'] ?? 'N/A'}'),
                        SizedBox(height: 8),
                        Text('Event: ${calendarData!['event'] ?? 'N/A'}'),
                        SizedBox(height: 8),
                        Text('Astrology: ${calendarData!['astrology'] ?? 'N/A'}'),
                      ],
                    ),
    );
  }
}

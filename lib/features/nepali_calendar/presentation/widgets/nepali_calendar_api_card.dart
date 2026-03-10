import 'package:flutter/material.dart';
import '../pages/nepali_calendar_api_page.dart';

// ...existing code...

class NepaliCalendarApiCard extends StatelessWidget {
  const NepaliCalendarApiCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_today),
        title: const Text('Nepali Calendar'),
        subtitle: const Text('View Nepali dates, festivals, events, astrology'),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const NepaliCalendarApiPage(),
            ),
          );
        },
      ),
    );
  }
}

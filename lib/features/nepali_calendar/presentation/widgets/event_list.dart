import 'package:flutter/material.dart';
import '../../domain/nepali_event.dart';

class EventList extends StatelessWidget {
  final List<NepaliEvent> events;

  const EventList({required this.events, super.key});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Center(child: Text('No events for this day'));
    }
    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return ListTile(title: Text(event.title));
      },
    );
  }
}

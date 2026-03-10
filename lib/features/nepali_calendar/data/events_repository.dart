import 'dart:convert';
import 'package:flutter/services.dart';
import '../domain/nepali_event.dart';

class EventsRepository {
  Future<List<NepaliEvent>> loadEvents() async {
    final data = await rootBundle.loadString("features/nepali_calendar/data/sample_events.json");
    final list = jsonDecode(data) as List;
    return list.map((e) => NepaliEvent.fromJson(e)).toList();
  }
}

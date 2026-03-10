/// Nepali public holidays and festivals data
/// This file contains lists of holidays and festivals for display in the Nepali calendar.
library;

class NepaliHoliday {
  final String name;
  final DateTime date;
  NepaliHoliday({required this.name, required this.date});
}

class NepaliFestival {
  final String name;
  final DateTime date;
  NepaliFestival({required this.name, required this.date});
}

/// Example holidays (add more as needed)
final List<NepaliHoliday> nepaliPublicHolidays = [
  NepaliHoliday(name: 'New Year (Nepali)', date: DateTime(2024, 4, 14)),
  NepaliHoliday(name: 'Constitution Day', date: DateTime(2024, 9, 20)),
  NepaliHoliday(name: 'Independence Day', date: DateTime(2024, 8, 15)),
  NepaliHoliday(name: 'Dashain Holiday', date: DateTime(2024, 10, 11)),
  NepaliHoliday(name: 'Tihar Holiday', date: DateTime(2024, 11, 3)),
];

/// Example festivals (add more as needed)
final List<NepaliFestival> nepaliFestivals = [
  NepaliFestival(name: 'Dashain', date: DateTime(2024, 10, 11)),
  NepaliFestival(name: 'Tihar', date: DateTime(2024, 11, 3)),
  NepaliFestival(name: 'Holi', date: DateTime(2024, 3, 24)),
  NepaliFestival(name: 'Maghe Sankranti', date: DateTime(2024, 1, 15)),
  NepaliFestival(name: 'Teej', date: DateTime(2024, 9, 6)),
];

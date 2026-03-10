// Nepali Calendar API Data Structure Example
// This is a sample Dart model and JSON structure for yearly holidays and festivals.

class NepaliCalendarDay {
  final String bsDate; // e.g. '2083-11-01'
  final String adDate; // e.g. '2027-02-13'
  final String? festival;
  final String? publicHoliday;
  final String? description;

  NepaliCalendarDay({
    required this.bsDate,
    required this.adDate,
    this.festival,
    this.publicHoliday,
    this.description,
  });

  factory NepaliCalendarDay.fromJson(Map<String, dynamic> json) => NepaliCalendarDay(
        bsDate: json['bs_date'],
        adDate: json['ad_date'],
        festival: json['festival'],
        publicHoliday: json['public_holiday'],
        description: json['description'],
      );

  Map<String, dynamic> toJson() => {
        'bs_date': bsDate,
        'ad_date': adDate,
        'festival': festival,
        'public_holiday': publicHoliday,
        'description': description,
      };
}

// Example JSON for a year (2083):
/*
[
  {
    "bs_date": "2083-01-01",
    "ad_date": "2026-04-13",
    "festival": "New Year",
    "public_holiday": "Nepali New Year",
    "description": "Nepali New Year 2083 BS."
  },
  {
    "bs_date": "2083-01-02",
    "ad_date": "2026-04-14",
    "festival": null,
    "public_holiday": null,
    "description": null
  },
  ...
]
*/

// The API endpoint could be:
// GET /api/nepali-calendar/{year}
// Returns: List<NepaliCalendarDay> for the year

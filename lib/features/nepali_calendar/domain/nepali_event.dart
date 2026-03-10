class NepaliEvent {
  final int year, month, day;
  final String title;

  NepaliEvent({required this.year, required this.month, required this.day, required this.title});

  factory NepaliEvent.fromJson(Map<String, dynamic> json) {
    return NepaliEvent(
      year: json["year"],
      month: json["month"],
      day: json["day"],
      title: json["title"],
    );
  }
}

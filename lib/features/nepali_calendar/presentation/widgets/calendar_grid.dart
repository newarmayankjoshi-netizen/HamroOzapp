import 'package:flutter/material.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart';
import 'day_cell.dart';
import '../../utils/nepali_holidays_festivals.dart';

class CalendarGrid extends StatelessWidget {
  final NepaliDateTime month;
  final Function(NepaliDateTime) onDaySelected;

  const CalendarGrid({
    required this.month,
    required this.onDaySelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = NepaliDateTime(month.year, month.month, 1);
    final nextMonth = month.month == 12
      ? NepaliDateTime(month.year + 1, 1, 1)
      : NepaliDateTime(month.year, month.month + 1, 1);
    final lastDayOfMonth = nextMonth.subtract(const Duration(days: 1));
    final totalDays = lastDayOfMonth.day;
    final startWeekday = firstDay.weekday % 7;

    return GridView.builder(
      padding: EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: totalDays + startWeekday,
      itemBuilder: (context, index) {
        if (index < startWeekday) return SizedBox();
        final day = index - startWeekday + 1;
        final date = NepaliDateTime(month.year, month.month, day);
        final isToday = NepaliDateTime.now().year == date.year &&
            NepaliDateTime.now().month == date.month &&
            NepaliDateTime.now().day == date.day;

        // Check for holiday/festival
        NepaliHoliday? holiday;
        try {
          holiday = nepaliPublicHolidays.firstWhere(
            (h) => h.date.year == date.year && h.date.month == date.month && h.date.day == date.day,
          );
        } catch (_) {
          holiday = null;
        }
        NepaliFestival? festival;
        try {
          festival = nepaliFestivals.firstWhere(
            (f) => f.date.year == date.year && f.date.month == date.month && f.date.day == date.day,
          );
        } catch (_) {
          festival = null;
        }

        return DayCell(
          date: date,
          isToday: isToday,
          holidayName: holiday?.name,
          festivalName: festival?.name,
          onTap: () => onDaySelected(date),
        );
      },
    );
  }
}

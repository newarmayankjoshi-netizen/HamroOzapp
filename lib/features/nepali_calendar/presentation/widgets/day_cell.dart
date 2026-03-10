import 'package:flutter/material.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart';

class DayCell extends StatelessWidget {
  final NepaliDateTime date;
  final bool isToday;
  final String? holidayName;
  final String? festivalName;
  final VoidCallback onTap;

  const DayCell({
    required this.date,
    required this.isToday,
    this.holidayName,
    this.festivalName,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isToday
              ? Colors.blue.shade100
              : (holidayName != null
                  ? Colors.red.shade100
                  : (festivalName != null
                      ? Colors.green.shade100
                      : Colors.transparent)),
          borderRadius: BorderRadius.circular(8),
          border: isToday
              ? Border.all(color: Colors.blue, width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              NepaliDateFormat('d').format(date),
              style: TextStyle(
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: holidayName != null
                    ? Colors.red
                    : (festivalName != null ? Colors.green : Colors.black),
              ),
            ),
            if (holidayName != null)
              Text(
                holidayName!,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            if (festivalName != null)
              Text(
                festivalName!,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}

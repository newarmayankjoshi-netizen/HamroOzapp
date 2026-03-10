import 'package:flutter/material.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart';

class CalendarHeader extends StatelessWidget {
  final NepaliDateTime month;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const CalendarHeader({
    required this.month,
    required this.onNext,
    required this.onPrevious,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = NepaliDateFormat("MMMM yyyy").format(month);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: Icon(Icons.chevron_left), onPressed: onPrevious),
          Text(
            formatted,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          IconButton(icon: Icon(Icons.chevron_right), onPressed: onNext),
        ],
      ),
    );
  }
}

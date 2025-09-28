import 'package:flutter/material.dart';
import 'package:APP/pages/home_screen/widgets/main_calendar.dart';
import 'package:APP/pages/home_screen/widgets/today_banner.dart';
import 'package:APP/pages/home_screen/model/schedule.dart';

class CalendarSection extends StatelessWidget {
  final DateTime selectedDate;
  final DateTime focusedDay;
  final Function(DateTime selectedDate, DateTime focusedDate) onDaySelected;
  final Map<DateTime, List<Schedule>> schedulesByDate;
  final int selectedDateCount;

  const CalendarSection({
    required this.selectedDate,
    required this.focusedDay,
    required this.onDaySelected,
    required this.schedulesByDate,
    required this.selectedDateCount,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 메인 캘린더 (헤더는 MainCalendar 것만 사용)
        MainCalendar(
          selectedDate: selectedDate,
          focusedDay: focusedDay,
          onDaySelected: onDaySelected,
          schedulesByDate: schedulesByDate,
        ),
        const SizedBox(height: 8.0),

        // 오늘 배너
        TodayBanner(
          selectedDate: selectedDate,
          count: selectedDateCount,
        ),
        const SizedBox(height: 8.0),
      ],
    );
  }
}

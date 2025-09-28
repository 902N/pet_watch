import 'package:APP/pages/home_screen/model/schedule.dart';

/// Utility functions for schedule operations with performance optimizations
class ScheduleUtils {
  /// 하루 일정만 뽑고 '시작 시간 오름차순'으로 정렬
  static List<Schedule> filterSchedulesByDate(
      List<Schedule> schedules,
      DateTime targetDate,
      ) {
    final normalizedTarget = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );

    final filtered = schedules.where((schedule) {
      final scheduleDate = DateTime(
        schedule.date.year,
        schedule.date.month,
        schedule.date.day,
      );
      return scheduleDate.isAtSameMomentAs(normalizedTarget);
    }).toList();

    // ✅ 시각 오름차순 정렬 (Comparable 구현 여부와 무관)
    filtered.sort((a, b) {
      final byHour = a.startHour.compareTo(b.startHour);
      if (byHour != 0) return byHour;
      // 동일 시간대면 id로 안정 정렬
      return a.id.compareTo(b.id);
    });

    return filtered;
  }

  /// Optimized same day comparison using normalized dates
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Efficiently compares two schedule lists for equality (shallow comparison)
  static bool areScheduleListsEqual(
      List<Schedule> list1,
      List<Schedule> list2,
      ) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) return false;
    }
    return true;
  }
}

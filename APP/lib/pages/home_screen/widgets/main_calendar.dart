// lib/pages/home_screen/widgets/main_calendar.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:APP/const/colors.dart';
import 'package:APP/pages/home_screen/model/schedule.dart';

class MainCalendar extends StatelessWidget {
  final OnDaySelected onDaySelected;
  final DateTime selectedDate;
  final DateTime focusedDay;
  final Map<DateTime, List<Schedule>>? schedulesByDate;

  const MainCalendar({
    super.key,
    required this.onDaySelected,
    required this.selectedDate,
    required this.focusedDay,
    this.schedulesByDate,
  });

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      locale: 'ko_KR',
      daysOfWeekHeight: 28.0,
      onDaySelected: onDaySelected,
      selectedDayPredicate: (date) =>
      date.year == selectedDate.year &&
          date.month == selectedDate.month &&
          date.day == selectedDate.day,
      firstDay: DateTime(1800, 1, 1),
      lastDay: DateTime(3000, 1, 1),
      focusedDay: focusedDay,

      // 헤더: 중앙정렬 & 큰 글씨
      headerStyle: HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 22,
          color: AppColors.textPrimary,
          height: 1.1,
          letterSpacing: 0.2,
        ),
        leftChevronPadding: const EdgeInsets.symmetric(horizontal: 8),
        rightChevronPadding: const EdgeInsets.symmetric(horizontal: 8),
      ),

      calendarStyle: CalendarStyle(
        isTodayHighlighted: true,
        todayDecoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.divider),
        defaultDecoration: const BoxDecoration(shape: BoxShape.circle),
        weekendDecoration: const BoxDecoration(shape: BoxShape.circle),
        selectedDecoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryAccent),
        defaultTextStyle: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        weekendTextStyle: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        selectedTextStyle: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      ),

      daysOfWeekStyle: const DaysOfWeekStyle(
        weekdayStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.0, height: 1.2),
        weekendStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.0, height: 1.2),
      ),

      calendarBuilders: CalendarBuilders(
        // 헤더 제목 탭 → 연/월 그리드 피커
        headerTitleBuilder: (context, day) {
          final title = '${day.year}년 ${day.month}월';
          return InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () async {
              final picked = await _pickYearMonthGrid(context, day);
              if (picked != null) {
                final target = DateTime(picked.year, picked.month, 1);
                onDaySelected(target, target);
              }
            },
            child: Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          );
        },

        // 요일 헤더: 토=파랑, 일=빨강
        dowBuilder: (context, day) {
          String label;
          if (day.weekday == DateTime.sunday) {
            label = '일';
          } else if (day.weekday == DateTime.monday) {
            label = '월';
          } else if (day.weekday == DateTime.tuesday) {
            label = '화';
          } else if (day.weekday == DateTime.wednesday) {
            label = '수';
          } else if (day.weekday == DateTime.thursday) {
            label = '목';
          } else if (day.weekday == DateTime.friday) {
            label = '금';
          } else {
            label = '토';
          }

          final isSat = day.weekday == DateTime.saturday;
          final isSun = day.weekday == DateTime.sunday;
          final color = isSat ? Colors.blue : (isSun ? Colors.red : AppColors.textSecondary);

          return Center(
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.0, height: 1.2, color: color),
            ),
          );
        },

        // 날짜 셀(현재 달)
        defaultBuilder: (context, date, _) {
          final isSat = date.weekday == DateTime.saturday;
          final isSun = date.weekday == DateTime.sunday;
          final color = isSat ? Colors.blue : (isSun ? Colors.red : AppColors.textSecondary);
          return Center(child: Text('${date.day}', style: TextStyle(fontWeight: FontWeight.w600, color: color)));
        },

        // 다른 달 날짜
        outsideBuilder: (context, date, _) {
          final isSat = date.weekday == DateTime.saturday;
          final isSun = date.weekday == DateTime.sunday;
          final base = isSat ? Colors.blue : (isSun ? Colors.red : AppColors.textSecondary);
          return Center(child: Text('${date.day}', style: TextStyle(fontWeight: FontWeight.w600, color: base.withOpacity(0.4))));
        },

        // 날짜 하단 마커
        markerBuilder: (context, date, events) {
          final list = schedulesByDate?[DateTime(date.year, date.month, date.day)] ?? const <Schedule>[];
          if (list.isEmpty) return null;

          final colors = list
              .take(3)
              .map((s) => kCategoryColorMap[s.category ?? 'memo'] ?? AppColors.textSecondary)
              .toList();
          final extra = list.length - colors.length;

          return Padding(
            padding: const EdgeInsets.only(top: 28.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final c in colors)
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                  ),
                if (extra > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 2),
                    child: Text('+', style: TextStyle(fontSize: 8, color: AppColors.textSecondary)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 연도 좌우 화살표 + 12개월 그리드 (탭 즉시 이동, 높이 고정으로 overflow 방지)
Future<DateTime?> _pickYearMonthGrid(BuildContext context, DateTime initial) async {
  int year = initial.year;

  // UI 상수
  const double kPillHeight = 46;
  const double kSpacing = 12;
  const double kHeaderApprox = 56; // 상단 연/월 헤더 대략 높이
  const double kMinGridH = 160;    // 너무 작아지지 않도록 최소치
  const double kIdealGridH = 4 * kPillHeight + 3 * kSpacing; // ≈ 258 (4행)

  return showModalBottomSheet<DateTime>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true, // 가용 높이 반영
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      // ↓↓↓ StatefulBuilder로 year 변경을 setState로 처리
      return StatefulBuilder(
        builder: (ctx, setSB) {
          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: LayoutBuilder(
                builder: (ctx2, cons) {
                  // 바텀시트 내부 최대 높이
                  final double maxH = cons.maxHeight;

                  // 그리드에 줄 수 있는 실제 높이(헤더/여백 제외)
                  final double gridH =
                  (maxH - kHeaderApprox - 20).clamp(kMinGridH, kIdealGridH);

                  final bool scrollable = gridH < kIdealGridH;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 상단: 좌/우 화살표 + 연도 중앙정렬
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () => setSB(() => year--),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                '$year년',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () => setSB(() => year++),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // 12개월 그리드 (탭 즉시 pop)
                      SizedBox(
                        height: gridH,
                        child: GridView.builder(
                          physics: scrollable
                              ? const BouncingScrollPhysics()
                              : const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: 12,
                          gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: kSpacing,
                            crossAxisSpacing: kSpacing,
                            childAspectRatio: 2.8,
                          ),
                          itemBuilder: (context, index) {
                            final month = index + 1;
                            final bool isSelected =
                            (year == initial.year && month == initial.month);

                            return _MonthPillButton(
                              label: '$month월',
                              selected: isSelected,
                              onTap: () => Navigator.pop(
                                ctx,
                                DateTime(year, month, 1),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      );
    },
  );
}




/// 둥근 모양의 월 선택 버튼
class _MonthPillButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MonthPillButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = selected ? Colors.black.withOpacity(0.08) : Colors.black.withOpacity(0.04);
    final Color border = selected ? Colors.black.withOpacity(0.12) : Colors.black.withOpacity(0.06);

    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

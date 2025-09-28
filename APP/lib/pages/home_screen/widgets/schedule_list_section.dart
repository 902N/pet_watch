import 'package:flutter/material.dart';
import 'package:APP/pages/home_screen/widgets/schedule_card.dart';
import 'package:APP/pages/home_screen/model/schedule.dart';

class ScheduleListSection extends StatelessWidget {
  final List<Schedule> schedules;
  final void Function(Schedule)? onTap;

  const ScheduleListSection({
    required this.schedules,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: schedules.isEmpty
          ? const Center(
        child: Text(
          '기록이 없습니다.',
          style: TextStyle(color: Colors.grey, fontSize: 16.0),
        ),
      )
          : ListView.builder(
        itemCount: schedules.length,
        itemBuilder: (context, index) {
          final s = schedules[index];
              // 시간 정렬 보장 (컨트롤러에서 대부분 정렬되지만 방어적 처리)
              // 리스트 자체는 이미 날짜 필터링된 상태이므로 여기서 정렬은 하지 않음
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: GestureDetector(
              key: Key('${s.category ?? 'unknown'}_record_item_$index'),
              onTap: onTap == null ? null : () => onTap!(s),
              child: ScheduleCard(
                startTime: s.startHour,
                startMinute: s.startMinute,
                content: s.content,
                category: s.category,
                isDone: s.isDone,
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';

class MiniMonthCalendar extends StatelessWidget {
  /// 레이아웃에서 참조할 ‘권장 달력 높이’
  static const double preferredHeight = 118; // 112~122 사이로 미세조정 가능

  final DateTime monthAnchor;
  final Set<dynamic> markedDays;
  final Color markColor;
  final String? debugLabel;
  final bool showTodayRing; // 미사용

  const MiniMonthCalendar({
    super.key,
    required this.monthAnchor,
    required this.markedDays,
    required this.markColor,
    this.debugLabel,
    this.showTodayRing = false,
  });

  Set<int> _normalize(Set<dynamic> src, DateTime anchor) {
    final out = <int>{};
    for (final v in src) {
      if (v is int) {
        if (v >= 1 && v <= 31) out.add(v);
      } else if (v is DateTime) {
        if (v.year == anchor.year && v.month == anchor.month) out.add(v.day);
      } else if (v is String) {
        final dt = DateTime.tryParse(v);
        if (dt != null && dt.year == anchor.year && dt.month == anchor.month) out.add(dt.day);
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final first = DateTime(monthAnchor.year, monthAnchor.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(monthAnchor.year, monthAnchor.month);
    final startW = first.weekday % 7;
    final cells = startW + daysInMonth;

    final normalized = _normalize(markedDays, monthAnchor);

    // 기본 labelSmall보다 1pt 크게
    final base = Theme.of(context).textTheme.labelSmall;
    final bigger = base?.copyWith(fontSize: (base?.fontSize ?? 12) + 1);

    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    final header = weekdays.asMap().entries.map((e) {
      return Center(
        child: Text(
          e.value,
          style: (bigger ?? const TextStyle(fontSize: 13)).copyWith(
            fontWeight: FontWeight.w700,
            height: 1.0,
            color: e.key == 0
                ? Colors.red
                : (e.key == 6 ? Colors.blue : Colors.black.withOpacity(.45)),
          ),
        ),
      );
    }).toList();

    final items = List<Widget>.generate(cells, (i) {
      if (i < startW) return const SizedBox.shrink();

      final day = i - startW + 1;
      final marked = normalized.contains(day);
      final w = i % 7;
      final baseColor = w == 0
          ? Colors.red
          : (w == 6 ? Colors.blue : Colors.black.withOpacity(.75));
      final textColor = marked ? Colors.white : baseColor;

      return Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (marked)
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(color: markColor, shape: BoxShape.circle),
              ),
            Text(
              '$day',
              textAlign: TextAlign.center,
              style: (bigger ?? const TextStyle(fontSize: 13)).copyWith(
                height: 1.0,
                color: textColor,
                fontWeight: marked ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    });

    // ✅ 어떤 보드/배경도 감싸지 않고 ‘순수 달력’만 반환
    return Column(
      children: [
        SizedBox(
          height: 18,
          child: GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: header,
          ),
        ),
        GridView.count(
          crossAxisCount: 7,
          mainAxisSpacing: 2,
          crossAxisSpacing: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: items,
        ),
      ],
    );
  }
}

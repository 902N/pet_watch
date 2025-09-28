import 'package:flutter/material.dart';
import 'mini_month_calendar.dart';

class RecordCard extends StatelessWidget {
  // 내부 레이아웃 상수
  static const double _padTop = 10;
  static const double _padBottom = 10;
  static const double _titleRowGap = 4;
  static const double _calendarFooterGap = 6;
  static const double _footerRowHeight = 22; // 푸터 고정 높이

  /// Grid에서 카드 높이 계산할 때 사용 (콘텐츠 기준 + 여유는 호출부에서)
  static double gridItemHeight(BuildContext context) {
    const titleRowHeight = 20;
    return _padTop +
        titleRowHeight +
        _titleRowGap +
        MiniMonthCalendar.preferredHeight +   // ← 래퍼 패딩 없음!
        _calendarFooterGap +
        _footerRowHeight +
        _padBottom;
  }

  final Widget icon;
  final String title;
  final Color accent;
  final DateTime monthAnchor;
  final Set<dynamic> markedDays; // 정규화는 MiniMonthCalendar에서 처리
  final Widget footer;

  /// 제목/아이콘 컬러 커스터마이즈(없으면 기본 onSurface, accent)
  final Color? titleColor;
  final Color? iconColor;

  const RecordCard({
    super.key,
    required this.icon,
    required this.title,
    required this.accent,
    required this.monthAnchor,
    required this.markedDays,
    required this.footer,
    this.titleColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, _padTop, 12, _padBottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목 행
            Row(
              children: [
                IconTheme(
                  data: IconThemeData(color: iconColor ?? accent, size: 16),
                  child: icon,
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: titleColor ?? onSurface,
                  ),
                ),
              ],
            ),

            const SizedBox(height: _titleRowGap),

            // 달력 (★ 어떤 래퍼도 없이 순수 달력만)
            SizedBox(
              height: MiniMonthCalendar.preferredHeight,
              child: MiniMonthCalendar(
                monthAnchor: monthAnchor,
                markedDays: markedDays.cast<dynamic>().toSet(),
                markColor: accent,
                showTodayRing: false,
              ),
            ),

            const SizedBox(height: _calendarFooterGap),

            // 푸터 (고정 높이로 오버플로우 방지)
            SizedBox(height: _footerRowHeight, child: Center(child: footer)),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class MiniStat {
  final String label;
  final String value;
  final Color? accent;
  MiniStat({required this.label, required this.value, this.accent});
}

class WeeklyStatsPanel extends StatelessWidget {
  const WeeklyStatsPanel({
    super.key,
    required this.weekStart,
    required this.matrix,
    required this.summary,
    this.showSummary = true,
  });

  final DateTime weekStart;
  final Map<String, List<bool>> matrix;
  final List<MiniStat> summary;
  final bool showSummary;

  // ── 사이즈/폰트/간격 조절 지점 ─────────────────────────────────────────────
  static const double _dotSize = 22;          // 칸(흰 네모) 크기
  static const double _dotRadius = 7;         // 칸 라운드
  static const double _weekdayFontSize = 16;  // 요일(월~일) 글씨
  static const double _labelFontSize = 15;    // 좌측 라벨 글씨
  static const double _labelColWidth = 48;    // 좌측 라벨 영역 너비
  static const double _rowHeight = 34;        // ▶ 각 행(식사/산책/...) 세로 높이
  static const double _rowGap = 10;           // ▶ 행 사이 여백
  static const double _headerBottomGap = 10;  // ▶ 요일 헤더와 첫 행 사이 여백
  static const EdgeInsets _cardPadding = EdgeInsets.fromLTRB(12, 14, 12, 14);
  // ────────────────────────────────────────────────────────────────────

  static const _labelsKo = {
    'meal': '식사',
    'walk': '산책',
    'excretion': '배변',
    'health': '건강',
    'memo': '자유',
    'anomaly': '이상',
  };

  static const _labelColor = {
    'meal': Color(0xFF9B6BFF),
    'walk': Color(0xFF38A3FF),
    'excretion': Color(0xFFFF6FAE),
    'health': Color(0xFF37D4B8),
    'memo': Color(0xFF666666),
    'anomaly': Color(0xFFE75151),
  };

  List<bool> _safe7(List<bool>? v) {
    if (v == null) return List<bool>.filled(7, false);
    if (v.length >= 7) return v.sublist(0, 7);
    return [...v, ...List<bool>.filled(7 - v.length, false)];
  }

  Widget _dot({
    required bool active,
    required Color accent,
    bool filledWhenActive = true,
    double size = _dotSize,
    double radius = _dotRadius,
    double borderWidth = 1.2,
    required Color borderColor,
    Color? bg,
  }) {
    final filled = active && filledWhenActive;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: filled ? accent : (bg ?? Colors.transparent),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: active ? accent : borderColor,
          width: borderWidth,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final borderColor = cs.outlineVariant;
    final weekdaysKo = ['월', '화', '수', '목', '금', '토', '일'];
    final order = ['meal', 'walk', 'excretion', 'health', 'memo', 'anomaly'];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFF7F5FB),
      child: Padding(
        padding: _cardPadding,
        child: Column(
          children: [
            // 요일 헤더
            Row(
              children: [
                const SizedBox(width: _labelColWidth),
                for (final w in weekdaysKo)
                  Expanded(
                    child: Center(
                      child: Text(
                        w,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: _weekdayFontSize,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: _headerBottomGap),

            // 내용 행
            for (final key in order) ...[
              _RowLine(
                height: _rowHeight,
                dotColor: _labelColor[key]!,
                label: _labelsKo[key]!,
                labelFontSize: _labelFontSize,
                labelColWidth: _labelColWidth,
                builder: (i) => _dot(
                  active: _safe7(matrix[key]).elementAt(i),
                  accent: _labelColor[key]!,
                  borderColor: borderColor,
                  filledWhenActive: true, // 이상도 채워서 표시
                  bg: Colors.white,
                ),
              ),
              SizedBox(height: _rowGap),
            ],
          ],
        ),
      ),
    );
  }
}

class _RowLine extends StatelessWidget {
  const _RowLine({
    required this.height,
    required this.dotColor,
    required this.label,
    required this.builder,
    required this.labelFontSize,
    required this.labelColWidth,
  });

  final double height;
  final Color dotColor;
  final String label;
  final double labelFontSize;
  final double labelColWidth;
  final Widget Function(int dayIndex) builder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: height, // ▶ 행 전체 높이 확보
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 왼쪽 라벨
          SizedBox(
            width: labelColWidth,
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: labelFontSize,
                    height: 1.05,
                  ),
                ),
              ],
            ),
          ),

          // 7일 칸
          for (int i = 0; i < 7; i++) ...[
            Expanded(
              child: Center(child: builder(i)), // 세로 가운데 정렬
            ),
          ],
        ],
      ),
    );
  }
}

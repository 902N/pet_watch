import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/weekly_report.dart' show WeeklyRecord;

/// 사용량 지표
enum UsageMetric { mealAmount, snackAmount, waterAmount, walkTime, intensity }

String usageMetricLabel(UsageMetric m) {
  switch (m) {
    case UsageMetric.mealAmount: return '식사량';
    case UsageMetric.snackAmount: return '간식량';
    case UsageMetric.waterAmount: return '물 양';
    case UsageMetric.walkTime:   return '산책 시간';
    case UsageMetric.intensity:  return '최고 강도';
  }
}

String usageMetricUnit(UsageMetric m) {
  switch (m) {
    case UsageMetric.mealAmount:
    case UsageMetric.snackAmount: return 'g';
    case UsageMetric.waterAmount: return 'ml';
    case UsageMetric.walkTime:    return '분';
    case UsageMetric.intensity:   return '';
  }
}

// 라인 색
const _mealColor      = Color(0xFF9B6BFF);
const _snackColor     = Color(0xFFFF6FAE);
const _waterColor     = Color(0xFF38A3FF);
const _walkColor      = Color(0xFF37D4B8);
const _intensityColor = Color(0xFF666666);

Color _colorOfMetric(UsageMetric m) {
  switch (m) {
    case UsageMetric.mealAmount:  return _mealColor;
    case UsageMetric.snackAmount: return _snackColor;
    case UsageMetric.waterAmount: return _waterColor;
    case UsageMetric.walkTime:    return _walkColor;
    case UsageMetric.intensity:   return _intensityColor;
  }
}

int intensityScore(String s) {
  switch (s.trim()) {
    case '낮음': return 1;
    case '보통': return 2;
    case '높음': return 3;
    default:     return 0;
  }
}

List<int> _safe7(List<int> src) {
  if (src.length >= 7) return src.sublist(0, 7);
  return [...src, ...List.filled(7 - src.length, 0)];
}

class WeeklyAmountChart extends StatefulWidget {
  final DateTime weekStart;         // 월요일 앵커
  final List<WeeklyRecord> records; // API 데이터
  final UsageMetric metric;
  final VoidCallback? onTapChangeMetric;

  const WeeklyAmountChart({
    super.key,
    required this.weekStart,
    required this.records,
    required this.metric,
    this.onTapChangeMetric,
  });

  @override
  State<WeeklyAmountChart> createState() => _WeeklyAmountChartState();
}

class _WeeklyAmountChartState extends State<WeeklyAmountChart> {
  /// 고정 툴팁을 위한 상태(선택된 인덱스). null이면 비표시
  int? _selectedIndex;

  List<int> _values(UsageMetric m, List<WeeklyRecord> d) {
    switch (m) {
      case UsageMetric.mealAmount:  return d.map((r) => r.mealAmount).toList();
      case UsageMetric.snackAmount: return d.map((r) => r.snackAmount).toList();
      case UsageMetric.waterAmount: return d.map((r) => r.waterAmount).toList();
      case UsageMetric.walkTime:    return d.map((r) => r.walkTime).toList();
      case UsageMetric.intensity:   return d.map((r) => intensityScore(r.walkIntensity ?? '')).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _colorOfMetric(widget.metric);

    final vals = _safe7(_values(widget.metric, widget.records));
    final maxY = (vals.isEmpty ? 1 : vals.reduce((a, b) => a > b ? a : b));
    final yStep = maxY <= 5 ? 1.0 : (maxY / 5).ceilToDouble();
    final xLabels = const ['월', '화', '수', '목', '금', '토', '일'];

    TextStyle dayStyle(int i) {
      final base = theme.textTheme.bodyMedium!;
      if (i == 5) return base.copyWith(color: Colors.blue);
      if (i == 6) return base.copyWith(color: Colors.red);
      return base;
    }

    int? todayIndex() {
      final today = DateTime.now();
      final monday = DateTime(widget.weekStart.year, widget.weekStart.month, widget.weekStart.day);
      for (var i = 0; i < 7; i++) {
        final d = monday.add(Duration(days: i));
        if (d.year == today.year && d.month == today.month && d.day == today.day) return i;
      }
      return null;
    }

    final lineData = LineChartBarData(
      isCurved: false,
      color: color,
      barWidth: 3,
      dotData: const FlDotData(show: true),
      spots: List.generate(vals.length, (i) => FlSpot(i.toDouble(), vals[i].toDouble())),
    );

    // 선택된 점을 고정해서 보여주기 위한 인디케이터
    final showing = <ShowingTooltipIndicators>[
      if (_selectedIndex != null && _selectedIndex! >= 0 && _selectedIndex! < vals.length)
        ShowingTooltipIndicators([
          LineBarSpot(lineData, 0, FlSpot(_selectedIndex!.toDouble(), vals[_selectedIndex!].toDouble())),
        ]),
    ];

    final gridH = Colors.black.withOpacity(0.10);
    final gridV = Colors.black.withOpacity(0.08);
    final today = todayIndex();

    final chart = LineChart(
      LineChartData(
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: (maxY == 0 ? 1 : maxY).toDouble(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: yStep,
          verticalInterval: 1,
          getDrawingHorizontalLine: (v) => FlLine(color: gridH, strokeWidth: 1),
          getDrawingVerticalLine: (v) => FlLine(color: gridV, dashArray: const [6, 6], strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: yStep,
              getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: theme.textTheme.bodyMedium),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (v, m) {
                final i = v.toInt();
                if (i < 0 || i > 6) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(xLabels[i], style: dayStyle(i)),
                );
              },
            ),
          ),
        ),
        lineBarsData: [lineData],

        // ✅ 빌트인 터치(일시 툴팁) 끄고, 우리가 고정 툴팁만 컨트롤
        lineTouchData: LineTouchData(
          handleBuiltInTouches: false,
          enabled: true,
          touchCallback: (event, resp) {
            if (event is FlTapUpEvent) {
              final spot = resp?.lineBarSpots?.isNotEmpty == true ? resp!.lineBarSpots!.first : null;
              if (spot == null) {
                // 빈 영역을 탭 → 선택 해제
                setState(() => _selectedIndex = null);
              } else {
                final idx = spot.x.round().clamp(0, 6);
                // 같은 점을 다시 탭 → 토글 해제
                setState(() {
                  _selectedIndex = (_selectedIndex == idx) ? null : idx;
                });
              }
            }
          },
          touchSpotThreshold: 24, // 점 근처 허용 반경
          mouseCursorResolver: (event, resp) => SystemMouseCursors.click,
          touchTooltipData: LineTouchTooltipData(
            // 여기 값은 showingTooltipIndicators에 의해 '고정'으로 표시됨
            tooltipBgColor: Colors.black.withOpacity(0.8),
            getTooltipItems: (spots) => spots.map((s) {
              final day = xLabels[s.x.toInt()];
              final value = s.y.toInt();
              final unit = usageMetricUnit(widget.metric);
              return LineTooltipItem(
                '$day  $value${unit.isEmpty ? '' : unit}',
                TextStyle(color: color, fontWeight: FontWeight.w800),
              );
            }).toList(),
          ),
        ),

        // ⛳️ 고정 툴팁의 타깃 지정
        showingTooltipIndicators: showing,

        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          verticalLines: [
            // 월요일 라인 강제 추가
            VerticalLine(
              x: 0,
              color: gridV,
              dashArray: const [6, 6],
              strokeWidth: 1,
            ),
            if (today != null)
              VerticalLine(
                x: today.toDouble(),
                color: Colors.black.withOpacity(0.28),
                dashArray: const [4, 6],
                strokeWidth: 1,
              ),
          ],
        ),
      ),
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '주간 사용량 (${usageMetricLabel(widget.metric)} · ${usageMetricUnit(widget.metric).isEmpty ? "점수" : usageMetricUnit(widget.metric)})',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: widget.onTapChangeMetric,
                  icon: const Icon(Icons.tune, size: 18),
                  label: Text('필터 · ${usageMetricLabel(widget.metric)}'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFEDE7FF),
                    foregroundColor: Colors.black,
                    minimumSize: const Size(0, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: theme.textTheme.bodyMedium,
                    shape: const StadiumBorder(),
                    elevation: 0,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            AspectRatio(aspectRatio: 1.6, child: chart),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

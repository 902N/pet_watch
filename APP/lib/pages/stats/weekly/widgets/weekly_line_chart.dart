import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/weekly_report.dart'; // WeeklyRecord, toWeeklyCounts

class WeeklyLineChart extends StatelessWidget {
  final DateTime weekStart;
  final List<WeeklyRecord> records;
  final List<String>? visibleKeys;
  final String? filterLabel;
  final VoidCallback? onTapFilter;

  const WeeklyLineChart({
    super.key,
    required this.weekStart,
    required this.records,
    this.visibleKeys,
    this.filterLabel,
    this.onTapFilter,
  });

  static const _allOrder = ['meal', 'walk', 'excretion', 'health', 'memo'];
  static const _label = {
    'meal': '식사',
    'walk': '산책',
    'excretion': '배변',
    'health': '건강',
    'memo': '자유',
  };

  static const _mealColor      = Color(0xFF9B6BFF);
  static const _walkColor      = Color(0xFF38A3FF);
  static const _excretionColor = Color(0xFFFF6FAE);
  static const _healthColor    = Color(0xFF37D4B8);
  static const _memoColor      = Color(0xFF666666);

  Color _colorOf(String key) {
    switch (key) {
      case 'meal': return _mealColor;
      case 'walk': return _walkColor;
      case 'excretion': return _excretionColor;
      case 'health': return _healthColor;
      case 'memo': return _memoColor;
      default: return Colors.black87;
    }
  }

  @override
  Widget build(BuildContext context) {
    final counts = toWeeklyCounts(records);
    final order = (visibleKeys == null || visibleKeys!.isEmpty)
        ? _allOrder
        : visibleKeys!.where((k) => counts.containsKey(k)).toList();

    final maxY = order.expand((k) => counts[k]!).fold<int>(0, (m, v) => v > m ? v : m);
    final yStep = maxY <= 5 ? 1.0 : (maxY / 5).ceilToDouble();
    final xLabels = const ['월','화','수','목','금','토','일'];

    final series = <LineChartBarData>[
      for (final key in order)
        LineChartBarData(
          isCurved: false,
          color: _colorOf(key),
          barWidth: 3,
          dotData: const FlDotData(show: true),
          spots: List.generate(7, (i) => FlSpot(i.toDouble(), counts[key]![i].toDouble())),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(
            '카테고리별 일간 횟수',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const Spacer(),
          if (onTapFilter != null)
            OutlinedButton.icon(
              onPressed: onTapFilter,
              icon: const Icon(Icons.filter_list, size: 16),
              label: Text(filterLabel ?? '전체'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: const StadiumBorder(),
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ]),
        const SizedBox(height: 8),
        Card(
          elevation: 3,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    for (final key in order)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 10, height: 10, decoration: BoxDecoration(color: _colorOf(key), shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(_label[key]!, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                AspectRatio(
                  aspectRatio: 1.8,
                  child: LineChart(
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
                        getDrawingHorizontalLine: (v) => FlLine(color: Colors.black.withOpacity(0.1), strokeWidth: 1),
                        getDrawingVerticalLine: (v) => FlLine(color: Colors.black.withOpacity(0.08), dashArray: [6, 6], strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: yStep,
                            getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: Theme.of(context).textTheme.bodySmall),
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
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(xLabels[i], style: Theme.of(context).textTheme.bodySmall),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: series,
                      lineTouchData: LineTouchData(
                        handleBuiltInTouches: true,
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBgColor: Colors.black.withOpacity(0.75),
                          getTooltipItems: (items) => items.map((s) {
                            final idx = s.barIndex;
                            final key = order[idx];
                            final day = xLabels[s.x.toInt()];
                            final value = s.y.toInt();
                            return LineTooltipItem(
                              '$day • ${_label[key]}  $value회',
                              TextStyle(color: _colorOf(key), fontWeight: FontWeight.w800),
                            );
                          }).toList(),
                        ),
                      ),
                      borderData: FlBorderData(show: true, border: Border.all(color: const Color(0xFFE5D4FF))),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

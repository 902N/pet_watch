import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'widgets/weekly_stats_panel.dart'
    show MiniStat, WeeklyStatsPanel;
import 'widgets/weekly_amount_chart.dart'
    show WeeklyAmountChart, UsageMetric, usageMetricLabel, usageMetricUnit;
import 'api/weekly_report_api.dart';
import 'models/weekly_report.dart' show WeeklyReportData;
import '../../../../widget/pet_id.dart';

List<MiniStat> defaultWeeklySummary({
  required int activeDays,
  required int restDays,
  required int alerts,
}) {
  return [
    MiniStat(label: '활동일', value: '$activeDays', accent: const Color(0xFF7C3AED)),
    MiniStat(label: '휴식일', value: '$restDays', accent: const Color(0xFF6B7280)),
    MiniStat(label: '이상', value: '$alerts', accent: const Color(0xFFE75151)),
  ];
}

enum WeeklyFilter { all, meal, walk, excretion, health, memo }

String _filterLabel(WeeklyFilter f) {
  switch (f) {
    case WeeklyFilter.all:
      return '전체';
    case WeeklyFilter.meal:
      return '식사';
    case WeeklyFilter.walk:
      return '산책';
    case WeeklyFilter.excretion:
      return '배변';
    case WeeklyFilter.health:
      return '건강';
    case WeeklyFilter.memo:
      return '자유';
  }
}

class WeeklyView extends StatefulWidget {
  const WeeklyView({super.key});
  @override
  State<WeeklyView> createState() => _WeeklyViewState();
}

class _WeeklyViewState extends State<WeeklyView> {
  DateTime _cursor = DateTime.now();
  late final WeeklyReportApi _api;

  bool _loading = false;
  String? _error;

  Map<String, List<bool>>? _matrix;
  List<MiniStat>? _summary;
  WeeklyReportData? _lastWeekly;

  WeeklyFilter _filter = WeeklyFilter.all;
  UsageMetric _usageMetric = UsageMetric.mealAmount;

  Color _metricColor(UsageMetric m) {
    switch (m) {
      case UsageMetric.mealAmount:
        return const Color(0xFF9B6BFF);
      case UsageMetric.snackAmount:
        return const Color(0xFFFF6FAE);
      case UsageMetric.waterAmount:
        return const Color(0xFF38A3FF);
      case UsageMetric.walkTime:
        return const Color(0xFF37D4B8);
      case UsageMetric.intensity:
        return const Color(0xFF666666);
    }
  }

  IconData _metricIcon(UsageMetric m) {
    switch (m) {
      case UsageMetric.mealAmount:
        return Icons.restaurant;
      case UsageMetric.snackAmount:
        return Icons.cake_outlined;
      case UsageMetric.waterAmount:
        return Icons.local_drink_outlined;
      case UsageMetric.walkTime:
        return Icons.directions_walk;
      case UsageMetric.intensity:
        return Icons.trending_up;
    }
  }

  DateTime _mondayOf(DateTime d) {
    final base = DateTime(d.year, d.month, d.day);
    final diff = (base.weekday + 6) % 7;
    return base.subtract(Duration(days: diff));
  }

  @override
  void initState() {
    super.initState();
    _api = WeeklyReportApi();
    _load();
  }

  Future<void> _load() async {
    final petId = context.read<PetIdStore>().activePetId;
    final weekStart = _mondayOf(_cursor);

    if (petId == null) {
      setState(() {
        _error = '활성화된 반려동물 ID가 없습니다.';
        _loading = false;
        _matrix = null;
        _summary = null;
        _lastWeekly = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _api.fetchWeeklyMatrix(petId: petId, weekStart: weekStart),
        _api.fetchWeekly(petId: petId, weekStart: weekStart),
      ]);

      final matrix = results[0] as Map<String, List<bool>>;
      final weekly = results[1] as WeeklyReportData;

      List<bool> _safe7(List<bool>? v) => v == null
          ? List<bool>.filled(7, false)
          : (v.length >= 7
          ? v.sublist(0, 7)
          : [...v, ...List<bool>.filled(7 - v.length, false)]);

      final meal = _safe7(matrix['meal']);
      final walk = _safe7(matrix['walk']);
      final excretion = _safe7(matrix['excretion']);
      final health = _safe7(matrix['health']);
      final memo = _safe7(matrix['memo']);
      final anomaly = _safe7(matrix['anomaly']);

      final activeDays = List.generate(
          7, (i) => meal[i] || walk[i] || excretion[i] || health[i] || memo[i])
          .where((e) => e)
          .length;
      final restDays = 7 - activeDays;
      final alerts = anomaly.where((e) => e).length;

      if (!mounted) return;
      setState(() {
        _matrix = matrix;
        _lastWeekly = weekly;
        _summary = defaultWeeklySummary(
          activeDays: activeDays,
          restDays: restDays,
          alerts: alerts,
        );
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _matrix = null;
        _summary = null;
        _lastWeekly = null;
      });
    }
  }

  void _prevWeek() {
    setState(() => _cursor = _cursor.subtract(const Duration(days: 7)));
    _load();
  }

  void _nextWeek() {
    setState(() => _cursor = _cursor.add(const Duration(days: 7)));
    _load();
  }

  Future<void> _openFilterDialog() async {
    final picked = await showDialog<WeeklyFilter>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 4),
            Text('보기 설정',
                style: Theme.of(ctx)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Divider(height: 1),
            ...[
              WeeklyFilter.all,
              WeeklyFilter.meal,
              WeeklyFilter.walk,
              WeeklyFilter.excretion,
              WeeklyFilter.health,
              WeeklyFilter.memo,
            ].map((f) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              title: Text(_filterLabel(f)),
              trailing: f == _filter
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () => Navigator.of(ctx).pop(f),
            )),
          ]),
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _filter = picked);
  }

// 기존 _openUsageMetricDialog() 전체 교체
  Future<void> _openUsageMetricDialog() async {
    final picked = await showDialog<UsageMetric>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final cs = theme.colorScheme;

        // intensity 제외하여 표기
        final metrics = const [
          UsageMetric.mealAmount,
          UsageMetric.snackAmount,
          UsageMetric.waterAmount,
          UsageMetric.walkTime,
        ];

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 4),
                  Text('지표 선택',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                      children: [
                        for (final m in metrics)
                          Container(
                            constraints: const BoxConstraints(minHeight: 64),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              dense: false,
                              visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              leading: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: _metricColor(m).withOpacity(0.18),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _metricIcon(m),
                                  size: 16,
                                  color: _metricColor(m),
                                ),
                              ),
                              title: Text(usageMetricLabel(m)),
                              // 모든 항목에 subtitle을 강제 표기하여 동일 높이
                              subtitle: Text(
                                '단위: ${usageMetricUnit(m).isEmpty ? '분' : usageMetricUnit(m)}',
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
                              ),
                              trailing: m == _usageMetric
                                  ? Icon(Icons.check, color: _metricColor(m))
                                  : null,
                              onTap: () => Navigator.of(ctx).pop(m),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: m == _usageMetric
                                      ? _metricColor(m)
                                      : cs.outlineVariant,
                                  width: m == _usageMetric ? 1.2 : 1,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (picked != null && mounted) setState(() => _usageMetric = picked);
  }


  @override
  Widget build(BuildContext context) {
    final weekStart = _mondayOf(_cursor);
    final weekEnd = weekStart.add(const Duration(days: 6));
    final title = '${weekStart.month}월 ${weekStart.day}일 - ${weekEnd.month}월 ${weekEnd.day}일';

    Map<String, List<bool>>? filteredMatrix;
    if (_matrix != null) {
      if (_filter == WeeklyFilter.all) {
        filteredMatrix = _matrix;
      } else {
        final key = switch (_filter) {
          WeeklyFilter.meal => 'meal',
          WeeklyFilter.walk => 'walk',
          WeeklyFilter.excretion => 'excretion',
          WeeklyFilter.health => 'health',
          WeeklyFilter.memo => 'memo',
          WeeklyFilter.all => 'meal',
        };
        filteredMatrix = {
          if (_matrix!.containsKey(key)) key: _matrix![key]!,
        };
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        SizedBox(
          height: 44,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: _prevWeek,
                  icon: const Icon(Icons.chevron_left),
                  constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                  padding: EdgeInsets.zero,
                  visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: _nextWeek,
                  icon: const Icon(Icons.chevron_right),
                  constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                  padding: EdgeInsets.zero,
                  visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                ),
              ),
              Center(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (_loading)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
        if (_error != null)
          Center(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)))),
        if (!_loading && _error == null && filteredMatrix != null && _summary != null) ...[
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SizedBox(
              height: 72,
              child: Row(
                children: List.generate(_summary!.length * 2 - 1, (i) {
                  if (i.isOdd) {
                    return Container(width: 1, height: 32, color: Colors.black.withOpacity(0.08));
                  }
                  final s = _summary![i ~/ 2];
                  return Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(s.value,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800, color: s.accent ?? Colors.black)),
                          const SizedBox(height: 2),
                          Text(s.label,
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: s.accent?.withOpacity(0.9) ?? Colors.black54,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 12),
          WeeklyStatsPanel(
            weekStart: weekStart,
            matrix: filteredMatrix!,
            summary: _summary!,
            showSummary: false,
          ),
          const SizedBox(height: 20),
          if (_lastWeekly != null)
            WeeklyAmountChart(
              weekStart: weekStart,
              records: _lastWeekly!.records,
              metric: _usageMetric,
              onTapChangeMetric: _openUsageMetricDialog,
            ),
        ],
      ],
    );
  }
}

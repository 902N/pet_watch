// lib/pages/stats/monthly/monthly_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../../widget/pet_id.dart';
import 'api/monthly_report_api.dart';
import 'api/anomaly_alerts_api.dart';
import 'models/monthly_report.dart';
import 'models/anomaly_alert.dart';
import 'widgets/header_bar.dart';
import 'widgets/achievement_card.dart';
import 'widgets/day_cell.dart';
import 'widgets/record_card.dart';
import 'widgets/card_footer.dart';
import 'utils/category_theme.dart';
import 'utils/date_utils_ext.dart';
import 'dialogs/category_picker.dart';
import 'dialogs/year_month_picker.dart';

// 라벤더 패널 팔레트
const kLavBg   = Color(0xFFF6EDFF);
const kLavLine = Color(0xFFE5D4FF);

// 라벤더 패널(바깥 카드)
Widget _panel({required Widget child}) {
  return Ink(
    decoration: BoxDecoration(
      color: kLavBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kLavLine),
      boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 6))],
    ),
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );
}

// 달력 보드(안쪽 하얀 라운드 박스)
Widget _calendarBoard({required Widget child}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: kLavLine),
      boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4))],
    ),
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
    child: child,
  );
}

/// HeaderBar 위에 중앙 타이틀을 오버레이해서 항상 보이도록 하는 래퍼(월간 전용)
class _CenteredHeader extends StatelessWidget {
  final Widget headerBar;
  final String title;
  const _CenteredHeader({required this.headerBar, required this.title});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Stack(
        children: [
          Positioned.fill(child: headerBar),
          IgnorePointer(
            child: Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MonthlyView extends StatefulWidget {
  const MonthlyView({super.key, this.petId, this.baseUrl});
  final int? petId;
  final String? baseUrl;

  @override
  State<MonthlyView> createState() => _MonthlyViewState();
}

class _MonthlyViewState extends State<MonthlyView> {
  DateTime _cursor = DateTime(DateTime.now().year, DateTime.now().month, 1);
  late final MonthlyReportApi _api;
  late final AnomalyAlertsApi _alertsApi;

  MonthlyReport? _report;
  List<AnomalyAlert> _alerts = [];
  Set<int> _anomalyMarked = {};

  bool _loading = false;
  String? _error;
  int? _lastPetId;

  RecordCategory _category = RecordCategory.all;

  @override
  void initState() {
    super.initState();
    final baseUrl = widget.baseUrl ?? dotenv.env['BASE_URL'] ?? '';
    _api = MonthlyReportApi(baseUrl: baseUrl);
    _alertsApi = AnomalyAlertsApi(baseUrl: baseUrl);
  }

  void _prevMonth() {
    setState(() => _cursor = DateTime(_cursor.year, _cursor.month - 1, 1));
    _load();
  }

  void _nextMonth() {
    setState(() => _cursor = DateTime(_cursor.year, _cursor.month + 1, 1));
    _load();
  }

  Future<void> _load() async {
    final int? effectivePetId = widget.petId ?? context.read<PetIdStore>().petId;
    if (effectivePetId == null) {
      setState(() {
        _report = null;
        _alerts = [];
        _anomalyMarked = {};
        _error = null;
        _loading = false;
        _lastPetId = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _lastPetId = effectivePetId;
    });
    try {
      final reportF = _api.fetchMonthly(petId: effectivePetId, monthAnchor: _cursor);
      final alertsF = _alertsApi.fetchAll(pageSize: 200);

      final results = await Future.wait([reportF, alertsF]);
      final MonthlyReport data = results[0] as MonthlyReport;
      final List<AnomalyAlert> alerts = results[1] as List<AnomalyAlert>;

      final am = <int>{};
      for (final a in alerts) {
        final dt = a.detectedAt; // anomaly_alert.dart에서 toLocal() 적용됨
        if (a.petId == effectivePetId &&
            dt.year == _cursor.year &&
            dt.month == _cursor.month) {
          am.add(dt.day);
        }
      }

      if (!mounted) return;
      setState(() {
        _report = data;
        _alerts = alerts;
        _anomalyMarked = am;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _ensureLoaded(PetIdStore store) {
    final currentPetId = widget.petId ?? store.petId;
    if (_loading) return;
    if (currentPetId != null && _lastPetId != currentPetId) {
      Future.microtask(() {
        if (mounted) _load();
      });
    }
  }

  Set<int> _markedDaysForCategory() => _markedDaysFor(_category);

  Set<int> _markedDaysFor(RecordCategory cat) {
    switch (cat) {
      case RecordCategory.all:
        final s = <int>{};
        if (_report != null) {
          s.addAll(normalizeDays(_report!.mealRecords.markedDays(_cursor), _cursor));
          s.addAll(normalizeDays(_report!.walkRecords.markedDays(_cursor), _cursor));
          s.addAll(normalizeDays(_report!.excretionRecords.markedDays(_cursor), _cursor));
          s.addAll(normalizeDays(_report!.healthRecords.markedDays(_cursor), _cursor));
          s.addAll(normalizeDays(_report!.freeRecords.markedDays(_cursor), _cursor)); // 자유기록(검정)
        }
        s.addAll(_anomalyMarked); // 이상기록(빨강)
        return s;

      case RecordCategory.meal:
        return _report == null ? {} : normalizeDays(_report!.mealRecords.markedDays(_cursor), _cursor);
      case RecordCategory.walk:
        return _report == null ? {} : normalizeDays(_report!.walkRecords.markedDays(_cursor), _cursor);
      case RecordCategory.excretion:
        return _report == null ? {} : normalizeDays(_report!.excretionRecords.markedDays(_cursor), _cursor);
      case RecordCategory.health:
        return _report == null ? {} : normalizeDays(_report!.healthRecords.markedDays(_cursor), _cursor);
      case RecordCategory.free:
        return _report == null ? {} : normalizeDays(_report!.freeRecords.markedDays(_cursor), _cursor);
      case RecordCategory.anomaly:
        return _anomalyMarked;
    }
  }

  String _rateTextForCategory() => _rateTextFor(_category);

  String _rateTextFor(RecordCategory cat) {
    if (cat == RecordCategory.all) {
      final days = DateUtils.getDaysInMonth(_cursor.year, _cursor.month);
      final successDays = _markedDaysFor(cat).length;
      final rate = (successDays * 100 / days).round();
      return '$rate%';
    }
    switch (cat) {
      case RecordCategory.meal:
        return _report == null ? '' : _report!.mealRecords.rateText;
      case RecordCategory.walk:
        return _report == null ? '' : _report!.walkRecords.rateText;
      case RecordCategory.excretion:
        return _report == null ? '' : _report!.excretionRecords.rateText;
      case RecordCategory.health:
        return _report == null ? '' : _report!.healthRecords.rateText;
      case RecordCategory.free:
        return _report == null ? '' : _report!.freeRecords.rateText;

    // === 이상기록: 달력만 보이게 → rate 숨김 ===
      case RecordCategory.anomaly:
        return '';

      case RecordCategory.all:
        final daysAll = DateUtils.getDaysInMonth(_cursor.year, _cursor.month);
        final successDaysAll = _markedDaysFor(cat).length;
        final rateAll = (successDaysAll * 100 / daysAll).round();
        return '$rateAll%';
    }
  }

  String _countTextForCategory() => _countTextFor(_category);

  String _countTextFor(RecordCategory cat) {
    if (cat == RecordCategory.all) {
      final successDays = _markedDaysFor(cat).length;
      return '기록일수 ${successDays}일';
    }
    switch (cat) {
      case RecordCategory.meal:
        return _report == null ? '' : _report!.mealRecords.countText;
      case RecordCategory.walk:
        return _report == null ? '' : _report!.walkRecords.countText;
      case RecordCategory.excretion:
        return _report == null ? '' : _report!.excretionRecords.countText;
      case RecordCategory.health:
        return _report == null ? '' : _report!.healthRecords.countText;
      case RecordCategory.free:
        return _report == null ? '' : _report!.freeRecords.countText;

    // === 이상기록: 달력만 보이게 → count 숨김 ===
      case RecordCategory.anomaly:
        return '';

      case RecordCategory.all:
        final successDays = _markedDaysFor(cat).length;
        return '기록일수 ${successDays}일';
    }
  }

  Future<void> _openCategoryPicker() async {
    final selected = await showCategoryPicker(context, current: _category);
    if (selected != null && mounted) setState(() => _category = selected);
  }

  Future<void> _openYearMonthPicker() async {
    final picked = await showYearMonthPicker(context, _cursor);
    if (picked != null && mounted) {
      setState(() => _cursor = picked);
      await _load();
    }
  }

  Future<void> _openCategoryModal(RecordCategory cat) async {
    final accent = CategoryTheme.colorOf(cat, context);
    const double _kLegendLeftPadding = 16;
    const double _kLegendDot = 10;

    final marked = _markedDaysFor(cat);
    final daysInMonth = DateUtils.getDaysInMonth(_cursor.year, _cursor.month);
    final firstWeekday = DateTime(_cursor.year, _cursor.month, 1).weekday % 7;
    final cells = firstWeekday + daysInMonth;
    final rows = ((cells + 6) ~/ 7);
    const cellHeight = 48.0;
    final calendarHeight = rows * (cellHeight + 8) - 8;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_cursor.year}년 ${_cursor.month}월 • ${CategoryTheme.labelOf(cat)}',
                          style: Theme.of(ctx).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ▼▼▼ 라벤더 패널 + 하얀 캘린더 보드 ▼▼▼
                  _panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // === 이상기록은 성취카드 숨김 ===
                        if (cat != RecordCategory.anomaly)
                          AchievementCard(
                            color: accent,
                            rateText: _rateTextFor(cat),
                            countText: _countTextFor(cat),
                          ),
                        if (cat != RecordCategory.anomaly) const SizedBox(height: 12),

                        _calendarBoard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: _kLegendLeftPadding),
                                child: Row(
                                  children: [
                                    Container(
                                      width: _kLegendDot,
                                      height: _kLegendDot,
                                      decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      cat == RecordCategory.anomaly ? '  이상' : (cat == RecordCategory.free ? '  메모' : '  성공'),
                                      style: Theme.of(ctx).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 28,
                                child: Row(
                                  children: const [
                                    Expanded(child: Center(child: Text('일', style: TextStyle(color: Colors.red)))),
                                    Expanded(child: Center(child: Text('월'))),
                                    Expanded(child: Center(child: Text('화'))),
                                    Expanded(child: Center(child: Text('수'))),
                                    Expanded(child: Center(child: Text('목'))),
                                    Expanded(child: Center(child: Text('금'))),
                                    Expanded(child: Center(child: Text('토', style: TextStyle(color: Colors.blue)))),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: calendarHeight,
                                child: GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.zero,
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 7,
                                    mainAxisSpacing: 8,
                                    crossAxisSpacing: 8,
                                    childAspectRatio: 1,
                                  ),
                                  itemCount: rows * 7,
                                  itemBuilder: (context, index) {
                                    final dayNum = index - firstWeekday + 1;
                                    final inMonth = dayNum >= 1 && dayNum <= daysInMonth;
                                    final success = inMonth && marked.contains(dayNum);
                                    final weekday = DateTime(_cursor.year, _cursor.month, inMonth ? dayNum : 1).weekday % 7;
                                    return DayCell(
                                      day: inMonth ? dayNum : null,
                                      accent: accent,
                                      success: success,
                                      isToday: inMonth &&
                                          _cursor.year == DateTime.now().year &&
                                          _cursor.month == DateTime.now().month &&
                                          dayNum == DateTime.now().day,
                                      weekendColor: weekday == 0 ? Colors.red : (weekday == 6 ? Colors.blue : null),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ▲▲▲ 끝 ▲▲▲

                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      setState(() => _category = cat);
                      Navigator.pop(ctx);
                    },
                    child: const Text('이 카테고리로 보기'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PetIdStore>();
    _ensureLoaded(store);

    const double _kLegendLeftPadding = 16;
    const double _kLegendDot = 10;

    final title = '${_cursor.year}년 ${_cursor.month}월';
    final catColor = CategoryTheme.colorOf(_category, context);

    // 이상기록은 리포트 없어도 보여야 함(알림 기반)
    final showEmptyScreen = _error != null || (_report == null && _category != RecordCategory.anomaly);

    if (showEmptyScreen) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          _CenteredHeader(
            title: title,
            headerBar: Theme(
              data: Theme.of(context).copyWith(
                textTheme: Theme.of(context).textTheme.copyWith(
                  titleMedium: const TextStyle(color: Colors.transparent),
                ),
              ),
              child: HeaderBar(
                title: title,
                onPrev: _prevMonth,
                onNext: _nextMonth,
                onTitleTap: _openYearMonthPicker,
                categoryText: CategoryTheme.labelOf(_category),
                onCategoryTap: _openCategoryPicker,
                categoryColor: catColor,
                isAll: _category == RecordCategory.all,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_error != null) ...[
            Text('오류: $_error'),
            const SizedBox(height: 8),
            FilledButton(onPressed: _load, child: const Text('다시 시도')),
          ] else
            const Center(child: Padding(padding: EdgeInsets.only(top: 24), child: Text('데이터가 없습니다.'))),
        ],
      );
    }

    final r = _report!;
    final accent = CategoryTheme.colorOf(_category, context);

    if (_category == RecordCategory.all) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          _CenteredHeader(
            title: title,
            headerBar: Theme(
              data: Theme.of(context).copyWith(
                textTheme: Theme.of(context).textTheme.copyWith(
                  titleMedium: const TextStyle(color: Colors.transparent),
                ),
              ),
              child: HeaderBar(
                title: title,
                onPrev: _prevMonth,
                onNext: _nextMonth,
                onTitleTap: _openYearMonthPicker,
                categoryText: CategoryTheme.labelOf(_category),
                onCategoryTap: _openCategoryPicker,
                categoryColor: catColor,
                isAll: true,
              ),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (ctx, cons) {
              final double cardHeight = RecordCard.gridItemHeight(ctx) + 12;
              return GridView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: cardHeight,
                ),
                children: [
                  GestureDetector(
                    onTap: () => _openCategoryModal(RecordCategory.meal),
                    child: RecordCard(
                      icon: const Icon(Icons.restaurant, size: 18),
                      title: '식사 기록',
                      accent: CategoryTheme.meal,
                      titleColor: CategoryTheme.meal,
                      iconColor: CategoryTheme.meal,
                      monthAnchor: _cursor,
                      markedDays: normalizeDays(r.mealRecords.markedDays(_cursor), _cursor),
                      footer: CardFooter(rateText: r.mealRecords.rateText, countText: r.mealRecords.countText),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _openCategoryModal(RecordCategory.walk),
                    child: RecordCard(
                      icon: const Icon(Icons.pets, size: 18),
                      title: '산책 기록',
                      accent: CategoryTheme.walk,
                      titleColor: CategoryTheme.walk,
                      iconColor: CategoryTheme.walk,
                      monthAnchor: _cursor,
                      markedDays: normalizeDays(r.walkRecords.markedDays(_cursor), _cursor),
                      footer: CardFooter(rateText: r.walkRecords.rateText, countText: r.walkRecords.countText),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _openCategoryModal(RecordCategory.excretion),
                    child: RecordCard(
                      icon: const Icon(Icons.water_drop, size: 18),
                      title: '배변 기록',
                      accent: CategoryTheme.excretion,
                      titleColor: CategoryTheme.excretion,
                      iconColor: CategoryTheme.excretion,
                      monthAnchor: _cursor,
                      markedDays: normalizeDays(r.excretionRecords.markedDays(_cursor), _cursor),
                      footer: CardFooter(rateText: r.excretionRecords.rateText, countText: r.excretionRecords.countText),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _openCategoryModal(RecordCategory.health),
                    child: RecordCard(
                      icon: const Icon(Icons.favorite, size: 18),
                      title: '건강 기록',
                      accent: CategoryTheme.health,
                      titleColor: CategoryTheme.health,
                      iconColor: CategoryTheme.health,
                      monthAnchor: _cursor,
                      markedDays: normalizeDays(r.healthRecords.markedDays(_cursor), _cursor),
                      footer: CardFooter(rateText: r.healthRecords.rateText, countText: r.healthRecords.countText),
                    ),
                  ),

                  // 자유기록(검정)
                  GestureDetector(
                    onTap: () => _openCategoryModal(RecordCategory.free),
                    child: RecordCard(
                      icon: const Icon(Icons.edit_note, size: 18),
                      title: '자유 기록',
                      accent: CategoryTheme.free,
                      titleColor: Colors.black,
                      iconColor: Colors.black,
                      monthAnchor: _cursor,
                      markedDays: normalizeDays(r.freeRecords.markedDays(_cursor), _cursor),
                      footer: CardFooter(
                        rateText: r.freeRecords.rateText,
                        countText: r.freeRecords.countText,
                      ),
                    ),
                  ),

                  // 이상기록(빨강) — 달력만, 푸터 비움
                  GestureDetector(
                    onTap: () => _openCategoryModal(RecordCategory.anomaly),
                    child: RecordCard(
                      icon: const Icon(Icons.warning_amber_rounded, size: 18),
                      title: '이상 기록',
                      accent: CategoryTheme.anomaly,
                      titleColor: CategoryTheme.anomaly,
                      iconColor: CategoryTheme.anomaly,
                      monthAnchor: _cursor,
                      markedDays: _anomalyMarked,
                      footer: const CardFooter(
                        rateText: '',
                        countText: '',
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      );
    }

    final marked = _markedDaysForCategory();
    final daysInMonth = DateUtils.getDaysInMonth(_cursor.year, _cursor.month);
    final firstWeekday = DateTime(_cursor.year, _cursor.month, 1).weekday % 7;
    final cells = firstWeekday + daysInMonth;
    final rows = ((cells + 6) ~/ 7);
    const cellHeight = 48.0;
    final calendarHeight = rows * (cellHeight + 8) - 8;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        // ▶ HeaderBar 제목 투명 + 중앙 오버레이
        _CenteredHeader(
          title: title,
          headerBar: Theme(
            data: Theme.of(context).copyWith(
              textTheme: Theme.of(context).textTheme.copyWith(
                titleMedium: const TextStyle(color: Colors.transparent),
              ),
            ),
            child: HeaderBar(
              title: title,
              onPrev: _prevMonth,
              onNext: _nextMonth,
              onTitleTap: _openYearMonthPicker,
              categoryText: CategoryTheme.labelOf(_category),
              onCategoryTap: _openCategoryPicker,
              categoryColor: catColor,
              isAll: false,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // ▼▼▼ 단일 카테고리 화면: 라벤더 패널 + 하얀 캘린더 보드 ▼▼▼
        _panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === 이상기록은 성취카드 숨김 ===
              if (_category != RecordCategory.anomaly)
                AchievementCard(
                  color: accent,
                  rateText: _rateTextForCategory(),
                  countText: _countTextForCategory(),
                ),
              if (_category != RecordCategory.anomaly) const SizedBox(height: 12),

              _calendarBoard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _category == RecordCategory.anomaly
                                ? '  이상'
                                : (_category == RecordCategory.free ? '  메모' : '  성공'),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 28,
                      child: Row(
                        children: const [
                          Expanded(child: Center(child: Text('일', style: TextStyle(color: Colors.red)))),
                          Expanded(child: Center(child: Text('월'))),
                          Expanded(child: Center(child: Text('화'))),
                          Expanded(child: Center(child: Text('수'))),
                          Expanded(child: Center(child: Text('목'))),
                          Expanded(child: Center(child: Text('금'))),
                          Expanded(child: Center(child: Text('토', style: TextStyle(color: Colors.blue)))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: calendarHeight,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 1,
                        ),
                        itemCount: rows * 7,
                        itemBuilder: (context, index) {
                          final dayNum = index - firstWeekday + 1;
                          final inMonth = dayNum >= 1 && dayNum <= daysInMonth;
                          final success = inMonth && marked.contains(dayNum);
                          final weekday = DateTime(_cursor.year, _cursor.month, inMonth ? dayNum : 1).weekday % 7;
                          return DayCell(
                            day: inMonth ? dayNum : null,
                            accent: accent,
                            success: success,
                            isToday: inMonth &&
                                _cursor.year == DateTime.now().year &&
                                _cursor.month == DateTime.now().month &&
                                dayNum == DateTime.now().day,
                            weekendColor: weekday == 0 ? Colors.red : (weekday == 6 ? Colors.blue : null),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // ▲▲▲ 끝 ▲▲▲
      ],
    );
  }
}

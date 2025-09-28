// lib/pages/home_screen/controllers/home_screen_controller.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/schedule.dart';
import '../utils/schedule_utils.dart';
import '../record/models/record_api_models.dart';
import '../record/services/record_api_service.dart';
import '../services/record_cache_service.dart';
import '../record/utils/toilet_condition_mapper.dart';

class HomeScreenController extends ChangeNotifier {
  static const String _schedulesCachePrefix = 'schedules_';
  static const String _monthRecordsCachePrefix = 'month_records_';
  static const String _dayRecordsCachePrefix = 'day_records_';

  final RecordCacheService _cache = RecordCacheService();

  List<Schedule> _schedules = [];
  DateTime _selectedDate = DateTime.utc(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  bool _isLoadingDayRecords = false;
  final bool _isSwitchingPet = false;

  List<Schedule>? _filteredCache;
  DateTime? _lastFilterDate;
  Map<DateTime, List<Schedule>>? _schedulesByDateCache;
  List<Schedule>? _lastSchedulesForMapping;

  List<Schedule> get schedules => _schedules;
  DateTime get selectedDate => _selectedDate;
  bool get isLoadingDayRecords => _isLoadingDayRecords;
  bool get isSwitchingPet => _isSwitchingPet;

  List<Schedule> get filteredSchedules {
    if (_filteredCache != null &&
        _lastFilterDate != null &&
        ScheduleUtils.isSameDay(_lastFilterDate!, _selectedDate)) {
      return _filteredCache!;
    }
    final raw = ScheduleUtils.filterSchedulesByDate(_schedules, _selectedDate);
    final result = raw.where(_isApiSchedule).toList();
    _filteredCache = result;
    _lastFilterDate = _selectedDate;
    return result;
  }

  int get selectedDateCount => filteredSchedules.length;

  Map<DateTime, List<Schedule>> get schedulesByDate {
    if (_schedulesByDateCache != null &&
        _lastSchedulesForMapping != null &&
        _lastSchedulesForMapping!.length == _schedules.length &&
        ScheduleUtils.areScheduleListsEqual(_lastSchedulesForMapping!, _schedules)) {
      return _schedulesByDateCache!;
    }

    final Map<DateTime, List<Schedule>> map = {};
    for (final s in _schedules) {
      final key = DateTime(s.date.year, s.date.month, s.date.day);
      (map[key] ??= []).add(s);
    }

    final currentMonth = DateTime(_selectedDate.year, _selectedDate.month);
    final previousMonth = DateTime(_selectedDate.year, _selectedDate.month - 1);
    final nextMonth = DateTime(_selectedDate.year, _selectedDate.month + 1);
    final monthsToCheck = [previousMonth, currentMonth, nextMonth];

    final Map<DateTime, Set<String>> existingCategoriesByDate = {};
    for (final s in _schedules) {
      final key = DateTime(s.date.year, s.date.month, s.date.day);
      (existingCategoriesByDate[key] ??= <String>{}).add(s.category ?? '');
    }

    for (final month in monthsToCheck) {
      final allKeys = _cache.getAllKeys();
      final matchingKeys = allKeys.where((key) =>
      key.startsWith(_monthRecordsCachePrefix) &&
          key.endsWith('-${month.year}-${month.month}')).toList();

      for (final cacheKey in matchingKeys) {
        final monthData = _cache.get<MonthRecordsResponse>(cacheKey);
        if (monthData != null) {
          for (final dailyRecord in monthData.dailyRecords) {
            final date = DateTime.parse(dailyRecord.date);
            final key = DateTime(date.year, date.month, date.day);
            for (final category in dailyRecord.recordedCategories) {
              if (!(existingCategoriesByDate[key]?.contains(category) ?? false)) {
                (map[key] ??= []).add(
                  Schedule(
                    id: 'api_marker_${dailyRecord.date}_$category',
                    date: date,
                    startHour: 0,
                    startMinute: 0,
                    content: '',
                    category: category,
                    categoryData: const {},
                  ),
                );
              }
            }
          }
        }
      }
    }

    _schedulesByDateCache = map;
    _lastSchedulesForMapping = List.from(_schedules);
    return map;
  }

  Future<void> initialize({
    required int? petId,
    required String? accessToken,
  }) async {
    if (petId == null || accessToken == null) return;
    await clearAllPetData();
    clearAllCaches();
    await _loadPersistedData(petId);
    await _loadAllVisibleMonthRecords(petId, accessToken);
    await _loadDayRecords(petId, accessToken, force: true);
    notifyListeners();
  }

  Future<void> changeSelectedDate(
      DateTime newDate, {
        required int? petId,
        required String? accessToken,
      }) async {
    _selectedDate = DateTime.utc(newDate.year, newDate.month, newDate.day);
    _invalidateViewCaches();
    if (petId != null && accessToken != null) {
      await _loadDayRecords(petId, accessToken, force: true);
    }
    notifyListeners();
  }

  void addSchedule(Schedule schedule) {
    _schedules.add(schedule);
    _invalidateViewCaches();
    notifyListeners();
  }

  Future<void> refreshData({
    required int? petId,
    required String? accessToken,
  }) async {
    if (petId == null || accessToken == null) return;
    await _loadPersistedData(petId);
    await _loadAllVisibleMonthRecords(petId, accessToken);
    await _loadDayRecords(petId, accessToken, force: true);
    notifyListeners();
  }

  Future<void> refreshMonthRecordsForDate({
    required int petId,
    required String accessToken,
    required DateTime date,
  }) async {
    final year = date.year;
    final month = date.month;
    final cacheKey = '$_monthRecordsCachePrefix$petId-$year-$month';
    _cache.remove(cacheKey);
    await _loadMonthRecordsForSpecificMonth(petId, accessToken, year, month);
    _invalidateViewCaches();
    notifyListeners();
  }

  void clearDayCache(int petId, DateTime date) {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final dkey = '$_dayRecordsCachePrefix$petId-$dateStr';
    _cache.remove(dkey);
    notifyListeners();
  }

  bool _isApiSchedule(Schedule s) {
    final v = s.categoryData?['apiRecordId'];
    if (v is int) return true;
    if (v is String && int.tryParse(v) != null) return true;
    return s.id.startsWith('api_');
  }

  Future<void> _loadPersistedData(int petId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_schedulesCachePrefix$petId';
      final schedulesJson = prefs.getString(key);
      if (schedulesJson != null) {
        final List<dynamic> schedulesList = jsonDecode(schedulesJson);
        final list = <Schedule>[];
        for (final json in schedulesList) {
          list.add(Schedule(
            id: json['id'],
            date: DateTime.parse(json['date']),
            startHour: json['startHour'],
            startMinute: json['startMinute'] ?? 0,
            content: json['content'],
            category: json['category'],
            memo: json['memo'],
            isDone: json['isDone'] ?? false,
            categoryData: json['categoryData'] != null
                ? Map<String, dynamic>.from(json['categoryData'])
                : null,
          ));
        }
        _schedules = list;
        _invalidateViewCaches();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading persisted data: $e');
      }
    }
  }

  Future<void> savePersistedData(int petId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_schedulesCachePrefix$petId';
      final schedulesJson = jsonEncode(
        _schedules
            .map((schedule) => {
          'id': schedule.id,
          'date': schedule.date.toIso8601String(),
          'startHour': schedule.startHour,
          'startMinute': schedule.startMinute,
          'content': schedule.content,
          'category': schedule.category,
          'memo': schedule.memo,
          'isDone': schedule.isDone,
          'categoryData': schedule.categoryData,
        })
            .toList(),
      );
      await prefs.setString(key, schedulesJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving persisted data: $e');
      }
    }
  }

  Future<void> _loadAllVisibleMonthRecords(int petId, String accessToken) async {
    final currentMonth = DateTime(_selectedDate.year, _selectedDate.month);
    final previousMonth = DateTime(_selectedDate.year, _selectedDate.month - 1);
    final nextMonth = DateTime(_selectedDate.year, _selectedDate.month + 1);
    final monthsToLoad = [previousMonth, currentMonth, nextMonth];
    final futures = monthsToLoad.map((month) =>
        _loadMonthRecordsForSpecificMonth(petId, accessToken, month.year, month.month));
    await Future.wait(futures);
  }

  Future<void> _loadMonthRecordsForSpecificMonth(int petId, String accessToken, int year, int month) async {
    final cacheKey = '$_monthRecordsCachePrefix$petId-$year-$month';
    if (_cache.get<MonthRecordsResponse>(cacheKey) != null) return;
    try {
      final response = await RecordApiService.getMonthRecords(
        petId: petId,
        accessToken: accessToken,
        year: year,
        month: month,
      );
      if (response.success && response.data != null) {
        _cache.set(cacheKey, response.data!);
        _schedulesByDateCache = null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading month records for $year-$month: $e');
      }
    }
  }

  Future<void> _loadDayRecords(int petId, String accessToken, {bool force = false}) async {
    final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    final cacheKey = '$_dayRecordsCachePrefix$petId-$dateStr';
    if (!force && _cache.get<DayRecordsResponse>(cacheKey) != null) return;

    _isLoadingDayRecords = true;
    notifyListeners();

    try {
      final response = await RecordApiService.getDayRecords(
        petId: petId,
        accessToken: accessToken,
        year: _selectedDate.year,
        month: _selectedDate.month,
        day: _selectedDate.day,
      );
      if (response.success && response.data != null) {
        _cache.set(cacheKey, response.data!);
        _updateSchedulesFromApiData(response.data!);
        await savePersistedData(petId);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading day records: $e');
      }
    } finally {
      _isLoadingDayRecords = false;
      notifyListeners();
    }
  }

  void _updateSchedulesFromApiData(DayRecordsResponse dayData) {
    final dayKey = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

    _schedules.removeWhere((s) =>
    s.date.year == dayKey.year &&
        s.date.month == dayKey.month &&
        s.date.day == dayKey.day);

    final newSchedules = <Schedule>[];

    int parseHour(String? hhmm) {
      if (hhmm == null || hhmm.isEmpty) return 0;
      final m = RegExp(r'^(\d{2}):(\d{2})').firstMatch(hhmm);
      if (m == null) return 0;
      return int.tryParse(m.group(1)!) ?? 0;
    }

    int parseMinute(String? hhmm) {
      if (hhmm == null || hhmm.isEmpty) return 0;
      final m = RegExp(r'^(\d{2}):(\d{2})').firstMatch(hhmm);
      if (m == null) return 0;
      return int.tryParse(m.group(2)!) ?? 0;
    }

    for (final meal in dayData.mealRecords) {
      final hh = parseHour(meal.recordTime);
      final mm = parseMinute(meal.recordTime);
      newSchedules.add(Schedule(
        id: 'api_meal_${meal.id}',
        date: dayKey,
        startHour: hh,
        startMinute: mm,
        content: '밥 ${meal.amount}g (${meal.type}${meal.detail.isNotEmpty ? ' - ${meal.detail}' : ''})',
        category: 'meal',
        categoryData: {
          'mealAmount': meal.amount,
          'mealType': meal.type,
          'mealDetail': meal.detail,
          'apiRecordId': meal.id,
        },
      ));
    }

    for (final walk in dayData.walkRecords) {
      final hh = parseHour(walk.recordTime);
      final mm = parseMinute(walk.recordTime);
      newSchedules.add(Schedule(
        id: 'api_walk_${walk.id}',
        date: dayKey,
        startHour: hh,
        startMinute: mm,
        content: '산책 ${walk.duration}분 (${walk.intensity})',
        category: 'walk',
        categoryData: {
          'walkDuration': walk.duration,
          'walkIntensity': walk.intensity,
          'apiRecordId': walk.id,
        },
      ));
    }

    for (final excretion in dayData.excretionRecords) {
      final hh = parseHour(excretion.recordTime);
      final mm = parseMinute(excretion.recordTime);
      newSchedules.add(Schedule(
        id: 'api_toilet_${excretion.id}',
        date: dayKey,
        startHour: hh,
        startMinute: mm,
        content: '배변 ${excretion.type} (${ToiletConditionMapper.toUiValue(excretion.condition)})',
        category: 'toilet',
        categoryData: {
          'toiletType': excretion.type,
          'toiletCondition': excretion.condition,
          'toiletImageUrl': excretion.imageUrl,
          'apiRecordId': excretion.id,
        },
      ));
    }

    for (final health in dayData.healthRecords) {
      final hh = parseHour(health.recordTime);
      final mm = parseMinute(health.recordTime);
      newSchedules.add(Schedule(
        id: 'api_health_${health.id}',
        date: dayKey,
        startHour: hh,
        startMinute: mm,
        content: '건강 - ${health.symptomDescription.length > 20 ? '${health.symptomDescription.substring(0, 20)}...' : health.symptomDescription}',
        category: 'health',
        categoryData: {
          'symptomDescription': health.symptomDescription,
          'healthImageUrl': health.imgUrl,
          'apiRecordId': health.id,
        },
      ));
    }

    for (final free in dayData.freeRecords) {
      final hh = parseHour(free.recordTime);
      final mm = parseMinute(free.recordTime);
      newSchedules.add(Schedule(
        id: 'api_memo_${free.id}',
        date: dayKey,
        startHour: hh,
        startMinute: mm,
        content: free.content.length > 20 ? '${free.content.substring(0, 20)}...' : free.content,
        category: 'memo',
        categoryData: {
          'memoContent': free.content,
          'memoImageUrl': free.imgUrl,
          'apiRecordId': free.id,
        },
      ));
    }

    _schedules.addAll(newSchedules);
    _invalidateViewCaches();
  }

  int? extractApiId(Schedule s) {
    final v = s.categoryData?['apiRecordId'];
    if (v is int) return v;
    if (v is String) {
      final n = int.tryParse(v);
      if (n != null) return n;
    }
    final m = RegExp(r'^api_(?:meal|walk|toilet|health|memo)_(\d+)$').firstMatch(s.id);
    if (m != null) return int.tryParse(m.group(1)!);
    return null;
  }

  void _invalidateViewCaches() {
    _filteredCache = null;
    _lastFilterDate = null;
    _schedulesByDateCache = null;
    _lastSchedulesForMapping = null;
  }

  void invalidateViewCaches() {
    _invalidateViewCaches();
  }

  Future<void> clearAllPetData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('schedules_') ||
          key.startsWith('month_records_') ||
          key.startsWith('day_records_')) {
        await prefs.remove(key);
      }
    }
  }

  void clearAllCaches() {
    _cache.clear();
    _invalidateViewCaches();
    _schedules = [];
    _schedulesByDateCache = null;
  }

  Future<void> switchPet({required int petId, required String accessToken}) async {
    await clearAllPetData();
    clearAllCaches();
    notifyListeners();
    await _loadPersistedData(petId);
    await _loadAllVisibleMonthRecords(petId, accessToken);
    await _loadDayRecords(petId, accessToken, force: true);
    notifyListeners();
  }

  @override
  void dispose() {
    _cache.cleanup();
    super.dispose();
  }
}

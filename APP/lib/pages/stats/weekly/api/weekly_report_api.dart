import 'package:dio/dio.dart';
import '../models/weekly_report.dart';
import '../../../../auth/auth_api.dart';

class WeeklyReportApi {
  final Dio _dio;
  WeeklyReportApi({Dio? dio}) : _dio = dio ?? AuthApi.client;

  // ───────────────────────────────── fetchWeekly
  Future<WeeklyReportData> fetchWeekly({
    required int petId,
    required DateTime weekStart,
  }) async {
    final res = await _dio.get(
      '/pets/$petId/reports/weekly',
      queryParameters: {'startDate': _ymd(weekStart)},
      options: Options(
        headers: {'Accept': '*/*'},
        validateStatus: (s) => (s ?? 500) >= 200 && (s ?? 500) < 600,
      ),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed weekly (HTTP ${res.statusCode}): ${res.data}');
    }
    final env = WeeklyReportEnvelope.fromJson(res.data as Map<String, dynamic>);
    if (!env.success) {
      throw Exception('Weekly success=false (status=${env.status}, message=${env.message})');
    }
    return env.data;
  }

  // ───────────────────────────────── fetchWeeklyMatrix
  Future<Map<String, List<bool>>> fetchWeeklyMatrix({
    required int petId,
    required DateTime weekStart,
  }) async {
    final data = await fetchWeekly(petId: petId, weekStart: weekStart);

    // 1) records[].anomalyAlerts 기반
    final anomalyFromRecords = _anomalyDaysFromRecords(
      records: data.records,
      weekStart: weekStart,
    );

    // 2) /pets/{petId}/alerts 기반(UTC → Local 변환 후 날짜 비교)
    List<bool> anomalyFromAlerts = List<bool>.filled(7, false);
    try {
      anomalyFromAlerts = await _anomalyDaysFromPetAlerts(
        petId: petId,
        weekStart: weekStart,
      );
    } catch (_) {}

    // 3) OR 병합
    final anomalyDays = _orDays(anomalyFromRecords, anomalyFromAlerts);

    // 디버그 확인용
    // ignore: avoid_print
    print('[weekly] anomaly(rec)=$anomalyFromRecords anomaly(alerts)=$anomalyFromAlerts merged=$anomalyDays');

    return toWeeklyMatrix(
      data.records,
      weekStart: weekStart,
      anomalyDays: anomalyDays,
    );
  }

  // ───────────────────────────────── Matrix 변환
  static Map<String, List<bool>> toWeeklyMatrix(
      List<WeeklyRecord> records, {
        required DateTime weekStart,
        List<bool>? anomalyDays,
      }) {
    bool _gt0(num? v) => (v ?? 0) > 0;

    final meal = List<bool>.filled(7, false);
    final walk = List<bool>.filled(7, false);
    final excretion = List<bool>.filled(7, false);
    final health = List<bool>.filled(7, false);
    final free = List<bool>.filled(7, false);

    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);

    DateTime? _recordDate(WeeklyRecord r) {
      final raw = (r as dynamic).date?.toString();
      if (raw == null || raw.isEmpty) return null;
      try {
        // records[].date는 'yyyy-MM-dd' → 타임존 영향 없음
        return DateTime.parse(raw);
      } catch (_) {
        return null;
      }
    }

    for (final r in records) {
      final dt = _recordDate(r);
      if (dt == null) continue;
      final i = dt.difference(start).inDays;
      if (i < 0 || i > 6) continue;

      if (_gt0(r.mealAmount) || _gt0(r.snackAmount)) meal[i] = true;
      if (_gt0(r.walkTime) || ((r.walkIntensity ?? '').toString().trim().isNotEmpty)) walk[i] = true;

      final exCnt = (r as dynamic).excretionRecords as int? ?? 0;
      if (exCnt > 0) excretion[i] = true;

      final hCnt = (r as dynamic).healthRecords as int? ?? 0;
      if (hCnt > 0) health[i] = true;

      final fCnt = (r as dynamic).freeRecords as int? ?? 0;
      if (fCnt > 0) free[i] = true;
    }

    final anomaly = (anomalyDays != null && anomalyDays.length == 7)
        ? anomalyDays
        : List<bool>.filled(7, false);

    return {
      'meal': meal,
      'walk': walk,
      'excretion': excretion,
      'health': health,
      'memo': free,        // 자유
      'anomaly': anomaly,  // 이상
    };
  }

  // ───────────────────────────────── records -> anomaly days
  static List<bool> _anomalyDaysFromRecords({
    required List<WeeklyRecord> records,
    required DateTime weekStart,
  }) {
    final out = List<bool>.filled(7, false);
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);

    DateTime? _recordDate(WeeklyRecord r) {
      final raw = (r as dynamic).date?.toString();
      if (raw == null || raw.isEmpty) return null;
      try { return DateTime.parse(raw); } catch (_) { return null; }
    }

    for (final r in records) {
      final dt = _recordDate(r);
      if (dt == null) continue;
      final idx = dt.difference(start).inDays;
      if (idx < 0 || idx > 6) continue;

      final cnt = (r as dynamic).anomalyAlerts as int? ?? 0;
      if (cnt > 0) out[idx] = true;
    }
    return out;
  }

  // ───────────────────────────────── alerts -> anomaly days (UTC → Local 날짜로 계산)
  Future<List<bool>> _anomalyDaysFromPetAlerts({
    required int petId,
    required DateTime weekStart,
  }) async {
    // 주의: 로컬 자정 기준 날짜로 비교
    DateTime _localDateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

    final startLocal = _localDateOnly(DateTime(weekStart.year, weekStart.month, weekStart.day));
    final endLocal = _localDateOnly(startLocal.add(const Duration(days: 6)));

    final perDay = List<bool>.filled(7, false);
    int page = 0;
    const size = 200;

    while (true) {
      final res = await _dio.get(
        '/pets/$petId/alerts',
        queryParameters: {'page': page, 'size': size},
        options: Options(
          headers: {'Accept': '*/*'},
          validateStatus: (s) => (s ?? 500) >= 200 && (s ?? 500) < 600,
        ),
      );
      if (res.statusCode != 200) break;

      final body = res.data;
      final data = (body is Map<String, dynamic>)
          ? (body['data'] is Map<String, dynamic> ? body['data'] as Map<String, dynamic> : body)
          : <String, dynamic>{};

      final alerts = (data['alerts'] as List<dynamic>? ?? const []);
      for (final a in alerts) {
        if (a is! Map<String, dynamic>) continue;
        final ts = a['detectedAt'] as String?;
        if (ts == null || ts.isEmpty) continue;

        // 1) ISO → UTC DateTime → Local 변환
        final local = DateTime.parse(ts).toLocal();
        final day = _localDateOnly(local);

        // 2) 주 범위 포함 여부 (포함 비교)
        if (day.isBefore(startLocal) || day.isAfter(endLocal)) continue;

        // 3) 인덱스 계산
        final idx = day.difference(startLocal).inDays;
        if (idx >= 0 && idx < 7) perDay[idx] = true;
      }

      final hasNext = data['hasNext'] == true;
      if (!hasNext) break;
      page += 1;
    }

    // ignore: avoid_print
    print('[weekly] alerts(local) ${_ymd(startLocal)}~${_ymd(endLocal)} => $perDay');
    return perDay;
  }

  // ───────────────────────────────── helpers
  List<bool> _orDays(List<bool> a, List<bool> b) =>
      List<bool>.generate(7, (i) => (a.length > i && a[i]) || (b.length > i && b[i]));

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

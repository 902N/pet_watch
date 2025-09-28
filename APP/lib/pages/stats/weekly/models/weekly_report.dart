import 'dart:convert';

/// ---------- 데이터 모델 ----------

class WeeklyRecord {
  final DateTime date;

  // 카운트
  final int mealRecords;
  final int walkRecords;
  final int excretionRecords;
  final int healthRecords;
  final int freeRecords;

  // 주간 집계/이상신호
  final int anomalyAlerts;
  final int mealAmount;   // g
  final int snackAmount;  // g
  final int waterAmount;  // ml
  final int walkTime;     // 분
  final String walkIntensity;

  const WeeklyRecord({
    required this.date,
    required this.mealRecords,
    required this.walkRecords,
    required this.excretionRecords,
    required this.healthRecords,
    required this.freeRecords,
    required this.anomalyAlerts,
    required this.mealAmount,
    required this.snackAmount,
    required this.waterAmount,
    required this.walkTime,
    required this.walkIntensity,
  });

  factory WeeklyRecord.fromJson(Map<String, dynamic> json) {
    return WeeklyRecord(
      date: _parseDate(json['date']),
      mealRecords: _toInt(json['mealRecords']),
      walkRecords: _toInt(json['walkRecords']),
      excretionRecords: _toInt(json['excretionRecords']),
      healthRecords: _toInt(json['healthRecords']),
      freeRecords: _toInt(json['freeRecords']),
      anomalyAlerts: _toInt(json['anomalyAlerts']),
      mealAmount: _toInt(json['mealAmount']),
      snackAmount: _toInt(json['snackAmount']),
      waterAmount: _toInt(json['waterAmount']),
      walkTime: _toInt(json['walkTime']),
      walkIntensity: (json['walkIntensity'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'date': _formatYMD(date),
    'mealRecords': mealRecords,
    'walkRecords': walkRecords,
    'excretionRecords': excretionRecords,
    'healthRecords': healthRecords,
    'freeRecords': freeRecords,
    'anomalyAlerts': anomalyAlerts,
    'mealAmount': mealAmount,
    'snackAmount': snackAmount,
    'waterAmount': waterAmount,
    'walkTime': walkTime,
    'walkIntensity': walkIntensity,
  };

  static int _toInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;

  static DateTime _parseDate(String? s) {
    if (s == null) return DateTime.now();
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(s);
    if (m != null) {
      return DateTime(int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!));
    }
    return DateTime.tryParse(s) ?? DateTime.now();
  }

  static String _formatYMD(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class WeeklyReportData {
  final List<WeeklyRecord> records;
  final int weekRecordCount;
  final int weekNoneRecordCount;
  final int weekAnomalyCount;

  const WeeklyReportData({
    required this.records,
    required this.weekRecordCount,
    required this.weekNoneRecordCount,
    required this.weekAnomalyCount,
  });

  factory WeeklyReportData.fromJson(Map<String, dynamic> json) {
    final list = (json['records'] as List? ?? const [])
        .map((e) => WeeklyRecord.fromJson(e as Map<String, dynamic>))
        .toList();

    return WeeklyReportData(
      records: list,
      weekRecordCount: WeeklyRecord._toInt(json['weekRecordCount']),
      weekNoneRecordCount: WeeklyRecord._toInt(json['weekNoneRecordCount']),
      weekAnomalyCount: WeeklyRecord._toInt(json['weekAnomalyCount']),
    );
  }

  Map<String, dynamic> toJson() => {
    'records': records.map((e) => e.toJson()).toList(),
    'weekRecordCount': weekRecordCount,
    'weekNoneRecordCount': weekNoneRecordCount,
    'weekAnomalyCount': weekAnomalyCount,
  };
}

class WeeklyReportEnvelope {
  final bool success;
  final int status;
  final DateTime? timestamp;
  final String? message;
  final WeeklyReportData data;

  WeeklyReportEnvelope({
    required this.success,
    required this.status,
    required this.timestamp,
    required this.message,
    required this.data,
  });

  factory WeeklyReportEnvelope.fromJson(Map<String, dynamic> json) {
    return WeeklyReportEnvelope(
      success: json['success'] ?? false,
      status: json['status'] ?? 0,
      timestamp: json['timestamp'] != null ? DateTime.tryParse('${json['timestamp']}') : null,
      message: json['message']?.toString(),
      data: WeeklyReportData.fromJson(json['data'] ?? const {}),
    );
  }

  static WeeklyReportEnvelope fromJsonStr(String body) =>
      WeeklyReportEnvelope.fromJson(jsonDecode(body));
}

/// ---------- UI 변환 헬퍼 ----------

/// 보드용: 기록 존재 여부(7칸)
Map<String, List<bool>> toWeeklyMatrix(List<WeeklyRecord> records) {
  final days = [...records]..sort((a, b) => a.date.compareTo(b.date));
  List<T> first7<T>(List<T> l) => l.length <= 7 ? l : l.sublist(0, 7);
  final d = first7(days);

  bool has(int n) => n > 0;

  return {
    'meal': d.map((r) => has(r.mealRecords)).toList(),
    'walk': d.map((r) => has(r.walkRecords)).toList(),
    'excretion': d.map((r) => has(r.excretionRecords)).toList(),
    'health': d.map((r) => has(r.healthRecords)).toList(),
    'memo': d.map((r) => has(r.freeRecords)).toList(),
  };
}

/// 라인차트용: 카테고리별 일간 카운트
Map<String, List<int>> toWeeklyCounts(List<WeeklyRecord> records) {
  final days = [...records]..sort((a, b) => a.date.compareTo(b.date));
  List<T> first7<T>(List<T> l) => l.length <= 7 ? l : l.sublist(0, 7);
  final d = first7(days);

  return {
    'meal': d.map((r) => r.mealRecords).toList(),
    'walk': d.map((r) => r.walkRecords).toList(),
    'excretion': d.map((r) => r.excretionRecords).toList(),
    'health': d.map((r) => r.healthRecords).toList(),
    'memo': d.map((r) => r.freeRecords).toList(),
  };
}

/// 주간 합계/최고 강도
class WeeklyAggregates {
  final int mealAmount;   // g
  final int snackAmount;  // g
  final int waterAmount;  // ml
  final int walkTime;     // 분
  final String maxIntensity;

  WeeklyAggregates({
    required this.mealAmount,
    required this.snackAmount,
    required this.waterAmount,
    required this.walkTime,
    required this.maxIntensity,
  });
}

WeeklyAggregates computeAggregates(List<WeeklyRecord> records) {
  int meal = 0, snack = 0, water = 0, time = 0;
  String best = '';

  int rank(String s) {
    switch (s.trim()) {
      case '낮음': return 1;
      case '보통': return 2;
      case '높음': return 3;
      default: return 0;
    }
  }

  for (final r in records) {
    meal += r.mealAmount;
    snack += r.snackAmount;
    water += r.waterAmount;
    time += r.walkTime;
    if (rank(r.walkIntensity) > rank(best)) best = r.walkIntensity;
  }

  return WeeklyAggregates(
    mealAmount: meal,
    snackAmount: snack,
    waterAmount: water,
    walkTime: time,
    maxIntensity: best,
  );
}

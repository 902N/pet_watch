import 'dart:convert';
import 'package:intl/intl.dart';

class DayCount {
  final DateTime date;
  final int count;

  DayCount({required this.date, required this.count});

  factory DayCount.fromJson(Map<String, dynamic> json) {
    final rawCount = json['count'] ??
        json['mealRecords'] ??
        json['walkRecords'] ??
        json['excretionRecords'] ??
        json['healthRecords'] ??
        json['freeRecords'] ??
        0;
    return DayCount(
      date: DateTime.parse(json['date'] as String),
      count: (rawCount as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'count': count,
  };

  @override
  String toString() => jsonEncode(toJson());
}

class CategoryMonthly {
  final List<DayCount> records;
  final int monthCount;
  final double monthRate;

  CategoryMonthly({
    required this.records,
    required this.monthCount,
    required this.monthRate,
  });

  factory CategoryMonthly.fromJson(Map<String, dynamic> json) {
    final recs = (json['records'] as List<dynamic>? ?? [])
        .map((e) => DayCount.fromJson(e as Map<String, dynamic>))
        .toList();
    return CategoryMonthly(
      records: recs,
      monthCount: (json['monthCount'] as num? ?? 0).toInt(),
      monthRate: (json['monthRate'] as num? ?? 0).toDouble(),
    );
  }

  Set<int> markedDays(DateTime monthAnchor) {
    final first = DateTime(monthAnchor.year, monthAnchor.month, 1);
    final nextMonth = DateTime(monthAnchor.year, monthAnchor.month + 1, 1);
    return records
        .where((r) => !r.date.isBefore(first) && r.date.isBefore(nextMonth))
        .map((r) => r.date.day)
        .toSet();
  }

  String get rateText {
    final f = NumberFormat("0.##");
    return "${f.format(monthRate)}%";
  }

  String get countText => monthCount.toString();

  Map<String, dynamic> toJson() => {
    'records': records.map((e) => e.toJson()).toList(),
    'monthCount': monthCount,
    'monthRate': monthRate,
  };

  @override
  String toString() => jsonEncode(toJson());
}

class MonthlyReport {
  final CategoryMonthly mealRecords;
  final CategoryMonthly walkRecords;
  final CategoryMonthly excretionRecords;
  final CategoryMonthly healthRecords;
  final CategoryMonthly freeRecords;

  MonthlyReport({
    required this.mealRecords,
    required this.walkRecords,
    required this.excretionRecords,
    required this.healthRecords,
    required this.freeRecords,
  });

  factory MonthlyReport.fromJson(Map<String, dynamic> json) {
    CategoryMonthly parseCat(String key) =>
        CategoryMonthly.fromJson((json[key] as Map<String, dynamic>? ?? {}));
    return MonthlyReport(
      mealRecords: parseCat('mealRecords'),
      walkRecords: parseCat('walkRecords'),
      excretionRecords: parseCat('excretionRecords'),
      healthRecords: parseCat('healthRecords'),
      freeRecords: parseCat('freeRecords'),
    );
  }

  Map<String, dynamic> toJson() => {
    'mealRecords': mealRecords.toJson(),
    'walkRecords': walkRecords.toJson(),
    'excretionRecords': excretionRecords.toJson(),
    'healthRecords': healthRecords.toJson(),
    'freeRecords': freeRecords.toJson(),
  };

  @override
  String toString() => jsonEncode(toJson());
}

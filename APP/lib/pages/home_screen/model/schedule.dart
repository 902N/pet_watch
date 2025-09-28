import 'package:flutter/material.dart';

class Schedule implements Comparable<Schedule> {
  final String id;
  final DateTime date;
  final int startHour;
  final int startMinute;
  final String content;

  final String? category;
  final String? memo;
  final bool isDone;
  final Map<String, dynamic>? categoryData;

  const Schedule({
    required this.id,
    required this.date,
    required this.startHour,
    required this.startMinute,
    required this.content,
    this.category,
    this.memo,
    this.isDone = false,
    this.categoryData,
  });

  @override
  int compareTo(Schedule other) {
    int result = startHour.compareTo(other.startHour);
    if (result != 0) return result;
    result = startMinute.compareTo(other.startMinute);
    if (result != 0) return result;
    result = content.compareTo(other.content);
    if (result != 0) return result;
    return _uniqueKey.compareTo(other._uniqueKey);
  }

  String get _uniqueKey {
    final d = '${date.year}-${date.month}-${date.day}';
    final t = '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';
    final c = category ?? '';
    final m = memo ?? '';
    final cd = categoryData?['id']?.toString() ?? categoryData?['recordId']?.toString() ?? '';
    return '$id|$d|$t|$c|$content|$m|$cd';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Schedule && runtimeType == other.runtimeType && _uniqueKey == other._uniqueKey;

  @override
  int get hashCode => _uniqueKey.hashCode;
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

const Map<String, Color> kCategoryColorMap = {
  'walk': Color(0xFF38A3FF),
  'meal': Color(0xFF9B6BFF),
  'health': Color(0xFF37D4B8),
  'toilet': Color(0xFFFF6FAE),
  'memo': Color(0xFF666666),
};

const Map<String, String> kCategoryIconAsset = {
  'walk': 'asset/icon/walk.png',
  'meal': 'asset/icon/meal.png',
  'health': 'asset/icon/health.png',
  'toilet': 'asset/icon/toilet.png',
  'memo': 'asset/icon/memo.png',
};

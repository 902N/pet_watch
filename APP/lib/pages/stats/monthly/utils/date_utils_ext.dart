import 'package:flutter/material.dart';

/// int | DateTime | String(ISO8601) 섞여있는 markedDays를 day(int)로 정규화
Set<int> normalizeDays(dynamic daysLike, DateTime monthAnchor) {
  if (daysLike == null) return <int>{};

  int? asDay(dynamic v) {
    if (v is int) return (v >= 1 && v <= 31) ? v : null;
    if (v is DateTime) {
      if (v.year == monthAnchor.year && v.month == monthAnchor.month) return v.day;
      return null;
    }
    if (v is String) {
      final dt = DateTime.tryParse(v);
      if (dt != null &&
          dt.year == monthAnchor.year &&
          dt.month == monthAnchor.month) return dt.day;
    }
    return null;
  }

  if (daysLike is Iterable) {
    return daysLike.map(asDay).whereType<int>().toSet();
  }
  final single = asDay(daysLike);
  return single == null ? <int>{} : {single};
}

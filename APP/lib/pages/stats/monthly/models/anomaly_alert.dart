// lib/pages/stats/monthly/models/anomaly_alert.dart
import 'dart:convert';

class AnomalyAlert {
  final int alertId;
  final int petId;
  final String recordType;
  final String anomalyMessage;
  final DateTime detectedAt; // ← 로컬 시간으로 변환 저장
  final DateTime? readAt;    // ← 로컬 시간으로 변환 저장
  final bool read;

  AnomalyAlert({
    required this.alertId,
    required this.petId,
    required this.recordType,
    required this.anomalyMessage,
    required this.detectedAt,
    this.readAt,
    required this.read,
  });

  // 안전한 날짜 파서: null/빈문자 처리 + 로컬 변환
  static DateTime _parseToLocal(dynamic v) {
    if (v == null) {
      throw FormatException('detectedAt/readAt is null');
    }
    final s = v.toString();
    final dt = DateTime.parse(s);   // '...Z'면 UTC로, 아니면 로컬로 파싱
    return dt.toLocal();            // 항상 로컬로 맞춰 저장
  }

  factory AnomalyAlert.fromJson(Map<String, dynamic> j) {
    return AnomalyAlert(
      alertId: (j['alertId'] as num).toInt(),
      petId: (j['petId'] as num).toInt(),
      recordType: (j['recordType'] ?? '') as String,
      anomalyMessage: (j['anomalyMessage'] ?? '') as String,
      detectedAt: _parseToLocal(j['detectedAt']),
      readAt: j['readAt'] != null ? _parseToLocal(j['readAt']) : null,
      read: (j['read'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toJson() => {
    'alertId': alertId,
    'petId': petId,
    'recordType': recordType,
    'anomalyMessage': anomalyMessage,
    'detectedAt': detectedAt.toIso8601String(),
    'readAt': readAt?.toIso8601String(),
    'read': read,
  };

  @override
  String toString() => jsonEncode(toJson());
}

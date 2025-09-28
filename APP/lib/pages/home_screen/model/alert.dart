// lib/pages/home_screen/model/alert.dart
class Alert {
  final int alertId;
  final int petId;
  final String petName;
  final String recordType;
  final String anomalyMessage;
  final String anomalyFields;
  final DateTime detectedAt;
  final DateTime? readAt;
  final bool read;

  Alert({
    required this.alertId,
    required this.petId,
    required this.petName,
    required this.recordType,
    required this.anomalyMessage,
    required this.anomalyFields,
    required this.detectedAt,
    this.readAt,
    required this.read,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      alertId: json['alertId'] as int,
      petId: json['petId'] as int,
      petName: json['petName'] as String,
      recordType: json['recordType'] as String,
      anomalyMessage: json['anomalyMessage'] as String,
      anomalyFields: json['anomalyFields'] as String,
      detectedAt: DateTime.parse(json['detectedAt'] as String),
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt'] as String) : null,
      read: json['read'] as bool,
    );
  }

  Alert copyWith({
    int? alertId,
    int? petId,
    String? petName,
    String? recordType,
    String? anomalyMessage,
    String? anomalyFields,
    DateTime? detectedAt,
    DateTime? readAt,
    bool? read,
  }) {
    return Alert(
      alertId: alertId ?? this.alertId,
      petId: petId ?? this.petId,
      petName: petName ?? this.petName,
      recordType: recordType ?? this.recordType,
      anomalyMessage: anomalyMessage ?? this.anomalyMessage,
      anomalyFields: anomalyFields ?? this.anomalyFields,
      detectedAt: detectedAt ?? this.detectedAt,
      readAt: readAt ?? this.readAt,
      read: read ?? this.read,
    );
  }
}

class AlertResponse {
  final List<Alert> alerts;
  final int currentPage;
  final int totalPages;
  final int totalElements;
  final bool hasNext;
  final bool hasPrevious;

  AlertResponse({
    required this.alerts,
    required this.currentPage,
    required this.totalPages,
    required this.totalElements,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory AlertResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final alertsList = data['alerts'] as List<dynamic>;
    
    return AlertResponse(
      alerts: alertsList.map((alert) => Alert.fromJson(alert as Map<String, dynamic>)).toList(),
      currentPage: data['currentPage'] as int,
      totalPages: data['totalPages'] as int,
      totalElements: data['totalElements'] as int,
      hasNext: data['hasNext'] as bool,
      hasPrevious: data['hasPrevious'] as bool,
    );
  }
}

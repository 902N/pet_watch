// lib/pages/home_screen/record/models/walk_record_models.dart

/// 산책 기록 생성 요청 모델
/// - recordCategory: '산책'
/// - recordDateTime: ISO8601 (예: 2025-09-21T14:00:00.000Z)
/// - duration: 분 단위
/// - intensity: '가벼움' | '보통' | '격렬'
class WalkRecordRequest {
  final String recordCategory;
  final String recordDateTime;
  final int duration;
  final String intensity;

  WalkRecordRequest({
    required this.recordCategory,
    required this.recordDateTime,
    required this.duration,
    required this.intensity,
  });

  Map<String, dynamic> toJson() => {
    'recordCategory': recordCategory,
    'recordDateTime': recordDateTime,
    'duration': duration,
    'intensity': intensity,
  };
}

/// 산책 기록 응답 모델 (스웨거 예시 필드 반영)
class WalkRecordResponse {
  final int recordId;
  final int petId;
  final int userId;
  final String recordCategory;
  final String recordDateTime; // 서버에서 문자열로 내려오므로 String 유지
  final String createdAt;
  final String updatedAt;
  final int duration;
  final String intensity;

  WalkRecordResponse({
    required this.recordId,
    required this.petId,
    required this.userId,
    required this.recordCategory,
    required this.recordDateTime,
    required this.createdAt,
    required this.updatedAt,
    required this.duration,
    required this.intensity,
  });

  factory WalkRecordResponse.fromJson(Map<String, dynamic> json) {
    return WalkRecordResponse(
      recordId: json['recordId'] as int,
      petId: json['petId'] as int,
      userId: json['userId'] as int,
      recordCategory: json['recordCategory'] as String? ?? '산책',
      recordDateTime: json['recordDateTime'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      duration: json['duration'] as int? ?? 0,
      intensity: json['intensity'] as String? ?? '보통',
    );
  }

  Map<String, dynamic> toJson() => {
    'recordId': recordId,
    'petId': petId,
    'userId': userId,
    'recordCategory': recordCategory,
    'recordDateTime': recordDateTime,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'duration': duration,
    'intensity': intensity,
  };
}

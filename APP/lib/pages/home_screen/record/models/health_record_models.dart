// lib/pages/home_screen/record/models/health_record_models.dart
import 'common_record_models.dart';

/// 건강 기록 생성 요청
/// - 서버 스펙 통일: recordDateTime(ISO8601) 사용
class HealthRecordRequest extends BaseRecordRequest {
  final String symptomDescription;
  final String? imgUrl;

  HealthRecordRequest({
    required super.recordCategory, // '건강'
    required super.recordDate,    // ISO8601 문자열(UTC 권장) 전달 → toJson에서 recordDateTime으로 매핑
    required this.symptomDescription,
    this.imgUrl,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'recordCategory': recordCategory,
      'recordDateTime': recordDate, // ✅ 서버는 recordDateTime을 기대
      'symptomDescription': symptomDescription,
      'imgUrl': imgUrl,
    };
  }
}

/// 건강 기록 응답
class HealthRecordResponse extends BaseRecordResponse {
  final String symptomDescription;
  final String? imgUrl;

  HealthRecordResponse({
    required super.recordId,
    required super.petId,
    required super.userId,
    required super.recordCategory,
    required super.recordDate, // BaseRecordResponse의 필드명 유지 (recordDateTime도 아래서 매핑)
    required super.createdAt,
    super.updatedAt,
    required this.symptomDescription,
    this.imgUrl,
  });

  factory HealthRecordResponse.fromJson(Map<String, dynamic> json) {
    // 서버가 recordDateTime으로 내려줄 수도 있으니 안전 매핑
    final recordDate = (json['recordDate'] ?? json['recordDateTime']) as String? ?? '';

    return HealthRecordResponse(
      recordId: json['recordId'] as int,
      petId: json['petId'] as int,
      userId: json['userId'] as int,
      recordCategory: json['recordCategory'] as String? ?? '건강',
      recordDate: recordDate,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String?,
      symptomDescription: json['symptomDescription'] as String? ?? '',
      imgUrl: json['imgUrl'] as String?,
    );
  }
}

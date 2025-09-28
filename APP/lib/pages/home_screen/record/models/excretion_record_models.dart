// lib/pages/home_screen/record/models/excretion_record_models.dart
import 'common_record_models.dart';

/// 배변 기록 생성 요청
class ExcretionRecordRequest extends BaseRecordRequest {
  final String type;        // '대변' | '소변'
  final String condition;   // '정상' 등
  final String? imageUrl;   // S3 URL

  ExcretionRecordRequest({
    required super.recordCategory, // '배변'
    required super.recordDate,     // 화면에서 만든 ISO(로컬) 문자열 -> toJson에서 recordDateTime으로 매핑
    required this.type,
    required this.condition,
    this.imageUrl,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'recordCategory': recordCategory,
      'recordDateTime': recordDate, // ✅ 서버는 recordDateTime 기대
      'type': type,
      'condition': condition,
      'imageUrl': imageUrl,         // ✅ 서버는 imageUrl 기대
    };
  }
}

/// 배변 기록 응답
class ExcretionRecordResponse extends BaseRecordResponse {
  final String type;
  final String condition;
  final String? imageUrl;

  ExcretionRecordResponse({
    required super.recordId,
    required super.petId,
    required super.userId,
    required super.recordCategory,
    required super.recordDate, // BaseRecordResponse의 필드명 유지 (recordDateTime도 아래서 매핑)
    required super.createdAt,
    super.updatedAt,
    required this.type,
    required this.condition,
    this.imageUrl,
  });

  factory ExcretionRecordResponse.fromJson(Map<String, dynamic> json) {
    // 서버가 recordDateTime으로 내려줄 수도 있으니 안전 매핑
    final recordDate = (json['recordDate'] ?? json['recordDateTime']) as String? ?? '';

    return ExcretionRecordResponse(
      recordId: json['recordId'] as int,
      petId: json['petId'] as int,
      userId: json['userId'] as int,
      recordCategory: json['recordCategory'] as String? ?? '배변',
      recordDate: recordDate,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String?,
      type: json['type'] as String? ?? '',
      condition: json['condition'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
    );
  }
}

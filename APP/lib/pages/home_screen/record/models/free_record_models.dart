class FreeRecordRequest {
  final String recordCategory;   // '자유'
  final String recordDateTime;   // ISO-8601 (로컬, 오프셋X)
  final String content;
  final String? imgUrl;

  FreeRecordRequest({
    required this.recordCategory,
    required this.recordDateTime,
    required this.content,
    this.imgUrl,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'recordCategory': recordCategory,
      'recordDateTime': recordDateTime,
      'content': content,
    };
    // 서버가 null을 싫어하면 키 생략
    if (imgUrl != null && imgUrl!.trim().isNotEmpty) {
      map['imgUrl'] = imgUrl;
    }
    return map;
  }
}

class FreeRecordResponse {
  final int recordId;
  final int petId;
  final int userId;
  final String? recordCategory;   // ← nullable
  final String? recordDateTime;   // ← nullable
  final String? createdAt;        // ← nullable
  final String? updatedAt;        // ← nullable
  final String? content;          // ← nullable (안전하게)
  final String? imgUrl;           // ← nullable

  FreeRecordResponse({
    required this.recordId,
    required this.petId,
    required this.userId,
    this.recordCategory,
    this.recordDateTime,
    this.createdAt,
    this.updatedAt,
    this.content,
    this.imgUrl,
  });

  factory FreeRecordResponse.fromJson(Map<String, dynamic> json) {
    return FreeRecordResponse(
      recordId: (json['recordId'] ?? json['id']) as int,
      petId: json['petId'] as int,
      userId: json['userId'] as int,
      recordCategory: json['recordCategory'] as String?,     // null-safe
      recordDateTime: json['recordDateTime']?.toString(),    // null-safe
      createdAt: json['createdAt']?.toString(),              // null-safe
      updatedAt: json['updatedAt']?.toString(),              // null-safe
      content: json['content'] as String?,                   // null-safe
      imgUrl: json['imgUrl'] as String?,                     // null-safe
    );
  }
}

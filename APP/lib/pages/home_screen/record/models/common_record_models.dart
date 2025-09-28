// 공통 API 응답 모델
class ApiResponse<T> {
  final int status;
  final String message;
  final T? data;
  final bool success;
  final String timestamp;

  ApiResponse({
    required this.status,
    required this.message,
    this.data,
    required this.success,
    required this.timestamp,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>)? fromJsonT) {
    return ApiResponse<T>(
      status: json['status'],
      message: json['message'],
      data: json['data'] != null && fromJsonT != null ? fromJsonT(json['data']) : null,
      success: json['success'],
      timestamp: json['timestamp'],
    );
  }
}

// 공통 기록 요청 모델
abstract class BaseRecordRequest {
  final String recordCategory;
  final String recordDate;

  BaseRecordRequest({
    required this.recordCategory,
    required this.recordDate,
  });

  Map<String, dynamic> toJson();
}

// 공통 기록 응답 모델
abstract class BaseRecordResponse {
  final int recordId;
  final int petId;
  final int userId;
  final String recordCategory;
  final String recordDate;
  final String createdAt;
  final String? updatedAt;

  BaseRecordResponse({
    required this.recordId,
    required this.petId,
    required this.userId,
    required this.recordCategory,
    required this.recordDate,
    required this.createdAt,
    this.updatedAt,
  });
}

// API 에러 응답 구조
class ApiErrorResponse {
  final int errorStatus;
  final String errorCode;
  final String? message;

  ApiErrorResponse({
    required this.errorStatus,
    required this.errorCode,
    this.message,
  });

  factory ApiErrorResponse.fromJson(Map<String, dynamic> json) {
    return ApiErrorResponse(
      errorStatus: json['errorStatus'],
      errorCode: json['errorCode'],
      message: json['message'],
    );
  }
}

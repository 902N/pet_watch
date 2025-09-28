import 'common_record_models.dart';

class MealRecordRequest extends BaseRecordRequest {
  final String recordDateTime;
  final String type;
  final String detail;
  final int amount;

  MealRecordRequest({
    required super.recordCategory, // "식사"
    required this.recordDateTime,  // "YYYY-MM-DDTHH:mm:ss"
    required this.type,
    required this.detail,
    required this.amount,
  }) : super(recordDate: recordDateTime);

  @override
  Map<String, dynamic> toJson() {
    return {
      'recordCategory': recordCategory,
      'recordDateTime': recordDateTime,
      'type': type,
      'detail': detail,
      'amount': amount,
    };
  }
}

class MealRecordResponse extends BaseRecordResponse {
  final String recordDateTime;
  final String type;
  final String detail;
  final int amount;

  MealRecordResponse({
    required super.recordId,
    required super.petId,
    required super.userId,
    required super.recordCategory,
    required this.recordDateTime,
    required super.createdAt,
    super.updatedAt,
    required this.type,
    required this.detail,
    required this.amount,
  }) : super(recordDate: recordDateTime);

  factory MealRecordResponse.fromJson(Map<String, dynamic> json) {
    final dt = json['recordDateTime']?.toString() ?? '';
    return MealRecordResponse(
      recordId: (json['recordId'] as num).toInt(),
      petId: (json['petId'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      recordCategory: json['recordCategory']?.toString() ?? '',
      recordDateTime: dt,
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString(),
      type: json['type']?.toString() ?? '',
      detail: json['detail']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
    );
  }
}

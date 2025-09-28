import 'package:flutter/material.dart';

mixin RecordValidationMixin {
  void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // 종료시간 사용 제거에 따라 단일 시작시간만 간단 검증
  bool validateTimeInputs(BuildContext context, String startTime) {
    if (startTime.isEmpty) {
      showErrorSnackBar(context, '시간을 입력해주세요.');
      return false;
    }

    final startHour = int.tryParse(startTime);
    if (startHour == null || startHour < 0 || startHour > 23) {
      showErrorSnackBar(context, '시간은 0-23 사이의 값이어야 합니다.');
      return false;
    }
    return true;
  }

  void showSuccessSnackBar(BuildContext context, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }
}



import 'package:APP/const/colors.dart';
import 'package:flutter/material.dart';

class TodayBanner extends StatelessWidget {
  // 선택된 날짜
  final DateTime selectedDate;
  // 일정 개수
  final int count;

  const TodayBanner({required this.selectedDate, required this.count, super.key});

  @override
  Widget build(BuildContext context) {
    // 기본으로 사용할 글꼴
    final textStyle = TextStyle(
      fontWeight: FontWeight.w600,
      color: Colors.white,
    );

    return Container(
      color: primaryColor,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${selectedDate.year}년 ${selectedDate.month}월 ${selectedDate.day}일',
              style: textStyle,
            ),
            // 일정 개수 표시
            Text(
              '$count개',
              style: textStyle,
            ),
          ],
        ),
      ),
    );
  }
}

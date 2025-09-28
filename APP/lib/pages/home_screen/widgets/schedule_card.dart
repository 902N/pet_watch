import 'package:flutter/material.dart';
import 'package:APP/const/colors.dart';
import 'package:APP/pages/home_screen/model/schedule.dart';

class ScheduleCard extends StatelessWidget {
  final int startTime;
  final int startMinute;
  final String content;
  final String? category;
  final bool isDone;

  const ScheduleCard({
    required this.startTime,
    required this.startMinute,
    required this.content,
    this.category,
    this.isDone = false,
    super.key,
  });

  // 카테고리별 기본 아이콘 반환
  IconData _getDefaultIconForCategory(String category) {
    switch (category) {
      case 'walk':
        return Icons.directions_walk;
      case 'meal':
        return Icons.restaurant;
      case 'health':
        return Icons.health_and_safety;
      case 'toilet':
        return Icons.wc;
      case 'memo':
        return Icons.note;
      default:
        return Icons.note;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = kCategoryColorMap[category ?? 'memo'] ?? AppColors.textSecondary;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent, // 카테고리 색상을 배경으로 사용
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Image.asset(
                  kCategoryIconAsset[category ?? 'memo'] ?? 'asset/icon/memo.png',
                  width: 22,
                  height: 22,
                  // color: Colors.white, // 아이콘을 흰색으로 변경
                  errorBuilder: (context, error, stackTrace) {
                    // 아이콘 로드 실패 시 기본 아이콘 표시
                    return Icon(
                      _getDefaultIconForCategory(category ?? 'memo'),
                      size: 22,
                      color: Colors.white,
                    );
                  },
                ),
              ),
            ),
            SizedBox(width: 12.0),
            _Time(
              startTime: startTime,
              startMinute: startMinute,
            ),
            SizedBox(width: 12.0),
            Expanded(
              child: _Content(content: content, isDone: isDone),
            ),
          ],
        ),
      ),
    );
  }
}

class _Time extends StatelessWidget {
  final int startTime;
  final int startMinute;

  const _Time({required this.startTime, required this.startMinute});

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
      fontSize: 16.0,
    );

    // 시작시간과 분 표시
    return Text(
      '${startTime.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}', 
      style: textStyle,
    );
  }
}

class _Content extends StatelessWidget {
  final String content;
  final bool isDone;

  const _Content({required this.content, required this.isDone});

  @override
  Widget build(BuildContext context) {
    return Text(
      content,
      style: TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.w700,
        color: isDone ? Colors.grey : AppColors.textPrimary,
      ),
    );
  }
}

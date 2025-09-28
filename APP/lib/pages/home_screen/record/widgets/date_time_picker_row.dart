import 'package:flutter/material.dart';
import 'package:APP/const/colors.dart';

class DateTimePickerRow extends StatelessWidget {
  final DateTime selectedDate;
  final int selectedHour;
  final int selectedMinute;
  final VoidCallback onSelectDate;
  final VoidCallback onSelectTime;

  /// 선택된 카테고리 색을 넘기면 칩 배경/테두리에 반영됩니다.
  /// 안 넘기면 기본 색(AppColors.primaryAccent)이 사용됩니다.
  final Color? baseColor;

  const DateTimePickerRow({
    super.key,
    required this.selectedDate,
    required this.selectedHour,
    required this.selectedMinute,
    required this.onSelectDate,
    required this.onSelectTime,
    this.baseColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = (baseColor ?? AppColors.primaryAccent);

    // 칩 색 구성
    final Color bg = accent.withOpacity(0.14);
    final Color border = accent.withOpacity(0.45);
    final Color iconColor = accent;
    final Color textColor = AppColors.textPrimary;

    Widget pill({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
    }) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final dateLabel =
        '${selectedDate.year}년 ${selectedDate.month}월 ${selectedDate.day}일';
    final timeLabel =
        '${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}';

    return Row(
      children: [
        Expanded(
          child: pill(
            icon: Icons.calendar_today_rounded,
            label: dateLabel,
            onTap: onSelectDate,
          ),
        ),
        const SizedBox(width: 10),
        pill(
          icon: Icons.access_time_filled_rounded,
          label: timeLabel,
          onTap: onSelectTime,
        ),
      ],
    );
  }
}

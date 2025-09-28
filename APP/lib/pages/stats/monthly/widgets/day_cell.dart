import 'package:flutter/material.dart';

class DayCell extends StatelessWidget {
  final int? day;
  final Color accent;
  final bool success;
  final bool isToday;
  final Color? weekendColor;
  final bool alert;

  const DayCell({
    super.key,
    required this.day,
    required this.accent,
    required this.success,
    required this.isToday,
    this.weekendColor,
    this.alert = false,
  });

  @override
  Widget build(BuildContext context) {
    final inMonth = day != null;
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: inMonth ? Colors.white : const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5D4FF)),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  inMonth ? '$day' : '',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: weekendColor ?? Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: success ? accent : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isToday)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(width: 2, color: Theme.of(context).colorScheme.primary),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        if (alert && inMonth)
          const Positioned(
            top: 4,
            right: 4,
            child: SizedBox(
              width: 10,
              height: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
              ),
            ),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

class CardFooter extends StatelessWidget {
  final String rateText;   // 예: "85%"  | 이상기록일 때는 ""
  final String countText;  // 예: "12"   | 이상기록일 때는 ""

  const CardFooter({
    super.key,
    required this.rateText,
    required this.countText,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
      fontWeight: FontWeight.w600,
      height: 1.0,
    );

    final showRate = rateText.trim().isNotEmpty;
    final showCount = countText.trim().isNotEmpty;

    // 둘 다 비어 있으면 푸터 자체를 숨김 (아이콘도 보이지 않음)
    if (!showRate && !showCount) {
      return const SizedBox.shrink();
    }

    return Padding(
      // 상단 패딩 4로 유지
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          if (showRate) ...[
            const Icon(Icons.schedule, size: 16, color: Color(0xFF38A3FF)), // 시계
            const SizedBox(width: 6),
            Text(rateText, style: textStyle),
          ],
          if (showRate && showCount) const Spacer(),
          if (showCount) ...[
            const Icon(Icons.check_circle, size: 16, color: Color(0xFF40C057)), // 체크
            const SizedBox(width: 6),
            Text(countText, style: textStyle),
          ],
        ],
      ),
    );
  }
}

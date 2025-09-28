import 'package:flutter/material.dart';

class AchievementCard extends StatelessWidget {
  const AchievementCard({
    super.key,
    required this.color,
    required this.rateText,
    required this.countText,
  });

  final Color color;
  final String rateText;
  final String countText;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: color.withOpacity(.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(.18), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text('달성률 $rateText · $countText',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
          Icon(Icons.emoji_events, color: color),
        ],
      ),
    );
  }
}

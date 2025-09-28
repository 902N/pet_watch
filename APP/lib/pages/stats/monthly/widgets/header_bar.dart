import 'package:flutter/material.dart';

class HeaderBar extends StatelessWidget {
  const HeaderBar({
    super.key,
    required this.title,
    required this.onPrev,
    required this.onNext,
    required this.onTitleTap,
    required this.categoryText,
    required this.onCategoryTap,
    required this.categoryColor,
    required this.isAll,
    this.titleSize = 20, // ← 추가: 기본 20으로 살짝 크게
  });

  final String title;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onTitleTap;
  final String categoryText;
  final VoidCallback onCategoryTap;
  final Color categoryColor;
  final bool isAll;
  final double titleSize; // ← 추가

  @override
  Widget build(BuildContext context) {
    final categoryBtn = FilledButton.icon(
      onPressed: onCategoryTap,
      icon: const Icon(Icons.tune, size: 16, color: Colors.black87),
      label: Text(
        categoryText,
        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
      ),
      style: FilledButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        backgroundColor: (isAll ? Colors.black.withOpacity(0.06) : categoryColor.withOpacity(0.18)),
        foregroundColor: Colors.black87,
      ),
    );

    return Row(
      children: [
        const SizedBox(width: 48),
        Expanded(
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: onPrev,
                  icon: const Icon(Icons.chevron_left),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
                GestureDetector(
                  onTap: onTitleTap,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: titleSize,           // ← 적용
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onNext,
                  icon: const Icon(Icons.chevron_right),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              ],
            ),
          ),
        ),
        categoryBtn,
      ],
    );
  }
}

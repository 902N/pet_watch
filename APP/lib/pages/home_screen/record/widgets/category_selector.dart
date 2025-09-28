import 'package:flutter/material.dart';
import 'package:APP/const/colors.dart';
import 'package:APP/pages/home_screen/model/schedule.dart';

class CategorySelector extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;

  const CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  static const List<String> categories = ['walk', 'meal', 'health', 'toilet', 'memo'];
  static const List<String> categoryNames = ['산책', '밥주기', '건강', '배변', '메모'];
  static const List<String> categoryIcons = [
    'asset/icon/walk.png',
    'asset/icon/meal.png',
    'asset/icon/health.png',
    'asset/icon/toilet.png',
    'asset/icon/memo.png',
  ];

  @override
  Widget build(BuildContext context) {
    const double iconSize = 56;
    const double spacing = 8;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(categories.length * 2 - 1, (i) {
          if (i.isOdd) return const SizedBox(width: spacing);
          final index = i ~/ 2;
          final category = categories[index];
          final isSelected = selectedCategory == category;
          return GestureDetector(
            onTap: () => onCategoryChanged(category),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: (kCategoryColorMap[category] ?? AppColors.primaryAccent)
                        .withOpacity(isSelected ? 0.25 : 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (kCategoryColorMap[category] ?? AppColors.primaryAccent)
                          .withOpacity(isSelected ? 1 : 0.5),
                      width: isSelected ? 4 : 1.5,
                    ),
                  ),
                  child: Center(
                    child: Image.asset(
                      categoryIcons[index],
                      width: iconSize * 0.7,
                      height: iconSize * 0.7,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  categoryNames[index],
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

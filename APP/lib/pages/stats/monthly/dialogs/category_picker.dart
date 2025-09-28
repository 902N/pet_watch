import 'package:flutter/material.dart';
import '../utils/category_theme.dart';

Future<RecordCategory?> showCategoryPicker(
    BuildContext context, {
      required RecordCategory current,
    }) {
  final items = <(RecordCategory, String, IconData, Color Function(BuildContext))>[
    (RecordCategory.all, '전체', Icons.grid_view, (ctx) => Theme.of(ctx).colorScheme.primary),
    (RecordCategory.meal, '식사', Icons.restaurant, (_) => CategoryTheme.meal),
    (RecordCategory.walk, '산책', Icons.pets, (_) => CategoryTheme.walk),
    (RecordCategory.excretion, '배변', Icons.water_drop, (_) => CategoryTheme.excretion),
    (RecordCategory.health, '건강', Icons.favorite, (_) => CategoryTheme.health),
    (RecordCategory.free, '자유기록', Icons.edit_note, (_) => CategoryTheme.free),
    (RecordCategory.anomaly, '이상기록', Icons.warning_amber_rounded, (_) => CategoryTheme.anomaly),
  ];

  final controller = TextEditingController();

  return showDialog<RecordCategory>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      final maxH = MediaQuery.of(ctx).size.height * 0.8;
      final softPurple = Theme.of(ctx).colorScheme.primary.withOpacity(.10);

      return Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 360, maxHeight: maxH),
          child: StatefulBuilder(
            builder: (ctx, setM) {
              final q = controller.text.trim();
              final filtered = q.isEmpty ? items : items.where((e) => e.$2.contains(q)).toList();

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 4, 6),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Center(
                            child: Text('카테고리 선택', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: controller,
                      onChanged: (_) => setM(() {}),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: '카테고리 검색',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final e = filtered[i];
                        final selected = e.$1 == current;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.of(ctx).pop(e.$1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: softPurple,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(e.$3, color: e.$4(ctx), size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      e.$2,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  if (selected)
                                    Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}

import 'package:flutter/material.dart';

Future<DateTime?> showYearMonthPicker(BuildContext context, DateTime anchor) {
  int tempYear = anchor.year;

  return showDialog<DateTime>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      final softPurple = Theme.of(ctx).colorScheme.primary.withOpacity(.10);

      return Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          // ▶ 더 작은 모달
          constraints: const BoxConstraints(maxWidth: 320, maxHeight: 420),
          child: StatefulBuilder(
            builder: (ctx, setM) {
              return LayoutBuilder(
                builder: (ctx, cons) {
                  // 헤더/패딩/간격 설정
                  const double headerH = 60;
                  const double topGap = 6;
                  const double padH = 14;
                  const double padV = 12;
                  const int cols = 3;
                  const int rows = 4;
                  const double mainSpacing = 10;
                  const double crossSpacing = 10;

                  // 셀 비율 계산 → 4행이 세로를 ‘정확히’ 채우게
                  final double gridW =
                      cons.maxWidth - padH * 2 - crossSpacing * (cols - 1);
                  final double cellW = gridW / cols;
                  final double gridH =
                      cons.maxHeight - headerH - topGap - padV * 2;
                  final double cellH =
                      (gridH - mainSpacing * (rows - 1)) / rows;
                  final double aspect = cellW / cellH;

                  return SizedBox(
                    height: cons.maxHeight,
                    child: Column(
                      children: [
                        // 헤더
                        SizedBox(
                          height: headerH,
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () => setM(() => tempYear--),
                                icon: const Icon(Icons.chevron_left),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    '$tempYear년',
                                    // ▶ 제목 크게/굵게
                                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => setM(() => tempYear++),
                                icon: const Icon(Icons.chevron_right),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(ctx),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: topGap),
                        // 그리드(12개월) — 모달 세로 공간을 꽉 채움
                        Expanded(
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                                horizontal: padH, vertical: padV),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              mainAxisSpacing: mainSpacing,
                              crossAxisSpacing: crossSpacing,
                              childAspectRatio: aspect,
                            ),
                            itemCount: 12,
                            itemBuilder: (ctx, i) {
                              final m = i + 1;
                              final isCurrent =
                                  tempYear == anchor.year && m == anchor.month;
                              return InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => Navigator.of(ctx)
                                    .pop(DateTime(tempYear, m, 1)),
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: softPurple, // 연보라
                                    borderRadius: BorderRadius.circular(14),
                                    border: isCurrent
                                        ? Border.all(
                                      color: Theme.of(ctx)
                                          .colorScheme
                                          .primary
                                          .withOpacity(.45),
                                      width: 2,
                                    )
                                        : null,
                                  ),
                                  child: Text(
                                    '$m월',
                                    style: Theme.of(ctx)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      );
    },
  );
}

// lib/login/widgets/fields_basic.dart
import 'package:flutter/material.dart';

class FieldsBasic extends StatelessWidget {
  const FieldsBasic({
    super.key,
    required this.nameCtrl,
    required this.breedCtrl,
    required this.weightCtrl,
    required this.birthText,
    required this.onPickBirth,
    required this.decoration, // InputDecoration Function(String, {String? hint})
    this.onPickBreed,
  });

  final TextEditingController nameCtrl;
  final TextEditingController breedCtrl;
  final TextEditingController weightCtrl;

  /// '선택하세요' 또는 'YYYY-MM-DD'
  final String birthText;
  final VoidCallback onPickBirth;

  /// e.g. lilacDecoration(label, {hint})
  final InputDecoration Function(String label, {String? hint}) decoration;

  /// 견종 선택 바텀시트 열기
  final VoidCallback? onPickBreed;

  @override
  Widget build(BuildContext context) {
    // base decoration 함수 결과에 suffixIcon 등을 덧붙이는 헬퍼
    InputDecoration deco(String label, {String? hint, Widget? suffixIcon}) {
      final base = decoration(label, hint: hint);
      return base.copyWith(
        suffixIcon: suffixIcon,
        isDense: true,
        border: base.border ??
            OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );
    }

    final bool birthSelected =
        birthText.trim().isNotEmpty && birthText.trim() != '선택하세요';

    // 생일 전용: InputDecorator + InkWell 로 값/힌트 스타일을 분기
    Widget birthField() {
      // 선택됨 -> 값 표시(진한 글씨), 미선택 -> 힌트 표시(연한 글씨)
      final base = deco(
        '생일',
        // 힌트는 미선택일 때만 넣는다
        hint: birthSelected ? null : '선택하세요',
        suffixIcon: const Icon(Icons.calendar_today_outlined),
      );

      // InputDecorator에 들어갈 child
      final child = birthSelected
          ? Text(
        birthText,
        style: TextStyle(
          // 힌트 색이 아니라 일반 텍스트 색으로!
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      )
          : const SizedBox.shrink();

      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPickBirth,
        child: InputDecorator(
          decoration: base,
          isEmpty: !birthSelected,
          child: child,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 이름
        TextFormField(
          controller: nameCtrl,
          decoration: deco('이름'),
          textInputAction: TextInputAction.next,
          validator: (v) =>
          (v == null || v.trim().isEmpty) ? '이름을 입력하세요.' : null,
        ),
        const SizedBox(height: 12),

        // 견종 (readOnly + onTap으로 선택기 열기)
        TextFormField(
          controller: breedCtrl,
          readOnly: true,
          onTap: onPickBreed,
          decoration: deco(
            '견종',
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: onPickBreed,
              tooltip: '견종 검색',
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 생일 (InputDecorator로 값/힌트 분기)
        birthField(),
        const SizedBox(height: 12),

        // 몸무게
        TextFormField(
          controller: weightCtrl,
          keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
          decoration: deco('몸무게 (kg)'),
        ),
      ],
    );
  }
}

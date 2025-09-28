import 'dart:io';
import 'package:flutter/material.dart';
import 'package:APP/const/colors.dart';
import 'package:APP/pages/home_screen/model/schedule.dart' show kCategoryColorMap; // ★ 추가
import 'package:APP/pages/home_screen/record/widgets/auto_size_image.dart';

class ToiletForm extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onTypeChanged;
  final String selectedCondition;
  final ValueChanged<String> onConditionChanged;
  final String? imageUrl;          // 서버 URL
  final File? localImageFile;      // 로컬 미리보기 파일
  final VoidCallback? onImageTap;

  const ToiletForm({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
    required this.selectedCondition,
    required this.onConditionChanged,
    this.imageUrl,
    this.localImageFile,
    this.onImageTap,
  });

  static const List<String> typeOptions = ['소변', '대변'];

  static const Map<String, List<String>> conditionOptionsByType = {
    '대변': ['정상', '설사', '변비', '혈변', '점액변', '기생충변', '기타'],
    '소변': ['정상', '혈뇨', '탁한 소변', '진한 황색', '주황색/초록색', '아주 옅은 색', '기타'],
  };

  List<String> _getConditionOptions() {
    return conditionOptionsByType[selectedType] ?? conditionOptionsByType['대변']!;
  }

  Color get _accent => (kCategoryColorMap['toilet'] ?? AppColors.primaryAccent);

  @override
  Widget build(BuildContext context) {
    final hasImage = localImageFile != null || (imageUrl?.isNotEmpty ?? false);

    return Column(
      children: [
        // 배변 유형 선택
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: _accent.withOpacity(0.15), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('배변 유형',
                  style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 12.0),
              Row(
                children: typeOptions.map((type) {
                  final isSelected = selectedType == type;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTypeChanged(type),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        decoration: BoxDecoration(
                          color: isSelected ? _accent : Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: _accent, width: 1.0),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(color: isSelected ? Colors.white : _accent, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16.0),

        // 배변 상태 선택
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: _accent.withOpacity(0.15), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('배변 상태',
                  style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 12.0),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _getConditionOptions().map((condition) {
                  final isSelected = selectedCondition == condition;
                  return GestureDetector(
                    onTap: () => onConditionChanged(condition),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        color: isSelected ? _accent : Colors.white,
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(color: _accent, width: 1.0),
                      ),
                      child: Text(
                        condition,
                        style: TextStyle(color: isSelected ? Colors.white : _accent, fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16.0),

        // 사진 (선택)
        if (onImageTap != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _accent.withOpacity(0.15), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(text: '사진', accent: _accent, optional: true),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: onImageTap,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_accent.withOpacity(0.08), Colors.white],
                      ),
                      border: Border.all(color: _accent.withOpacity(0.25), width: 1),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: (localImageFile != null || (imageUrl?.isNotEmpty ?? false))
                        ? Padding(
                      padding: const EdgeInsets.all(8),
                      child: AutoSizeImage(
                        imageUrl: imageUrl,
                        file: localImageFile,
                        maxHeight: 360,
                        borderRadius: 10,
                        onTap: onImageTap,
                      ),
                    )
                        : _buildImagePlaceholder(),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return SizedBox(
      height: 140,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_photo_alternate_rounded, color: _accent, size: 34),
            const SizedBox(height: 8),
            Text('사진 추가', style: TextStyle(color: _accent, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final Color accent;
  final bool optional;

  const _SectionTitle({required this.text, required this.accent, this.optional = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: accent.withOpacity(0.22), width: 1),
          ),
          child: Text(
            optional ? '선택' : '필수',
            style: TextStyle(fontSize: 11.5, color: accent.withOpacity(0.88), fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

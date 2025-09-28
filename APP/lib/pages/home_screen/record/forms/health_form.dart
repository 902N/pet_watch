import 'dart:io';
import 'package:flutter/material.dart';
import 'package:APP/const/colors.dart';
import 'package:APP/pages/home_screen/model/schedule.dart' show kCategoryColorMap;
import 'package:APP/pages/home_screen/record/widgets/auto_size_image.dart';

class HealthForm extends StatelessWidget {
  final TextEditingController symptomDescriptionController;
  final String? imageUrl;
  final File? localImageFile;
  final VoidCallback? onImageTap;
  final FocusNode? symptomFocusNode;
  final bool showSymptomError;
  final GlobalKey? symptomFieldKey;

  const HealthForm({
    super.key,
    required this.symptomDescriptionController,
    this.imageUrl,
    this.localImageFile,
    this.onImageTap,
    this.symptomFocusNode,
    this.showSymptomError = false,
    this.symptomFieldKey,
  });

  Color get _accent => (kCategoryColorMap['health'] ?? AppColors.primaryAccent);

  @override
  Widget build(BuildContext context) {
    final hasImage = localImageFile != null || (imageUrl?.isNotEmpty ?? false);

    return Column(
      children: [
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
              _SectionTitle(text: '증상 설명', accent: _accent),
              const SizedBox(height: 12),
              TextField(
                key: symptomFieldKey,
                controller: symptomDescriptionController,
                focusNode: symptomFocusNode,
                maxLines: 5,
                style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: '반려동물의 증상이나 건강 상태를 자세히 적어주세요',
                  hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.8)),
                  filled: true,
                  fillColor: const Color(0xFFFAFAFF),
                  contentPadding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: showSymptomError ? Colors.red : _accent.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: showSymptomError ? Colors.red : _accent,
                      width: 1.6,
                    ),
                  ),
                  errorText: showSymptomError ? '증상 설명은 필수입니다' : null,
                  errorMaxLines: 2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
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
                        colors: [
                          _accent.withOpacity(0.08),
                          Colors.white,
                        ],
                      ),
                      border: Border.all(color: _accent.withOpacity(0.25), width: 1),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: hasImage
                        ? Padding(
                      padding: const EdgeInsets.all(8),
                      child: _HealthAutoImage(
                        key: ValueKey('${imageUrl ?? ''}|${localImageFile?.path ?? ''}'),
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
    return const SizedBox(
      height: 140,
      child: Center(
        child: _PlaceholderIconText(),
      ),
    );
  }
}

class _HealthAutoImage extends StatelessWidget {
  const _HealthAutoImage({super.key});

  @override
  Widget build(BuildContext context) {
    final form = context.findAncestorWidgetOfExactType<HealthForm>()!;
    return AutoSizeImage(
      imageUrl: form.imageUrl,
      file: form.localImageFile,
      maxHeight: 360,
      borderRadius: 10,
      onTap: form.onImageTap,
    );
  }
}

class _PlaceholderIconText extends StatelessWidget {
  const _PlaceholderIconText();

  @override
  Widget build(BuildContext context) {
    final form = context.findAncestorWidgetOfExactType<HealthForm>()!;
    final accent = (kCategoryColorMap['health'] ?? AppColors.primaryAccent);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.add_photo_alternate_rounded, color: accent, size: 34),
        const SizedBox(height: 8),
        Text('사진 추가', style: TextStyle(color: accent, fontWeight: FontWeight.w600)),
      ],
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

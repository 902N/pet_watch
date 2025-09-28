// lib/pages/home_screen/record/forms/memo_form.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:APP/const/colors.dart';
import 'package:APP/pages/home_screen/model/schedule.dart' show kCategoryColorMap;
import 'package:APP/pages/home_screen/record/widgets/auto_size_image.dart';

class MemoForm extends StatelessWidget {
  final TextEditingController contentController;
  final String? imageUrl;
  final File? localImageFile;
  final VoidCallback? onImageTap;

  const MemoForm({
    super.key,
    required this.contentController,
    this.imageUrl,
    this.localImageFile,
    this.onImageTap,
  });

  Color get _accent => (kCategoryColorMap['memo'] ?? AppColors.primaryAccent);

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
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _accent.withOpacity(0.15), width: 1),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '내용',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 100, maxHeight: 200),
                child: TextField(
                  controller: contentController,
                  maxLines: null,
                  minLines: 4,
                  decoration: InputDecoration(
                    hintText: '자유롭게 기록해주세요.',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: _accent.withOpacity(0.25), width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: _accent.withOpacity(0.25), width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: _accent, width: 1.6),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.all(14),
                  ),
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
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
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
                    child: hasImage
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
        Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
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

import 'dart:io';
import 'package:flutter/material.dart';
import '../../const/colors.dart';

class PetAvatarPicker extends StatelessWidget {
  final File? imageFile;
  final VoidCallback onTap;
  const PetAvatarPicker({super.key, required this.imageFile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryAccent]),
        ),
        child: CircleAvatar(
          radius: 40,
          backgroundColor: AppColors.surfaceCard,
          backgroundImage: imageFile != null ? FileImage(imageFile!) : null,
          child: imageFile == null ? Icon(Icons.add_a_photo, color: AppColors.textSecondary) : null,
        ),
      ),
    );
  }
}

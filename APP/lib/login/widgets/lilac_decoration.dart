import 'package:flutter/material.dart';
import '../../const/colors.dart';

InputDecoration lilacDecoration(String label, {String? hint}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: textFieldFillColor,
    labelStyle: TextStyle(color: AppColors.textSecondary),
    hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.7)),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.divider),
      borderRadius: BorderRadius.circular(12),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.primaryAccent, width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
    errorBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.redAccent),
      borderRadius: BorderRadius.circular(12),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.redAccent, width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}

import 'package:flutter/material.dart';

// New theme tokens (Lilac light theme)
class AppColors {
  // === Core ===
  static const pageBackground = Color(0xFFFFFFFA); // ← 전체 화면 기본 배경 (Scaffold 등)
  static const appBarBackground = Color(0xFFFFFFFA); // ← AppBar/탭바 영역 배경
  static const sheetBackground = Color(0xFFFFFFFA); // ← BottomSheet/Modal 배경

  static const primary = Color(0xFFE9DDFC);      // surface tint / header strip
  static const primaryAccent = Color(0xFFC7B3F5); // selected chip / focus
  static const surfaceCard = Color(0xFFEEE7FA);   // 카드·강조 블록 배경(연라일락)

  static const textPrimary = Color(0xFF111111);
  static const textSecondary = Color(0xFF666666);
  static const divider = Color(0xFFEAEAEA);

  // Markers by category
  static const markerWalk = Color(0xFF38A3FF);
  static const markerMeal = Color(0xFF9B6BFF);
  static const markerHospital = Color(0xFF37D4B8);
  static const markerGrooming = Color(0xFFFF6FAE);
}

// Backward-compat aliases (do not break existing widgets)
const primaryColor = AppColors.primaryAccent;             // emphasis color
final lightGreyColor = AppColors.surfaceCard;             // day cell background
final darkGreyColor = AppColors.textSecondary;            // default text for calendar
final textFieldFillColor = AppColors.divider;             // input fill baseline

// Optional: 전역 ThemeData에서 바로 쓰고 싶으면
ThemeData appThemeLight() {
  return ThemeData(
    scaffoldBackgroundColor: AppColors.pageBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.appBarBackground,
      elevation: 0,
      surfaceTintColor: Colors.transparent, // M3 틴트 제거
      foregroundColor: AppColors.textPrimary,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.sheetBackground,
      surfaceTintColor: Colors.transparent,
    ),
    dividerColor: AppColors.divider,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryAccent,
      brightness: Brightness.light,
      primary: AppColors.primaryAccent,
      onPrimary: AppColors.textPrimary,
      surface: AppColors.pageBackground,
      onSurface: AppColors.textPrimary,
    ),
    useMaterial3: true,
  );
}

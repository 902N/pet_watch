import 'package:flutter/material.dart';

// Unified snackbar helpers for consistent styling across the app

void showSuccessSnack(
  BuildContext context,
  String message, {
  Color backgroundColor = Colors.green,
  Duration? duration,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      duration: duration ?? const Duration(seconds: 1),
    ),
  );
}

void showErrorSnack(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 4),
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      duration: duration,
    ),
  );
}

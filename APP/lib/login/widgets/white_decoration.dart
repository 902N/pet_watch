import 'package:flutter/material.dart';

const _lilacSoftBg = Color(0xFFF7F5FF);   // 성별/중성화와 동일한 배경
const _border      = Color(0xFFE5E7EB);
const _focus       = Color(0xFFBDBDBD);
const _hintGray    = Color(0xFFB0B3BA);   // 연한 회색

// 연보라 배경 + 연회색 라벨/힌트
InputDecoration lilacSoftDecoration(String label, {String? hint}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: _lilacSoftBg,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    labelStyle: const TextStyle(color: _hintGray),
    hintStyle: const TextStyle(color: _hintGray),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _border, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _focus, width: 1.2),
    ),
  );
}

// 혹시 흰 배경이 필요한 곳에서 쓰는 기본 데코(유지)
InputDecoration whiteDecoration(String label, {String? hint}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    labelStyle: const TextStyle(color: _hintGray),
    hintStyle: const TextStyle(color: _hintGray),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _border, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _focus, width: 1.2),
    ),
  );
}

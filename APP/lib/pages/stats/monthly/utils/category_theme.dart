import 'package:flutter/material.dart';

/// 월간/주간 공용 카테고리
/// ⚠️ monthly_view.dart 가 free / anomaly 를 참조하므로 반드시 포함!
enum RecordCategory { all, meal, walk, excretion, health, free, anomaly }

class CategoryTheme {
  // 팔레트
  static const Color meal      = Color(0xFF9B6BFF); // 보라
  static const Color walk      = Color(0xFF38A3FF); // 파랑
  static const Color excretion = Color(0xFFFF6FAE); // 핑크
  static const Color health    = Color(0xFF37D4B8); // 민트
  static const Color free      = Color(0xFF666666); // 회색 (자유기록)
  static const Color anomaly   = Color(0xFFEF4444); // 빨강 (이상기록)

  static Color colorOf(RecordCategory c, BuildContext ctx) {
    switch (c) {
      case RecordCategory.all:       return Theme.of(ctx).colorScheme.primary;
      case RecordCategory.meal:      return meal;
      case RecordCategory.walk:      return walk;
      case RecordCategory.excretion: return excretion;
      case RecordCategory.health:    return health;
      case RecordCategory.free:      return free;
      case RecordCategory.anomaly:   return anomaly;
    }
  }

  static String labelOf(RecordCategory c) {
    switch (c) {
      case RecordCategory.all:       return '전체';
      case RecordCategory.meal:      return '식사';
      case RecordCategory.walk:      return '산책';
      case RecordCategory.excretion: return '배변';
      case RecordCategory.health:    return '건강';
      case RecordCategory.free:      return '자유기록';
      case RecordCategory.anomaly:   return '이상기록';
    }
  }

  // 주간 보드에서 문자열 키 기반으로 색/라벨이 필요할 때 사용
  static Color colorByKey(String key, BuildContext ctx) {
    switch (key) {
      case 'meal':      return meal;
      case 'walk':      return walk;
      case 'excretion': return excretion;
      case 'health':    return health;
      case 'memo':      // 주간 뷰는 memo 키를 사용 -> free 색 적용
      case 'free':      return free;
      case 'anomaly':   return anomaly;
      default:          return Theme.of(ctx).colorScheme.primary;
    }
  }

  static String labelByKey(String key) {
    switch (key) {
      case 'meal':      return '식사';
      case 'walk':      return '산책';
      case 'excretion': return '배변';
      case 'health':    return '건강';
      case 'memo':
      case 'free':      return '자유';
      case 'anomaly':   return '이상';
      default:          return key;
    }
  }
}

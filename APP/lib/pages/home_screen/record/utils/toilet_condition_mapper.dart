// lib/pages/home_screen/record/utils/toilet_condition_mapper.dart

/// 배변 상태 UI 표시값과 API 전송값을 매핑하는 유틸리티 클래스
class ToiletConditionMapper {
  /// UI 표시용 값과 API 전송용 값을 매핑하는 테이블
  static const Map<String, String> _uiToApiMapping = {
    '탁한 소변': '탁한소변',
    '진한 황색': '진한황색',
    '주황색/초록색': '주황색초록색',
    '아주 옅은 색': '아주옅은색',
  };

  /// UI 표시값을 API 전송값으로 변환
  /// 
  /// 매핑 테이블에 없는 값은 그대로 반환
  static String toApiValue(String uiValue) {
    return _uiToApiMapping[uiValue] ?? uiValue;
  }

  /// API 전송값을 UI 표시값으로 변환 (필요시 사용)
  /// 
  /// 매핑 테이블에 없는 값은 그대로 반환
  static String toUiValue(String apiValue) {
    final reverseMapping = _uiToApiMapping.map((key, value) => MapEntry(value, key));
    return reverseMapping[apiValue] ?? apiValue;
  }

  /// 모든 UI 표시값 목록 반환
  static List<String> getAllUiValues() {
    return _uiToApiMapping.keys.toList();
  }

  /// 모든 API 전송값 목록 반환
  static List<String> getAllApiValues() {
    return _uiToApiMapping.values.toList();
  }
}

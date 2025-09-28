import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get _rawBase {
    final a = dotenv.env['BASE_URL'] ?? '';
    final b = dotenv.env['base_url'] ?? '';
    final v = (a.isNotEmpty ? a : b).trim();
    if (v.isEmpty) {
      throw StateError('BASE_URL(base_url) is missing');
    }
    return v.replaceAll(RegExp(r'/*$'), '');
  }

  static String get baseUrl => _rawBase;
  static String get apiBase => '$_rawBase/api/v1';
  static String get kakaoAccessField => (dotenv.env['KAKAO_ACCESS_FIELD'] ?? 'kakao_access_token').trim();
  static String get refreshField => (dotenv.env['REFRESH_FIELD'] ?? 'refresh_token').trim();
}

(String?, String?) extractTokens(dynamic body) {
  if (body is Map) {
    if (body['data'] is Map) {
      final d = Map<String, dynamic>.from(body['data']);
      return (d['accessToken'] as String? ?? d['access_token'] as String?, d['refreshToken'] as String? ?? d['refresh_token'] as String?);
    }
    return (body['accessToken'] as String? ?? body['access_token'] as String?, body['refreshToken'] as String? ?? body['refresh_token'] as String?);
  }
  return (null, null);
}

String extractError(dynamic body) {
  if (body is Map) {
    if (body['message'] is String) return body['message'];
    if (body['errorCode'] is String) return body['errorCode'];
  }
  return '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
}

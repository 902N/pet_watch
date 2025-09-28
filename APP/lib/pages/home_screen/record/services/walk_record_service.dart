// lib/pages/home_screen/record/services/walk_record_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:APP/auth/env.dart';
import '../models/walk_record_models.dart';
import '../models/common_record_models.dart';

class WalkRecordService {
  /// e.g. https://api.example.com/api/v1
  static String get baseUrl => Env.apiBase;

  static const _timeout = Duration(seconds: 15);

  static Map<String, String> _headers(String accessToken) => {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': '*/*',
    'Authorization': 'Bearer $accessToken',
  };

  // -------------------------
  // CREATE
  // -------------------------
  static Future<ApiResponse<WalkRecordResponse>> createWalkRecord({
    required int petId,
    required String accessToken,
    required WalkRecordRequest request,
  }) async {
    final url = Uri.parse('$baseUrl/pets/$petId/walk-records');
    final body = jsonEncode(request.toJson());

    _logOutgoing('POST', url, accessToken, body);

    try {
      final res = await http
          .post(url, headers: _headers(accessToken), body: body)
          .timeout(_timeout);

      _logIncoming(res);

      final json = _safeDecode(res.bodyBytes);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return ApiResponse.fromJson(json, (d) => WalkRecordResponse.fromJson(d));
      }
      throw Exception('산책 기록 생성 실패(${res.statusCode}): ${extractError(json)}');
    } catch (e) {
      throw Exception('산책 기록 생성 중 오류 발생: $e');
    }
  }

  // -------------------------
  // READ (DETAIL)
  // -------------------------
  static Future<ApiResponse<WalkRecordResponse>> getWalkRecord({
    required int petId,
    required int recordId,
    required String accessToken,
  }) async {
    final url = Uri.parse('$baseUrl/pets/$petId/walk-records/$recordId');

    _logOutgoing('GET', url, accessToken, null);

    try {
      final res =
      await http.get(url, headers: _headers(accessToken)).timeout(_timeout);

      _logIncoming(res);

      final json = _safeDecode(res.bodyBytes);
      if (res.statusCode == 200) {
        return ApiResponse.fromJson(json, (d) => WalkRecordResponse.fromJson(d));
      }
      throw Exception('산책 기록 조회 실패(${res.statusCode}): ${extractError(json)}');
    } catch (e) {
      throw Exception('산책 기록 조회 중 오류 발생: $e');
    }
  }

  // -------------------------
  // UPDATE
  // -------------------------
  static Future<ApiResponse<WalkRecordResponse>> updateWalkRecord({
    required int petId,
    required int recordId,
    required String accessToken,
    required WalkRecordRequest request,
  }) async {
    final url = Uri.parse('$baseUrl/pets/$petId/walk-records/$recordId');
    final body = jsonEncode(request.toJson());

    _logOutgoing('PUT', url, accessToken, body);

    try {
      final res = await http
          .put(url, headers: _headers(accessToken), body: body)
          .timeout(_timeout);

      _logIncoming(res);

      final json = _safeDecode(res.bodyBytes);
      if (res.statusCode == 200) {
        return ApiResponse.fromJson(json, (d) => WalkRecordResponse.fromJson(d));
      }
      throw Exception('산책 기록 수정 실패(${res.statusCode}): ${extractError(json)}');
    } catch (e) {
      throw Exception('산책 기록 수정 중 오류 발생: $e');
    }
  }

  // -------------------------
  // DELETE
  // -------------------------
  static Future<bool> deleteWalkRecord({
    required int petId,
    required int recordId,
    required String accessToken,
  }) async {
    final url = Uri.parse('$baseUrl/pets/$petId/walk-records/$recordId');

    _logOutgoing('DELETE', url, accessToken, null);

    try {
      final res =
      await http.delete(url, headers: _headers(accessToken)).timeout(_timeout);

      _logIncoming(res);

      // 보통 204를 기대하지만, 백엔드에 따라 200을 줄 수도 있음
      if (res.statusCode == 204 || res.statusCode == 200) return true;

      final json = _safeDecode(res.bodyBytes);
      throw Exception('산책 기록 삭제 실패(${res.statusCode}): ${extractError(json)}');
    } catch (e) {
      throw Exception('산책 기록 삭제 중 오류 발생: $e');
    }
  }

  // =========================
  // Helpers
  // =========================
  static Map<String, dynamic> _safeDecode(List<int> bodyBytes) {
    if (bodyBytes.isEmpty) return <String, dynamic>{};
    final text = utf8.decode(bodyBytes);
    if (text.trim().isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(text);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  static void _logOutgoing(
      String method, Uri url, String accessToken, String? body) {
    // 토큰은 길어서 일부만 출력(보안)
    final tokenShort =
    accessToken.length > 10 ? '${accessToken.substring(0, 10)}...' : accessToken;
    // ignore: avoid_print
    print('[WalkRecord] $method $url');
    // ignore: avoid_print
    print('headers=${_headers(accessToken)..update('Authorization', (v) => 'Bearer $tokenShort')}');
    if (body != null) {
      // ignore: avoid_print
      print('body=$body');
    }
  }

  static void _logIncoming(http.Response res) {
    // ignore: avoid_print
    print('status=${res.statusCode}');
    if (res.bodyBytes.isNotEmpty) {
      // ignore: avoid_print
      print('response=${utf8.decode(res.bodyBytes)}');
    }
  }
}

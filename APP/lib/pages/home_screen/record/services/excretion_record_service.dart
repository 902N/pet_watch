// lib/pages/home_screen/record/services/excretion_record_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:APP/auth/env.dart';

import '../models/excretion_record_models.dart';
import '../models/common_record_models.dart';

class ExcretionRecordService {
  static String get baseUrl => Env.apiBase;

  static Map<String, String> _headers(String accessToken) => {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': '*/*',
    'Authorization': 'Bearer $accessToken',
  };

  // 배변 기록 생성
  static Future<ApiResponse<ExcretionRecordResponse>> createExcretionRecord({
    required int petId,
    required String accessToken,
    required ExcretionRecordRequest request,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/pets/$petId/excretion-records');
      final body = jsonEncode(request.toJson());

      if (kDebugMode) debugPrint(' [ExcretionRecord] POST $url');
      if (kDebugMode) debugPrint(' body=$body');

      final res = await http.post(url, headers: _headers(accessToken), body: body);

      if (kDebugMode) debugPrint(' status=${res.statusCode}');
      if (kDebugMode) debugPrint(' response=${utf8.decode(res.bodyBytes)}');

      final text = utf8.decode(res.bodyBytes);
      final data = text.isEmpty ? {} : jsonDecode(text);

      if (res.statusCode == 200 || res.statusCode == 201) {
        return ApiResponse.fromJson(
          data,
              (d) => ExcretionRecordResponse.fromJson(d),
        );
      } else {
        final msg = extractError(data);
        throw Exception('배변 기록 생성 실패(${res.statusCode}): $msg');
      }
    } catch (e) {
      throw Exception('배변 기록 생성 중 오류 발생: $e');
    }
  }

  // 배변 기록 조회
  static Future<ApiResponse<ExcretionRecordResponse>> getExcretionRecord({
    required int petId,
    required int recordId,
    required String accessToken,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/pets/$petId/excretion-records/$recordId');

      if (kDebugMode) debugPrint(' [ExcretionRecord] GET $url');

      final res = await http.get(url, headers: _headers(accessToken));

      if (kDebugMode) debugPrint(' status=${res.statusCode}');
      if (kDebugMode) debugPrint(' response=${utf8.decode(res.bodyBytes)}');

      final text = utf8.decode(res.bodyBytes);
      final data = text.isEmpty ? {} : jsonDecode(text);

      if (res.statusCode == 200) {
        return ApiResponse.fromJson(
          data,
              (d) => ExcretionRecordResponse.fromJson(d),
        );
      } else {
        final msg = extractError(data);
        throw Exception('배변 기록 조회 실패(${res.statusCode}): $msg');
      }
    } catch (e) {
      throw Exception('배변 기록 조회 중 오류 발생: $e');
    }
  }

  // 배변 기록 수정
  static Future<ApiResponse<ExcretionRecordResponse>> updateExcretionRecord({
    required int petId,
    required int recordId,
    required String accessToken,
    required ExcretionRecordRequest request,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/pets/$petId/excretion-records/$recordId');
      final body = jsonEncode(request.toJson());

      if (kDebugMode) debugPrint(' [ExcretionRecord] PUT $url');
      if (kDebugMode) debugPrint(' body=$body');

      final res = await http.put(url, headers: _headers(accessToken), body: body);

      if (kDebugMode) debugPrint(' status=${res.statusCode}');
      if (kDebugMode) debugPrint(' response=${utf8.decode(res.bodyBytes)}');

      final text = utf8.decode(res.bodyBytes);
      final data = text.isEmpty ? {} : jsonDecode(text);

      if (res.statusCode == 200) {
        return ApiResponse.fromJson(
          data,
              (d) => ExcretionRecordResponse.fromJson(d),
        );
      } else {
        final msg = extractError(data);
        throw Exception('배변 기록 수정 실패(${res.statusCode}): $msg');
      }
    } catch (e) {
      throw Exception('배변 기록 수정 중 오류 발생: $e');
    }
  }

  // 배변 기록 삭제
  static Future<bool> deleteExcretionRecord({
    required int petId,
    required int recordId,
    required String accessToken,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/pets/$petId/excretion-records/$recordId');

      if (kDebugMode) debugPrint(' [ExcretionRecord] DELETE $url');

      final res = await http.delete(url, headers: _headers(accessToken));

      if (kDebugMode) debugPrint(' status=${res.statusCode}');
      if (res.bodyBytes.isNotEmpty) {
        if (kDebugMode) debugPrint(' response=${utf8.decode(res.bodyBytes)}');
      }

      if (res.statusCode == 204 || res.statusCode == 200) return true;

      final text = utf8.decode(res.bodyBytes);
      final data = text.isEmpty ? {} : jsonDecode(text);
      final msg = extractError(data);
      throw Exception('배변 기록 삭제 실패(${res.statusCode}): $msg');
    } catch (e) {
      throw Exception('배변 기록 삭제 중 오류 발생: $e');
    }
  }
}

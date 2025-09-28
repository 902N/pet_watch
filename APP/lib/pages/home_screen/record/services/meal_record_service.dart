// lib/pages/home_screen/record/services/meal_record_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:APP/auth/env.dart';

import '../models/meal_record_models.dart';
import '../models/common_record_models.dart';

class MealRecordService {
  static String get baseUrl => Env.apiBase;

  static Map<String, String> _headers(String accessToken) => {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': '*/*',
    'Authorization': 'Bearer $accessToken',
  };

  static Future<ApiResponse<MealRecordResponse>> createMealRecord({
    required int petId,
    required String accessToken,
    required MealRecordRequest request,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/pets/$petId/meal-records');
      final body = jsonEncode(request.toJson());

      if (kDebugMode) debugPrint(' [MealRecord] POST $url');
      if (kDebugMode) debugPrint(' body=$body');

      final res = await http.post(url, headers: _headers(accessToken), body: body);

      if (kDebugMode) debugPrint(' status=${res.statusCode}');
      if (kDebugMode) debugPrint(' response=${utf8.decode(res.bodyBytes)}');

      final text = utf8.decode(res.bodyBytes);
      final data = text.isEmpty ? {} : jsonDecode(text);

      if (res.statusCode == 200 || res.statusCode == 201) {
        return ApiResponse.fromJson(
          data,
              (d) => MealRecordResponse.fromJson(d),
        );
      } else {
        final msg = extractError(data);
        throw Exception('식사 기록 생성 실패(${res.statusCode}): $msg');
      }
    } catch (e) {
      throw Exception('식사 기록 생성 중 오류 발생: $e');
    }
  }

  static Future<ApiResponse<MealRecordResponse>> getMealRecord({
    required int petId,
    required int recordId,
    required String accessToken,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/pets/$petId/meal-records/$recordId');

      if (kDebugMode) debugPrint(' [MealRecord] GET $url');

      final res = await http.get(url, headers: _headers(accessToken));

      if (kDebugMode) debugPrint(' status=${res.statusCode}');
      if (kDebugMode) debugPrint(' response=${utf8.decode(res.bodyBytes)}');

      final text = utf8.decode(res.bodyBytes);
      final data = text.isEmpty ? {} : jsonDecode(text);

      if (res.statusCode == 200) {
        return ApiResponse.fromJson(
          data,
              (d) => MealRecordResponse.fromJson(d),
        );
      } else {
        final msg = extractError(data);
        throw Exception('식사 기록 조회 실패(${res.statusCode}): $msg');
      }
    } catch (e) {
      throw Exception('식사 기록 조회 중 오류 발생: $e');
    }
  }

  static Future<ApiResponse<MealRecordResponse>> updateMealRecord({
    required int petId,
    required int recordId,
    required String accessToken,
    required MealRecordRequest request,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/pets/$petId/meal-records/$recordId');
      final body = jsonEncode(request.toJson());

      if (kDebugMode) debugPrint(' [MealRecord] PUT $url');
      if (kDebugMode) debugPrint(' body=$body');

      final res = await http.put(url, headers: _headers(accessToken), body: body);

      if (kDebugMode) debugPrint(' status=${res.statusCode}');
      if (kDebugMode) debugPrint(' response=${utf8.decode(res.bodyBytes)}');

      final text = utf8.decode(res.bodyBytes);
      final data = text.isEmpty ? {} : jsonDecode(text);

      if (res.statusCode == 200) {
        return ApiResponse.fromJson(
          data,
              (d) => MealRecordResponse.fromJson(d),
        );
      } else {
        final msg = extractError(data);
        throw Exception('식사 기록 수정 실패(${res.statusCode}): $msg');
      }
    } catch (e) {
      throw Exception('식사 기록 수정 중 오류 발생: $e');
    }
  }

  static Future<bool> deleteMealRecord({
    required int petId,
    required int recordId,
    required String accessToken,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/pets/$petId/meal-records/$recordId');

      if (kDebugMode) debugPrint(' [MealRecord] DELETE $url');

      final res = await http.delete(url, headers: _headers(accessToken));

      if (kDebugMode) debugPrint(' status=${res.statusCode}');
      if (res.bodyBytes.isNotEmpty) {
        if (kDebugMode) debugPrint(' response=${utf8.decode(res.bodyBytes)}');
      }

      if (res.statusCode == 204 || res.statusCode == 200) return true;

      final text = utf8.decode(res.bodyBytes);
      final data = text.isEmpty ? {} : jsonDecode(text);
      final msg = extractError(data);
      throw Exception('식사 기록 삭제 실패(${res.statusCode}): $msg');
    } catch (e) {
      throw Exception('식사 기록 삭제 중 오류 발생: $e');
    }
  }
}

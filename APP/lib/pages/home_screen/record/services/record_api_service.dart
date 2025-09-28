// lib/pages/home_screen/record/services/record_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:APP/auth/env.dart';
import '../models/record_api_models.dart';
import '../models/common_record_models.dart';

class RecordApiService {
  static String get baseUrl => Env.apiBase;

  static Map<String, String> _headers(String accessToken) => {
    'Accept': '*/*',
    'Authorization': 'Bearer $accessToken',
  };

  static String _pretty(Object? o) {
    try {
      return const JsonEncoder.withIndent('  ').convert(o);
    } catch (_) {
      return o.toString();
    }
  }

  static Future<ApiResponse<MonthRecordsResponse>> getMonthRecords({
    required int petId,
    required String accessToken,
    required int year,
    required int month,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/pets/$petId/month-records?year=$year&month=$month');
      final res = await http.get(url, headers: _headers(accessToken));
      final text = utf8.decode(res.bodyBytes);
      final data = text.isEmpty ? {} : jsonDecode(text);
      // ignore: avoid_print
      print('[MONTH RAW] ${_pretty(data)}');
      if (res.statusCode == 200) {
        return ApiResponse.fromJson(
          data,
              (d) => MonthRecordsResponse.fromJson(d),
        );
      } else {
        final msg = extractError(data);
        throw Exception('월별 기록 조회 실패(${res.statusCode}): $msg');
      }
    } catch (e) {
      throw Exception('월별 기록 조회 중 오류 발생: $e');
    }
  }

  static Future<ApiResponse<DayRecordsResponse>> getDayRecords({
    required int petId,
    required String accessToken,
    required int year,
    required int month,
    required int day,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/pets/$petId/day-records?year=$year&month=$month&day=$day');
      final res = await http.get(url, headers: _headers(accessToken));
      final text = utf8.decode(res.bodyBytes);
      final data = text.isEmpty ? {} : jsonDecode(text);
      // ignore: avoid_print
      print('[DAY RAW] ${_pretty(data)}');
      if (res.statusCode == 200) {
        final parsed = ApiResponse.fromJson(
          data,
              (d) => DayRecordsResponse.fromJson(d),
        );
        try {
          final v = parsed.data;
          if (v != null) {
            final memoLen = (v.freeRecords).length;
            // ignore: avoid_print
            print('[DAY COUNT] meal=${v.mealRecords.length} walk=${v.walkRecords.length} toilet=${v.excretionRecords.length} health=${v.healthRecords.length} memo=$memoLen');
          }
        } catch (_) {}
        return parsed;
      } else {
        final msg = extractError(data);
        throw Exception('일별 기록 조회 실패(${res.statusCode}): $msg');
      }
    } catch (e) {
      throw Exception('일별 기록 조회 중 오류 발생: $e');
    }
  }

  static Future<Map<String, dynamic>> probeDayRecordsRaw({
    required int petId,
    required String accessToken,
    required int year,
    required int month,
    required int day,
  }) async {
    final url = Uri.parse('$baseUrl/pets/$petId/day-records?year=$year&month=$month&day=$day');
    final res = await http.get(url, headers: _headers(accessToken));
    final text = utf8.decode(res.bodyBytes);
    final data = text.isEmpty ? {} : jsonDecode(text);
    // ignore: avoid_print
    print('[DAY PROBE] ${_pretty(data)}');
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data is Map<String, dynamic> ? data : {'data': data};
    } else {
      throw Exception('probe 실패(${res.statusCode})');
    }
  }
}

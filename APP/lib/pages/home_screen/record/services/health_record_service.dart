import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:APP/auth/env.dart';

import '../models/health_record_models.dart';
import '../models/common_record_models.dart';

class HealthRecordService {
  static String get baseUrl => Env.apiBase;

  static Map<String, String> _headers(String accessToken) => {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': '*/*',
    'Authorization': 'Bearer $accessToken',
  };

  static Map<String, String> _authOnly(String accessToken) => {
    'Accept': '*/*',
    'Authorization': 'Bearer $accessToken',
  };

  static Future<ApiResponse<HealthRecordResponse>> createHealthRecord({
    required int petId,
    required String accessToken,
    required HealthRecordRequest request,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/pets/$petId/health-records');
      final body = jsonEncode(request.toJson());
      if (kDebugMode) debugPrint(' [HealthRecord] POST $url');
      if (kDebugMode) debugPrint(' body=$body');
      final res = await http.post(url, headers: _headers(accessToken), body: body);
      if (kDebugMode) debugPrint(' status=${res.statusCode}');
      if (kDebugMode) debugPrint(' response=${utf8.decode(res.bodyBytes)}');
      final text = utf8.decode(res.bodyBytes);
      final data = text.isEmpty ? {} : jsonDecode(text);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return ApiResponse.fromJson(data, (d) => HealthRecordResponse.fromJson(d));
      } else {
        final msg = extractError(data);
        throw Exception('건강 기록 생성 실패(${res.statusCode}): $msg');
      }
    } catch (e) {
      throw Exception('건강 기록 생성 중 오류 발생: $e');
    }
  }

  static Future<ApiResponse<HealthRecordResponse>> createHealthRecordMultipart({
    required int petId,
    required String accessToken,
    required HealthRecordRequest request,
    File? imageFile,
    String imageField = 'image',
    String jsonField = 'data',
    String? imageMimeType,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/pets/$petId/health-records');
      if (kDebugMode) debugPrint(' [HealthRecord] MULTIPART POST $url');
      final m = http.MultipartRequest('POST', url);
      m.headers.addAll(_authOnly(accessToken));
      m.fields[jsonField] = jsonEncode(request.toJson());
      if (imageFile != null) {
        final name = imageFile.path.split(Platform.pathSeparator).last;
        final mime = imageMimeType ?? _guessMime(name);
        m.files.add(await http.MultipartFile.fromPath(
          imageField,
          imageFile.path,
          filename: name,
          contentType: MediaType.parse(mime),
        ));
      }
      final streamed = await m.send();
      final res = await http.Response.fromStream(streamed);
      if (kDebugMode) debugPrint(' status=${res.statusCode}');
      if (kDebugMode) debugPrint(' response=${utf8.decode(res.bodyBytes)}');
      final text = utf8.decode(res.bodyBytes);
      final data = text.isEmpty ? {} : jsonDecode(text);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return ApiResponse.fromJson(data, (d) => HealthRecordResponse.fromJson(d));
      } else {
        final msg = extractError(data);
        throw Exception('건강 기록 생성 실패(${res.statusCode}): $msg');
      }
    } catch (e) {
      throw Exception('건강 기록 생성 중 오류 발생: $e');
    }
  }

  static Future<ApiResponse<HealthRecordResponse>> getHealthRecord({
    required int petId,
    required int recordId,
    required String accessToken,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/pets/$petId/health-records/$recordId');
      if (kDebugMode) debugPrint(' [HealthRecord] GET $url');
      final res = await http.get(url, headers: _headers(accessToken));
      if (kDebugMode) debugPrint(' status=${res.statusCode}');
      if (kDebugMode) debugPrint(' response=${utf8.decode(res.bodyBytes)}');
      final text = utf8.decode(res.bodyBytes);
      final data = text.isEmpty ? {} : jsonDecode(text);
      if (res.statusCode == 200) {
        return ApiResponse.fromJson(data, (d) => HealthRecordResponse.fromJson(d));
      } else {
        final msg = extractError(data);
        throw Exception('건강 기록 조회 실패(${res.statusCode}): $msg');
      }
    } catch (e) {
      throw Exception('건강 기록 조회 중 오류 발생: $e');
    }
  }

  static Future<ApiResponse<HealthRecordResponse>> updateHealthRecord({
    required int petId,
    required int recordId,
    required String accessToken,
    required HealthRecordRequest request,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/pets/$petId/health-records/$recordId');
      final body = jsonEncode(request.toJson());
      if (kDebugMode) debugPrint(' [HealthRecord] PUT $url');
      if (kDebugMode) debugPrint(' body=$body');
      final res = await http.put(url, headers: _headers(accessToken), body: body);
      if (kDebugMode) debugPrint(' status=${res.statusCode}');
      if (kDebugMode) debugPrint(' response=${utf8.decode(res.bodyBytes)}');
      final text = utf8.decode(res.bodyBytes);
      final data = text.isEmpty ? {} : jsonDecode(text);
      if (res.statusCode == 200) {
        return ApiResponse.fromJson(data, (d) => HealthRecordResponse.fromJson(d));
      } else {
        final msg = extractError(data);
        throw Exception('건강 기록 수정 실패(${res.statusCode}): $msg');
      }
    } catch (e) {
      throw Exception('건강 기록 수정 중 오류 발생: $e');
    }
  }

  static Future<ApiResponse<HealthRecordResponse>> updateHealthRecordMultipart({
    required int petId,
    required int recordId,
    required String accessToken,
    required HealthRecordRequest request,
    File? imageFile,
    String imageField = 'image',
    String jsonField = 'data',
    String? imageMimeType,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/pets/$petId/health-records/$recordId');
      if (kDebugMode) debugPrint(' [HealthRecord] MULTIPART PUT $url');
      final m = http.MultipartRequest('PUT', url);
      m.headers.addAll(_authOnly(accessToken));
      m.fields[jsonField] = jsonEncode(request.toJson());
      if (imageFile != null) {
        final name = imageFile.path.split(Platform.pathSeparator).last;
        final mime = imageMimeType ?? _guessMime(name);
        m.files.add(await http.MultipartFile.fromPath(
          imageField,
          imageFile.path,
          filename: name,
          contentType: MediaType.parse(mime),
        ));
      }
      final streamed = await m.send();
      final res = await http.Response.fromStream(streamed);
      if (kDebugMode) debugPrint(' status=${res.statusCode}');
      if (kDebugMode) debugPrint(' response=${utf8.decode(res.bodyBytes)}');
      final text = utf8.decode(res.bodyBytes);
      final data = text.isEmpty ? {} : jsonDecode(text);
      if (res.statusCode == 200) {
        return ApiResponse.fromJson(data, (d) => HealthRecordResponse.fromJson(d));
      } else {
        final msg = extractError(data);
        throw Exception('건강 기록 수정 실패(${res.statusCode}): $msg');
      }
    } catch (e) {
      throw Exception('건강 기록 수정 중 오류 발생: $e');
    }
  }

  static Future<bool> deleteHealthRecord({
    required int petId,
    required int recordId,
    required String accessToken,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/pets/$petId/health-records/$recordId');
      if (kDebugMode) debugPrint(' [HealthRecord] DELETE $url');
      final res = await http.delete(url, headers: _headers(accessToken));
      if (kDebugMode) debugPrint(' status=${res.statusCode}');
      if (res.statusCode == 204 || res.statusCode == 200) return true;
      final text = utf8.decode(res.bodyBytes);
      final data = text.isEmpty ? {} : jsonDecode(text);
      final msg = extractError(data);
      throw Exception('건강 기록 삭제 실패(${res.statusCode}): $msg');
    } catch (e) {
      throw Exception('건강 기록 삭제 중 오류 발생: $e');
    }
  }

  static String _guessMime(String name) {
    final n = name.toLowerCase();
    if (n.endsWith('.png')) return 'image/png';
    if (n.endsWith('.jpg') || n.endsWith('.jpeg')) return 'image/jpeg';
    if (n.endsWith('.webp')) return 'image/webp';
    if (n.endsWith('.heic')) return 'image/heic';
    return 'application/octet-stream';
  }
}

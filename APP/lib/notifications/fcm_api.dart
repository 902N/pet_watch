// lib/api/fcm_api.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:APP/auth/env.dart';
import 'package:APP/auth/auth_api.dart'; // AuthApi.client (Dio + 인터셉터)

/// =======================
///  HTTP Debug Utilities
/// =======================
class _HttpDebug {
  static bool enabled = kDebugMode;

  static String _pretty(Object? data) {
    try {
      if (data is String) {
        final j = jsonDecode(data);
        return const JsonEncoder.withIndent('  ').convert(j);
      } else if (data is Map || data is List) {
        return const JsonEncoder.withIndent('  ').convert(data);
      }
    } catch (_) {}
    return data?.toString() ?? 'null';
  }

  static void logRequest({
    required Uri url,
    required String method,
    Map<String, String>? headers,
    Object? body,
  }) {
    if (!enabled) return;
    debugPrint('*** Request *** $method $url');
    if (headers != null && headers.isNotEmpty) {
      final redacted = Map<String, String>.from(headers);
      final auth = redacted['Authorization'];
      if (auth != null && auth.toLowerCase().startsWith('bearer ')) {
        redacted['Authorization'] = 'Bearer ***';
      }
      debugPrint('Headers:\n${const JsonEncoder.withIndent('  ').convert(redacted)}');
    }
    if (body != null) {
      debugPrint('Body:\n${_pretty(body)}');
    }
  }

  static void logResponse({
    required Uri url,
    required int status,
    Map<String, String>? headers,
    String? body,
    Duration? duration,
  }) {
    if (!enabled) return;
    debugPrint(
      '*** Response *** $status $url${duration != null ? ' (${duration.inMilliseconds}ms)' : ''}',
    );
    if (headers != null && headers.isNotEmpty) {
      debugPrint('Resp Headers:\n${const JsonEncoder.withIndent('  ').convert(headers)}');
    }
    if (body != null) {
      debugPrint('Resp Body:\n${_pretty(body)}');
    }
  }

  static void logError({
    required Uri url,
    Object? error,
    Duration? duration,
  }) {
    if (!enabled) return;
    debugPrint('*** Error *** $url${duration != null ? ' (${duration.inMilliseconds}ms)' : ''}\n$error');
  }
}

/// =======================
///  FCM API
/// =======================
class FcmApi {
  static const _kDeviceIdKey = 'device_id';

  static Future<String> deviceId() async {
    final sp = await SharedPreferences.getInstance();
    var id = sp.getString(_kDeviceIdKey);
    if (id == null || id.isEmpty) {
      id = _makeId();
      await sp.setString(_kDeviceIdKey, id);
    }
    return id;
  }

  static String _makeId() {
    final r = Random.secure();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    final b = StringBuffer();
    for (final v in bytes) {
      b.write(v.toRadixString(16).padLeft(2, '0'));
    }
    return b.toString();
  }

  static String _deviceType() {
    if (Platform.isAndroid) return 'ANDROID';
    if (Platform.isIOS) return 'IOS';
    return 'OTHER';
  }

  /// FCM 토큰 등록
  /// - 성공: true, 실패: false
  static Future<bool> syncToken(String token) async {
    final sw = Stopwatch()..start();
    final base = Env.baseUrl;
    if (base.isEmpty) return false;

    final did = await deviceId();
    final url = Uri.parse('$base/api/v1/notifications/fcm-token');

    // 디버그 로그(헤더는 인터셉터가 넣으므로 여기선 내용만)
    _HttpDebug.logRequest(
      url: url,
      method: 'POST',
      headers: const {'Content-Type': 'application/json', 'Accept': '*/*'},
      body: {
        'fcmToken': token,
        'deviceType': _deviceType(),
        'deviceId': did,
      },
    );

    try {
      final rsp = await AuthApi.client.post(
        '/notifications/fcm-token',
        data: {
          'fcmToken': token,
          'deviceType': _deviceType(),
          'deviceId': did,
        },
        options: Options(validateStatus: (_) => true),
      );

      final respBody = _tryStringify(rsp.data);
      _HttpDebug.logResponse(
        url: url,
        status: rsp.statusCode ?? 0,
        headers: _flattenHeaders(rsp.headers),
        body: respBody,
        duration: sw.elapsed,
      );

      return rsp.statusCode == 200;
    } catch (e) {
      _HttpDebug.logError(url: url, error: e, duration: sw.elapsed);
      rethrow;
    }
  }

  /// 이 기기만 등록 해제
  static Future<bool> disableThisDevice() async {
    final sw = Stopwatch()..start();
    final base = Env.baseUrl;
    final did = await deviceId();
    final url = Uri.parse('$base/api/v1/notifications/fcm-token?deviceId=$did');

    _HttpDebug.logRequest(url: url, method: 'DELETE', headers: const {'Accept': '*/*'});

    try {
      final rsp = await AuthApi.client.delete(
        '/notifications/fcm-token',
        queryParameters: {'deviceId': did},
        options: Options(validateStatus: (_) => true),
      );

      final respBody = _tryStringify(rsp.data);
      _HttpDebug.logResponse(
        url: url,
        status: rsp.statusCode ?? 0,
        headers: _flattenHeaders(rsp.headers),
        body: respBody,
        duration: sw.elapsed,
      );

      return rsp.statusCode == 200;
    } catch (e) {
      _HttpDebug.logError(url: url, error: e, duration: sw.elapsed);
      rethrow;
    }
  }

  /// 모든 기기 등록 해제
  static Future<bool> disableAll() async {
    final sw = Stopwatch()..start();
    final base = Env.baseUrl;
    final url = Uri.parse('$base/api/v1/notifications/fcm-token/all');

    _HttpDebug.logRequest(url: url, method: 'DELETE', headers: const {'Accept': '*/*'});

    try {
      final rsp = await AuthApi.client.delete(
        '/notifications/fcm-token/all',
        options: Options(validateStatus: (_) => true),
      );

      final respBody = _tryStringify(rsp.data);
      _HttpDebug.logResponse(
        url: url,
        status: rsp.statusCode ?? 0,
        headers: _flattenHeaders(rsp.headers),
        body: respBody,
        duration: sw.elapsed,
      );

      return rsp.statusCode == 200;
    } catch (e) {
      _HttpDebug.logError(url: url, error: e, duration: sw.elapsed);
      rethrow;
    }
  }

  /// 이 기기의 등록 상태 조회
  /// - 성공 시 true/false, 실패/파싱불가 시 null
  static Future<bool?> status() async {
    final sw = Stopwatch()..start();
    final base = Env.baseUrl;
    final did = await deviceId();
    final url = Uri.parse('$base/api/v1/notifications/fcm-token/status?deviceId=$did');

    _HttpDebug.logRequest(url: url, method: 'GET', headers: const {'Accept': '*/*'});

    try {
      final rsp = await AuthApi.client.get(
        '/notifications/fcm-token/status',
        queryParameters: {'deviceId': did},
        options: Options(validateStatus: (_) => true),
      );

      final respBody = _tryStringify(rsp.data);
      _HttpDebug.logResponse(
        url: url,
        status: rsp.statusCode ?? 0,
        headers: _flattenHeaders(rsp.headers),
        body: respBody,
        duration: sw.elapsed,
      );

      if (rsp.statusCode == 200) {
        final data = rsp.data;
        if (data is Map) {
          final inner = data['data'];
          if (inner is bool) return inner;
        }
      }
      return null;
    } catch (e) {
      _HttpDebug.logError(url: url, error: e, duration: sw.elapsed);
      rethrow;
    }
  }

  /// ===== Helpers =====
  static String? _tryStringify(dynamic data) {
    if (data == null) return null;
    try {
      if (data is String) return data;
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      return data.toString();
    }
  }

  static Map<String, String> _flattenHeaders(Headers h) {
    final out = <String, String>{};
    for (final e in h.map.entries) {
      out[e.key] = e.value.join(', ');
    }
    return out;
  }
}

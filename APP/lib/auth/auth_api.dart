import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'env.dart';

class TokenStore {
  static const _ak = 'accesstoken';
  static const _rk = 'refreshtoken';

  static Future<void> save(String a, String r) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_ak, a);
    await p.setString(_rk, r);
  }

  static Future<String?> access() async =>
      (await SharedPreferences.getInstance()).getString(_ak);

  static Future<String?> refresh() async =>
      (await SharedPreferences.getInstance()).getString(_rk);

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_ak);
    await p.remove(_rk);
  }
}

class AuthApi {
  static Dio? _dio;
  static Dio get client {
    _dio ??= Dio(
      BaseOptions(
        baseUrl: Env.apiBase,
        headers: {'Content-Type': 'application/json', 'Accept': '*/*'},
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        validateStatus: (c) => true,
      ),
    )
      ..interceptors.clear()
      ..interceptors.add(_AuthInterceptor())
      ..interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
    return _dio!;
  }

  static Future<Response> loginWithKakaoRaw(String kakaoAccess) {
    return client.post(
      '/auth/login/kakao',
      data: {Env.kakaoAccessField: kakaoAccess},
      options: Options(validateStatus: (_) => true, extra: {'skipAuth': true}),
    );
  }

  static Future<Response> reissueRaw(String refreshToken) {
    return client.post(
      '/auth/reissue',
      data: {Env.refreshField: refreshToken},
      options: Options(validateStatus: (_) => true, extra: {'skipAuth': true}),
    );
  }
}

class _AuthInterceptor extends Interceptor {
  static Future<void>? _refreshing;

  @override
  Future<void> onRequest(RequestOptions o, RequestInterceptorHandler h) async {
    if (o.extra['skipAuth'] == true) return h.next(o);
    final at = await TokenStore.access();
    if (at != null && at.isNotEmpty) {
      o.headers['Authorization'] = 'Bearer $at';
    }
    h.next(o);
  }

  @override
  Future<void> onError(DioException e, ErrorInterceptorHandler h) async {
    final status = e.response?.statusCode;
    final req = e.requestOptions;
    final skip = req.extra['skipAuth'] == true;
    if (status != 401 || skip) return h.next(e);

    if (_refreshing == null) {
      _refreshing = _doRefresh();
      try { await _refreshing; } finally { _refreshing = null; }
    } else {
      await _refreshing;
    }

    final na = await TokenStore.access();
    if (na == null || na.isEmpty) return h.next(e);

    req.headers['Authorization'] = 'Bearer $na';
    try {
      final clone = await AuthApi.client.fetch(req);
      return h.resolve(clone);
    } catch (_) {
      return h.next(e);
    }
  }

  // 응답에서 access/refresh 토큰 키 자동 탐지 (String/Map, data 래핑 모두 대응)
  (String?, String?) _extractTokens(dynamic raw) {
    try {
      dynamic body = raw;
      if (body is String) {
        try { body = jsonDecode(body); } catch (_) {}
      }
      if (body is Map) {
        final Map src = body['data'] is Map ? body['data'] as Map : body;
        String? at, rt;
        for (final k in src.keys) {
          final key = k.toString().toLowerCase();
          if (key.contains('access') && key.contains('token')) {
            at = src[k]?.toString();
          } else if (key.contains('refresh') && key.contains('token')) {
            rt = src[k]?.toString();
          }
        }
        return (at, rt);
      }
    } catch (_) {}
    return (null, null);
  }

  Future<void> _doRefresh() async {
    try {
      final rt = await TokenStore.refresh();
      if (rt == null || rt.isEmpty) {
        await TokenStore.clear();
        return;
      }
      final rsp = await AuthApi.reissueRaw(rt);
      if (rsp.statusCode == 200) {
        final (a, r) = _extractTokens(rsp.data);
        if (a != null && a.isNotEmpty && r != null && r.isNotEmpty) {
          await TokenStore.save(a, r);
          final sp = await SharedPreferences.getInstance();
          await sp.setString('access_token', a);
          await sp.setString('refresh_token', r);
          await sp.setString('accessToken', a);
          await sp.setString('refreshToken', r);
          return;
        }
      }
      await TokenStore.clear();
    } catch (_) {
      return;
    }
  }
}

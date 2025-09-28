// lib/api/s3_api.dart
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

import 'package:APP/auth/auth_api.dart';
import 'package:APP/auth/env.dart';

class S3UploadInfo {
  final String s3Key;
  final String uploadUrl;
  final String fileUrl;
  final Map<String, List<String>> requiredHeaders;
  final int expirySeconds;

  S3UploadInfo({
    required this.s3Key,
    required this.uploadUrl,
    required this.fileUrl,
    required this.requiredHeaders,
    required this.expirySeconds,
  });

  factory S3UploadInfo.fromJson(Map<String, dynamic> j) {
    final h = <String, List<String>>{};
    if (j['requiredHeaders'] is Map) {
      (j['requiredHeaders'] as Map).forEach((k, v) {
        if (v is List) h[k.toString()] = v.map((e) => e.toString()).toList();
      });
    }
    return S3UploadInfo(
      s3Key: j['s3Key'] as String,
      uploadUrl: j['uploadUrl'] as String,
      fileUrl: j['fileUrl'] as String,
      requiredHeaders: h,
      expirySeconds: (j['expirySeconds'] as num).toInt(),
    );
  }
}

class S3Api {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    followRedirects: true,         // ★ S3 307/308 대비
    maxRedirects: 5,
  ));

  /// 프리사인 URL 발급
  ///
  /// - 보안 자원이라면 Authorization 필요.
  /// - `AuthApi.client`가 토큰을 주입해 준다면 `useAuthClient = true`.
  /// - 아니라면 `accessToken`을 직접 전달.
  static Future<S3UploadInfo> presign({
    required String fileName,
    required String mimeType,
    required int fileSize,
    String? accessToken,               // ★ 선택적으로 토큰 직접 주입
    bool useAuthClient = true,         // ★ 기본은 AuthApi.client 사용
  }) async {
    final String url = '${Env.apiBase}/s3/presigned-url';

    Response rsp;

    if (useAuthClient) {
      // AuthApi.client는 Dio 인스턴스라고 가정 (인터셉터로 토큰 주입)
      rsp = await AuthApi.client.post(
        url,
        data: {
          'fileName': fileName,
          'mimeType': mimeType,
          'fileSize': fileSize,
        },
        options: Options(validateStatus: (_) => true),
      );
    } else {
      // 직접 토큰을 넣어 호출
      rsp = await _dio.post(
        url,
        data: {
          'fileName': fileName,
          'mimeType': mimeType,
          'fileSize': fileSize,
        },
        options: Options(
          headers: accessToken == null ? null : {'Authorization': 'Bearer $accessToken'},
          validateStatus: (_) => true,
          contentType: Headers.jsonContentType,
        ),
      );
    }

    if (rsp.statusCode != 200) {
      final bodyPreview = (() {
        try {
          return rsp.data is String ? rsp.data : jsonEncode(rsp.data);
        } catch (_) {
          return '<unreadable>';
        }
      })();
      throw HttpException('Presign failed: ${rsp.statusCode} ${rsp.statusMessage} body=$bodyPreview');
    }

    // 서버 응답이 { data: {...} } 형태라고 가정
    final raw = rsp.data is String ? jsonDecode(rsp.data as String) : rsp.data;
    final data = raw is Map && raw['data'] is Map
        ? (raw['data'] as Map).map((k, v) => MapEntry(k.toString(), v))
        : (raw as Map).map((k, v) => MapEntry(k.toString(), v)); // 혹시 바로 바디가 오면 fallback

    return S3UploadInfo.fromJson(data as Map<String, dynamic>);
  }

  /// S3로 PUT 업로드 (프리사인 URL 사용)
  ///
  /// - requiredHeaders가 있으면 그 값을 우선 사용.
  /// - Content-Type은 presign 요청 시 사용한 것과 100% 일치해야 함.
  /// - 스트림 업로드로 메모리 절약 + 리다이렉트 대응.
  static Future<void> uploadFile(
      File file,
      S3UploadInfo info, {
        required String mimeType,
      }) async {
    final len = await file.length();
    final stream = file.openRead();

    // 기본 헤더
    final headers = <String, dynamic>{
      'Content-Length': len,
      'Content-Type': mimeType,
    };

    // 서버가 요구하는 추가 헤더 병합 (서명이 이 헤더들에 묶여 있을 수 있음)
    info.requiredHeaders.forEach((k, v) {
      if (v.isNotEmpty) headers[k] = v.first;
    });

    // 만약 requiredHeaders에 Content-Type이 지정돼 있다면 그것을 우선
    final rhCT = info.requiredHeaders['Content-Type'] ?? info.requiredHeaders['content-type'];
    if (rhCT != null && rhCT.isNotEmpty) {
      headers['Content-Type'] = rhCT.first;
    }

    try {
      final rsp = await _dio.put(
        info.uploadUrl,
        data: stream, // 스트림 업로드
        options: Options(
          headers: headers,
          responseType: ResponseType.plain,
          validateStatus: (code) => code != null && code >= 200 && code < 400, // 3xx까지 허용(일부 edge에서 중간 3xx 가능)
        ),
        onSendProgress: (sent, total) {
          // 필요시 업로드 프로그레스 활용
          // debugPrint('S3 upload $sent / $total');
        },
      );

      // 3xx 따라간 뒤 최종 2xx여야 정상
      if (rsp.statusCode! < 200 || rsp.statusCode! >= 300) {
        throw HttpException('S3 upload failed: ${rsp.statusCode} ${rsp.statusMessage}');
      }
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final msg = e.response?.data;
      throw HttpException('S3 upload failed: $code ${e.message} body=$msg');
    }
  }
}

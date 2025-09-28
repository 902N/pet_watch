import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../models/anomaly_alert.dart';
import '../../../../auth/auth_api.dart'; // TokenStore.access() 경로, monthly_report_api.dart 와 동일하게

class AnomalyAlertsApi {
  final String baseUrl;

  AnomalyAlertsApi({required this.baseUrl});

  /// GET /api/v1/notifications/anomaly-alerts?page={page}&size={size}
  /// 전체 페이지를 돌며 모두 수집해서 반환
  Future<List<AnomalyAlert>> fetchAll({int pageSize = 200}) async {
    final token = await TokenStore.access();
    if (token == null || token.isEmpty) {
      throw Exception('AccessToken이 없습니다. 로그인 후 다시 시도해주세요.');
    }

    final results = <AnomalyAlert>[];
    var page = 0;

    while (true) {
      final uri = Uri.parse(
        '$baseUrl/api/v1/notifications/anomaly-alerts?page=$page&size=$pageSize',
      );

      http.Response res;
      try {
        res = await http
            .get(
          uri,
          headers: {
            HttpHeaders.acceptHeader: 'application/json',
            HttpHeaders.authorizationHeader: 'Bearer $token',
          },
        )
            .timeout(const Duration(seconds: 10));
      } on SocketException {
        throw Exception('서버에 연결할 수 없습니다. 네트워크를 확인해주세요.');
      } on HttpException {
        throw Exception('HTTP 요청에 실패했습니다.');
      } on FormatException {
        throw Exception('응답 형식이 잘못되었습니다(JSON 파싱 오류).');
      } on TimeoutException {
        throw Exception('요청 시간이 초과되었습니다.');
      }

      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }

      final decoded = json.decode(res.body);
      final data = (decoded is Map<String, dynamic>)
          ? (decoded['data'] is Map<String, dynamic> ? decoded['data'] : decoded)
          : {};

      final alertsJson = (data['alerts'] as List<dynamic>? ?? []);
      results.addAll(alertsJson
          .map((e) => AnomalyAlert.fromJson(e as Map<String, dynamic>))
          .toList());

      final hasNext = data['hasNext'] == true;
      if (!hasNext) break;
      page += 1;
    }

    return results;
  }
}

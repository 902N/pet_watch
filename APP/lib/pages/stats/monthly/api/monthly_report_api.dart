import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/monthly_report.dart';
import '../../../../auth/auth_api.dart';

class MonthlyReportApi {
  final String baseUrl;

  MonthlyReportApi({required this.baseUrl});

  /// GET /api/v1/pets/{petId}/reports/monthly?yearMonth=YYYY-MM
  Future<MonthlyReport> fetchMonthly({
    required int petId,
    required DateTime monthAnchor,
  }) async {
    final ym = "${monthAnchor.year}-${monthAnchor.month.toString().padLeft(2, '0')}";
    final uri = Uri.parse('$baseUrl/api/v1/pets/$petId/reports/monthly?yearMonth=$ym');

    final token = await TokenStore.access();
    print('token: $token');
    if (token == null || token.isEmpty) {
      throw Exception('AccessToken이 없습니다. 로그인 후 다시 시도해주세요.');
    }

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
    // 서버 응답이 {"data": {...}} 형식일 수도 있고, 바로 {...} 일 수도 있음
    final payload = decoded is Map<String, dynamic>
        ? (decoded['data'] is Map<String, dynamic> ? decoded['data'] : decoded)
        : {};
    return MonthlyReport.fromJson(payload as Map<String, dynamic>);
  }
}

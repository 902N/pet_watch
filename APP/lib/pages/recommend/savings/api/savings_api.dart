import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/savings_model.dart';
import '../../../../auth/auth_api.dart';

class SavingsService {
  SavingsService._();
  static final instance = SavingsService._();

  String get _base => dotenv.env['BASE_URL'] ?? '';


  Future<List<SavingsProduct>> fetchSavings() async {
    final uri = Uri.parse('$_base/finance/saving');
    final token = await TokenStore.access();

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
    final list = (decoded['data'] as List? ?? [])
        .map((e) => SavingsProduct.fromJson(e as Map<String, dynamic>))
        .toList();

    print('받은 적금 상품 데이터: $list');
    print('엑세스토큰: $token');
    return list;
  }
}

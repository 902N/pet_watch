// savings/api/savings_detail_api.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../../../auth/auth_api.dart'; // TokenStore 접근
import '../models/savings_detail_model.dart';

class SavingsDetailApi {
  SavingsDetailApi._();
  static final instance = SavingsDetailApi._();

  String get _base => dotenv.env['BASE_URL'] ?? '';

  Future<SavingsDetail> fetchDetail(String productUuid) async {
    final token = await TokenStore.access();
    if (token == null || token.isEmpty) {
      throw Exception('AccessToken이 없습니다. 로그인 후 다시 시도해주세요.');
    }

    final uri = Uri.parse('$_base/finance/saving/$productUuid');

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
          .timeout(const Duration(seconds: 15));
    } on SocketException {
      throw Exception('네트워크에 연결할 수 없습니다.');
    } on TimeoutException {
      throw Exception('요청이 시간 초과되었습니다.');
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('상세 조회 실패 (${res.statusCode}): ${res.body}');
    }

    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return SavingsDetail.fromJson(body);
  }
}

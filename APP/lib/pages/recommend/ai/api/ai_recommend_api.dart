import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/ai_recommend.dart';
import '../../../../auth/auth_api.dart';

class AiRecommendApi {
  final Dio _dio;

  AiRecommendApi() : _dio = AuthApi.client;

  Future<AiRecommendation> fetch() async {
    final baseUrl = dotenv.env['BASE_URL'] ?? '';
    if (baseUrl.isEmpty) {
      throw Exception('BASE_URL is not set in .env');
    }

    final res = await _dio.post('$baseUrl/finance/ai_recommend');

    if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
      return AiRecommendation.fromJson(res.data as Map<String, dynamic>);
    }
    throw Exception('AI 추천 API 실패: ${res.statusCode}');
  }
}

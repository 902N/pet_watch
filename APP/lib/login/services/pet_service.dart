import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PetService {
  static Future<String?> token() async {
    final sp = await SharedPreferences.getInstance();
    final candidates = ['accessToken', 'accesstoken', 'ACCESS_TOKEN', 'at'];
    for (final k in candidates) {
      final v = sp.getString(k);
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  static String baseUrl() {
    final raw = dotenv.env['BASE_URL'] ??
        dotenv.env['API_BASE'] ??
        dotenv.env['API_BASE_URL'] ??
        dotenv.env['BACKEND_URL'] ??
        '';
    if (raw.isEmpty) return raw;
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  static String _apiV1(String b) => b.endsWith('/api/v1') ? b : '$b/api/v1';
  static String? _defaultProfile() =>
      dotenv.env['DEFAULT_PROFILE_IMAGE_URL'] ?? dotenv.env['DEFAULT_PET_IMAGE_URL'];
  static double _d(num? n) => n == null ? 0.0 : n.toDouble();

  static Future<String?> uploadImage(
      File file, {
        required String baseUrl,
        required String accessToken,
      }) async {
    final url = baseUrl.endsWith('/api/v1')
        ? '$baseUrl/pets/images'
        : '$baseUrl/api/v1/pets/images';

    final uri = Uri.parse(url);
    final req = http.MultipartRequest('POST', uri);
    req.headers['Authorization'] = 'Bearer $accessToken';
    req.headers['Accept'] = 'application/json';
    req.files.add(await http.MultipartFile.fromPath('file', file.path));

    final resp = await req.send();
    final text = await resp.stream.bytesToString();
    if (resp.statusCode < 200 || resp.statusCode >= 300) return null;

    try {
      final json = jsonDecode(text);
      final data = (json is Map && json['data'] != null) ? json['data'] : json;
      if (data is String && data.isNotEmpty) return data;
      if (data is Map) {
        final cands = [
          data['url'],
          data['profileImage'],
          data['profileImageUrl'],
          data['profile_image_url'],
        ];
        for (final v in cands) {
          if (v is String && v.isNotEmpty) return v;
        }
      }
      return null;
    } catch (_) {
      return text.isNotEmpty ? text : null;
    }
  }

  static Future<Map<String, dynamic>?> createPet({
    required String accessToken,
    required String name,
    String? breed,
    required String birthdate,
    required String gender,
    required bool neutered,
    num? weight,
    String? profileImage,
    bool makeActive = true,
  }) async {
    final b = _apiV1(baseUrl());
    final effectiveProfile = (profileImage != null && profileImage.isNotEmpty)
        ? profileImage
        : (_defaultProfile() ?? '');
    if (effectiveProfile.isEmpty) throw Exception('profileImage required');

    final url = Uri.parse('$b/pets');
    final body = jsonEncode({
      'name': name,
      if (breed != null && breed.isNotEmpty) 'breed': breed,
      'birthdate': birthdate,
      'gender': gender,
      'neutered': neutered,
      'weight': _d(weight),
      'profileImageUrl': effectiveProfile,
      'profileImage': effectiveProfile,
      'profile_image_url': effectiveProfile,
      'makeActive': makeActive,
    });

    final resp = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: body,
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) return null;

    final json = jsonDecode(resp.body);
    return (json is Map && json['data'] is Map)
        ? Map<String, dynamic>.from(json['data'])
        : null;
  }
}

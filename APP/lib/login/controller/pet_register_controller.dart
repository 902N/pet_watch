// lib/login/controller/pet_register_controller.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:APP/auth/auth_api.dart' show TokenStore;
import 'package:APP/auth/env.dart';

typedef Notifier = void Function(String message, {bool err});

class PetRegisterController {
  final nameCtrl = TextEditingController();
  final breedCtrl = TextEditingController();
  final weightCtrl = TextEditingController();

  DateTime? birth;
  String? gender = 'M';
  bool neutered = false;
  bool submitting = false;

  /// imageUrl 우선 사용 (S3 업로드 완료된 URL). imageFile은 하위호환용으로만 남김.
  Future<bool> submit({
    File? imageFile, // 사용하지 않음(호환용)
    String? imageUrl,
    required Notifier show,
  }) async {
    try {
      // 인증/베이스 확보
      final token = await TokenStore.access();
      if (token == null || token.isEmpty) {
        show('로그인이 필요합니다.', err: true);
        return false;
      }
      final apiBase = Env.apiBase.replaceAll(RegExp(r'/*$'), ''); // 슬래시 정리
      final uri = Uri.parse('$apiBase/pets');

      // 필수 입력 검증
      if (nameCtrl.text.trim().isEmpty) {
        show('이름을 입력하세요.', err: true);
        return false;
      }

      // 날짜 문자열
      final birthStr = birth == null
          ? null
          : '${birth!.year.toString().padLeft(4, '0')}-'
          '${birth!.month.toString().padLeft(2, '0')}-'
          '${birth!.day.toString().padLeft(2, '0')}';

      // 체중 숫자 파싱(서버가 숫자 기대 시 안전하게 처리)
      final weightText = weightCtrl.text.trim();
      final weightValue = double.tryParse(weightText);

      final body = <String, dynamic>{
        'name'        : nameCtrl.text.trim(),
        'breed'       : breedCtrl.text.trim(),
        // 서버 스펙에 맞춰 숫자/문자 모두 대응: 숫자면 number, 아니면 원문
        'weight'      : weightValue ?? weightText,
        'birthdate'   : birthStr,
        'gender'      : (gender == 'F' || gender == 'M') ? gender : 'M',
        'neutered'    : neutered,
        'profileImage': imageUrl ?? '', // S3 URL(or 빈 문자열)
      };

      final headers = <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type' : 'application/json',
        'Accept'       : 'application/json',
      };

      final resp = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        var msg = '등록 실패(${resp.statusCode})';
        try {
          final m = jsonDecode(resp.body) as Map<String, dynamic>;
          final s = (m['message'] ?? m['error'] ?? m['errorMessage'])?.toString();
          if (s != null && s.isNotEmpty) msg = '$msg - $s';
        } catch (_) {}
        show(msg, err: true);
        return false;
      }

      final map = jsonDecode(resp.body) as Map<String, dynamic>;
      if (map['success'] != true) {
        show(map['message']?.toString() ?? '등록 실패', err: true);
        return false;
      }
      return true;
    } catch (e) {
      show('예외 발생: $e', err: true);
      return false;
    }
  }

  void dispose() {
    nameCtrl.dispose();
    breedCtrl.dispose();
    weightCtrl.dispose();
  }
}

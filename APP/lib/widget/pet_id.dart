import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:APP/auth/auth_api.dart' show AuthApi;

class PetSummary {
  final int id;
  final String name;
  final String profileImage;
  PetSummary({required this.id, required this.name, required this.profileImage});

  factory PetSummary.fromJson(Map<String, dynamic> j) => PetSummary(
    id: (j['id'] ?? j['petId']) as int,
    name: (j['name'] ?? j['petName'] ?? '') as String,
    profileImage: (j['profileImage'] ??
        j['profileImageUrl'] ??
        j['profile_image_url'] ??
        '') as String,
  );
}

class PetIdStore extends ChangeNotifier {
  static const _kActivePetKey = 'last_active_pet_id';

  int? _activePetId;
  List<PetSummary> _pets = [];
  bool _loading = false;

  int? get activePetId => _activePetId;
  List<PetSummary> get pets => _pets;
  bool get loading => _loading;

  int? get petId => _activePetId;
  String? get petName => _currentPet()?.name;
  String? get petImage => _currentPet()?.profileImage;

  PetSummary? _currentPet() {
    final id = _activePetId;
    if (id == null) return null;
    try {
      return _pets.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  String _apiV1(String base) => base.endsWith('/api/v1') ? base : '$base/api/v1';

  void _upsertPet(PetSummary p) {
    final i = _pets.indexWhere((e) => e.id == p.id);
    if (i >= 0) {
      _pets[i] = p;
    } else {
      _pets = [..._pets, p];
    }
  }

  Future<void> initFromUserMeAndPets({required String baseUrl}) async {
    _loading = true;
    notifyListeners();

    final api = _apiV1(baseUrl);
    int? serverActiveId;

    // 1) 서버의 activePetId
    try {
      final me = await AuthApi.client.get(
        '$api/users/me',
        options: Options(
          validateStatus: (_) => true,
          contentType: null,
          headers: {'Accept': 'application/json'},
        ),
      );
      if ((me.statusCode ?? 0) >= 200 && (me.statusCode ?? 0) < 300) {
        final body = (me.data is Map<String, dynamic>)
            ? me.data as Map<String, dynamic>
            : <String, dynamic>{};
        final data = body['data'] as Map<String, dynamic>? ?? {};
        if (data['activePetId'] is int) serverActiveId = data['activePetId'] as int;
      }
    } catch (_) {}

    // 2) 펫 목록
    try {
      final petsRes = await AuthApi.client.get(
        '$api/pets',
        options: Options(
          validateStatus: (_) => true,
          contentType: null,
          headers: {'Accept': 'application/json'},
        ),
      );
      if ((petsRes.statusCode ?? 0) >= 200 && (petsRes.statusCode ?? 0) < 300) {
        final body = (petsRes.data is Map<String, dynamic>)
            ? petsRes.data as Map<String, dynamic>
            : <String, dynamic>{};
        final list = body['data'] as List<dynamic>? ?? [];
        _pets = list
            .map((e) => PetSummary.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } else {
        _pets = [];
      }
    } catch (_) {
      _pets = [];
    }

    // 3) activePetId가 목록에 없으면 상세로 보충 로딩
    if (serverActiveId != null && !_pets.any((p) => p.id == serverActiveId)) {
      try {
        final res = await AuthApi.client.get(
          '$api/pets/$serverActiveId',
          options: Options(
            validateStatus: (_) => true,
            contentType: null,
            headers: {'Accept': 'application/json'},
          ),
        );
        if ((res.statusCode ?? 0) >= 200 && (res.statusCode ?? 0) < 300) {
          final body = (res.data is Map<String, dynamic>)
              ? res.data as Map<String, dynamic>
              : <String, dynamic>{};
          final data = body['data'] as Map<String, dynamic>? ?? {};
          if (data.isNotEmpty) {
            _upsertPet(PetSummary.fromJson(data));
          }
        }
      } catch (_) {}
    }

    // 4) 활성 펫 결정 순서: 로컬 저장값 → 서버 active → 목록 첫 번째
    final localActiveId = await _loadLocalActivePetId();
    int? resolved;
    if (localActiveId != null && _pets.any((p) => p.id == localActiveId)) {
      resolved = localActiveId;
    } else if (serverActiveId != null && _pets.any((p) => p.id == serverActiveId)) {
      resolved = serverActiveId;
    } else if (_pets.isNotEmpty) {
      resolved = _pets.first.id;
    }

    _activePetId = resolved;
    _loading = false;
    notifyListeners();

    if (resolved != null) {
      await _saveLocalActivePetId(resolved);
      // 서버 동기화가 별도로 필요하면 아래 주석 해제
      // unawaited(_syncActiveToServer(baseUrl: baseUrl, petId: resolved));
    }
  }

  Future<void> refreshPets({required String baseUrl}) async {
    final api = _apiV1(baseUrl);
    try {
      final petsRes = await AuthApi.client.get(
        '$api/pets',
        options: Options(
          validateStatus: (_) => true,
          contentType: null,
          headers: {'Accept': 'application/json'},
        ),
      );
      if ((petsRes.statusCode ?? 0) >= 200 && (petsRes.statusCode ?? 0) < 300) {
        final body = (petsRes.data is Map<String, dynamic>)
            ? petsRes.data as Map<String, dynamic>
            : <String, dynamic>{};
        final list = body['data'] as List<dynamic>? ?? [];
        _pets = list
            .map((e) => PetSummary.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        if (_activePetId == null && _pets.isNotEmpty) {
          _activePetId = _pets.first.id;
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> switchActive({
    required String baseUrl,
    required int targetPetId,
  }) async {
    _activePetId = targetPetId;
    notifyListeners();
    await _saveLocalActivePetId(targetPetId);

    final api = _apiV1(baseUrl);
    try {
      await AuthApi.client.patch(
        '$api/pets/$targetPetId/active',
        data: const {},
        options: Options(
          validateStatus: (_) => true,
          contentType: 'application/json',
          headers: {'Accept': 'application/json'},
        ),
      );
      await refreshPets(baseUrl: baseUrl);
    } catch (_) {}
  }

  Future<void> setActivePetId(int id) async {
    _activePetId = id;
    notifyListeners();
    await _saveLocalActivePetId(id);
  }

  void reset() {
    _activePetId = null;
    _pets = [];
    _loading = false;
    notifyListeners();
  }

  Future<void> _saveLocalActivePetId(int id) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kActivePetKey, id);
  }

  Future<int?> _loadLocalActivePetId() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kActivePetKey);
  }

  Future<void> _syncActiveToServer({
    required String baseUrl,
    required int petId,
  }) async {
    final api = _apiV1(baseUrl);
    try {
      await AuthApi.client.patch(
        '$api/pets/$petId/active',
        data: const {},
        options: Options(
          validateStatus: (_) => true,
          contentType: 'application/json',
          headers: {'Accept': 'application/json'},
        ),
      );
    } catch (_) {}
  }
}

// ignore: deprecated_member_use
void unawaited(Future<void> f) {}

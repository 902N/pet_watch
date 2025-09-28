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
    id: j['id'] as int,
    name: j['name'] as String? ?? '',
    profileImage: j['profileImage'] as String? ?? '',
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

  String _u(String baseUrl, String path) {
    if (baseUrl.endsWith('/')) baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    return '$baseUrl$path';
  }

  Future<void> initFromUserMeAndPets({required String baseUrl}) async {
    _loading = true;
    notifyListeners();

    int? serverActiveId;

    try {
      final me = await AuthApi.client.get(
        _u(baseUrl, '/users/me'),
        options: Options(validateStatus: (_) => true),
      );
      if (me.statusCode != null && me.statusCode! >= 200 && me.statusCode! < 300) {
        final body = (me.data is Map<String, dynamic>) ? me.data as Map<String, dynamic> : <String, dynamic>{};
        final data = body['data'] as Map<String, dynamic>? ?? {};
        final ap = data['activePetId'];
        if (ap is int) serverActiveId = ap;
      }
    } catch (_) {}

    try {
      final petsRes = await AuthApi.client.get(
        _u(baseUrl, '/pets'),
        options: Options(validateStatus: (_) => true),
      );
      if (petsRes.statusCode != null && petsRes.statusCode! >= 200 && petsRes.statusCode! < 300) {
        final body = (petsRes.data is Map<String, dynamic>) ? petsRes.data as Map<String, dynamic> : <String, dynamic>{};
        final list = body['data'] as List<dynamic>? ?? [];
        _pets = list.map((e) => PetSummary.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      }
    } catch (_) {}

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
      if (serverActiveId == null || serverActiveId != resolved) {
        unawaited(_syncActiveToServer(baseUrl: baseUrl, petId: resolved));
      }
    }
  }

  Future<void> refreshPets({required String baseUrl}) async {
    try {
      final petsRes = await AuthApi.client.get(
        _u(baseUrl, '/pets'),
        options: Options(validateStatus: (_) => true),
      );
      if (petsRes.statusCode != null && petsRes.statusCode! >= 200 && petsRes.statusCode! < 300) {
        final body = (petsRes.data is Map<String, dynamic>) ? petsRes.data as Map<String, dynamic> : <String, dynamic>{};
        final list = body['data'] as List<dynamic>? ?? [];
        _pets = list.map((e) => PetSummary.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        if (_activePetId == null && _pets.isNotEmpty) _activePetId = _pets.first.id;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> switchActive({required String baseUrl, required int targetPetId}) async {
    _activePetId = targetPetId;
    notifyListeners();
    await _saveLocalActivePetId(targetPetId);

    try {
      final resp = await AuthApi.client.put(
        _u(baseUrl, '/users/me/active-pet'),
        data: {'petId': targetPetId},
        options: Options(validateStatus: (_) => true),
      );
      if (!(resp.statusCode != null && resp.statusCode! >= 200 && resp.statusCode! < 300)) {
        await AuthApi.client.put(
          _u(baseUrl, '/users/me/active-pet'),
          data: {'activePetId': targetPetId},
          options: Options(validateStatus: (_) => true),
        );
      }
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

  Future<void> _syncActiveToServer({required String baseUrl, required int petId}) async {
    try {
      final r = await AuthApi.client.put(
        _u(baseUrl, '/users/me/active-pet'),
        data: {'petId': petId},
        options: Options(validateStatus: (_) => true),
      );
      if (!(r.statusCode != null && r.statusCode! >= 200 && r.statusCode! < 300)) {
        await AuthApi.client.put(
          _u(baseUrl, '/users/me/active-pet'),
          data: {'activePetId': petId},
          options: Options(validateStatus: (_) => true),
        );
      }
    } catch (_) {}
  }
}

void unawaited(Future<void> f) {}

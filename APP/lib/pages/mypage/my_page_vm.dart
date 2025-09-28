// lib/pages/mypage/my_page_vm.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/painting.dart';

import 'package:APP/auth/auth_api.dart' show AuthApi, TokenStore;
import 'package:APP/auth/auth_service.dart';
import 'package:APP/auth/env.dart';
import 'package:APP/login/login.dart';
import 'package:APP/pages/main_screen/main_screen.dart';
import 'package:APP/pages/mypage/models/pet_profile.dart';
import 'package:APP/pages/mypage/widgets/user_info_dialog.dart' as user_info_dialog;
import 'package:APP/pages/mypage/pet_edit_screen.dart';
import 'package:APP/widget/pet_id.dart';
import 'package:APP/fcm/fcm_bridge.dart';
import 'package:APP/notifications/fcm_api.dart';
import 'package:APP/guide/guideline_page.dart';

class MyPageVM extends ChangeNotifier {
  final PetIdStore store;

  bool agreeNotification = true;
  bool loadingMe = false;
  bool loadingPet = false;

  PetProfile profile = PetProfile(
    id: null,
    name: '-',
    breed: '-',
    age: null,
    birthdate: null,
    gender: null,
    neutered: null,
    profileImage: null,
  );

  int? _lastWatchedPetId;
  int? _fetchedPetId;
  bool _fetching = false;
  int? _pendingPetId;
  VoidCallback? _storeListener;

  MyPageVM(this.store);

  void start() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _lastWatchedPetId = store.activePetId;

      _storeListener = () {
        final nextId = store.activePetId;
        if (nextId != _lastWatchedPetId) {
          _lastWatchedPetId = nextId;
          fetchPetIfNeeded(nextId);
        }
        if (nextId != null && nextId == profile.id) {
          final nextName = store.petName;
          if (nextName != null && nextName != profile.name) {
            profile = profile.copyWith(name: nextName);
            notifyListeners();
          }
        }
      };
      store.addListener(_storeListener!);

      fetchUserInfo(null);
      fetchPetIfNeeded(store.activePetId, force: true);
    });
  }

  @override
  void dispose() {
    if (_storeListener != null) {
      store.removeListener(_storeListener!);
    }
    super.dispose();
  }

  Future<void> fetchUserInfo(BuildContext? context, {bool show = false}) async {
    loadingMe = true;
    notifyListeners();
    try {
      final rsp = await AuthApi.client.get(
        '/users/me',
        options: Options(validateStatus: (_) => true),
      );

      if (rsp.statusCode == 200) {
        final map = (rsp.data is Map<String, dynamic>) ? rsp.data as Map<String, dynamic> : <String, dynamic>{};
        final d = map['data'] as Map<String, dynamic>? ?? {};

        final name = d['profileName'] ?? '-';
        final email = d['email'] ?? '-';

        final serverAgree = d['agreeNotification'] as bool?;
        if (serverAgree != null) {
          agreeNotification = serverAgree;
          notifyListeners();
        }

        if (agreeNotification == true) {
          await FcmBridge.initAndSyncOnce();
        }

        if (show && (context?.mounted ?? false)) {
          await user_info_dialog.UserInfoDialog.show(
            context!,
            name: name,
            email: email,
            onLogout: () => logout(context),
            onWithdraw: () => deleteAccount(context),
          );
        }
      }
    } finally {
      loadingMe = false;
      notifyListeners();
    }
  }

  Future<void> fetchPetIfNeeded(int? petId, {bool force = false}) async {
    if (petId == null) return;
    if (!force && _fetchedPetId == petId) return;
    if (_fetching) {
      _pendingPetId = petId;
      return;
    }

    double? _asDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v.trim());
      return null;
    }

    _fetching = true;
    loadingPet = true;
    notifyListeners();

    try {
      final rsp = await AuthApi.client.get(
        '/pets/$petId',
        options: Options(validateStatus: (_) => true),
      );

      if (rsp.statusCode == 200) {
        final m = (rsp.data is Map<String, dynamic>) ? rsp.data as Map<String, dynamic> : <String, dynamic>{};
        final d = m['data'] as Map<String, dynamic>?;

        if (d != null) {
          profile = PetProfile(
            id: d['id'] as int?,
            name: d['name'] as String? ?? '-',
            breed: d['breed'] as String? ?? '-',
            age: d['age'] is int ? d['age'] as int? : int.tryParse('${d['age']}'),
            birthdate: d['birthdate'] as String?,
            gender: (d['gender'] as String?)?.toUpperCase(),
            neutered: d['neutered'] as bool?,
            profileImage: d['profileImage'] as String?,
            weight: _asDouble(d['weight'] ?? d['weightKg'] ?? d['weight_kg'] ?? d['bodyWeight'] ?? d['petWeight']),
          );
          _fetchedPetId = profile.id;
          notifyListeners();
        }
      }
    } finally {
      _fetching = false;
      loadingPet = false;
      notifyListeners();

      if (_pendingPetId != null && _pendingPetId != _fetchedPetId) {
        final next = _pendingPetId;
        _pendingPetId = null;
        await fetchPetIfNeeded(next, force: true);
      } else {
        _pendingPetId = null;
      }
    }
  }

  Future<void> toggleNotification(bool next) async {
    final prev = agreeNotification;
    agreeNotification = next;
    notifyListeners();

    try {
      if (next) {
        await FcmBridge.forceSync();
        final r = await AuthApi.client.patch(
          '/users/me/notification',
          data: {'agreeNotification': true},
          options: Options(validateStatus: (_) => true),
        );
        if (r.statusCode != 200) throw Exception('patch failed');
      } else {
        await FcmApi.disableThisDevice();
        final r = await AuthApi.client.patch(
          '/users/me/notification',
          data: {'agreeNotification': false},
          options: Options(validateStatus: (_) => true),
        );
        if (r.statusCode != 200) throw Exception('patch failed');
      }

      final me = await AuthApi.client.get(
        '/users/me',
        options: Options(validateStatus: (_) => true),
      );
      if (me.statusCode == 200) {
        final d = (me.data is Map<String, dynamic> ? me.data as Map<String, dynamic> : const {})['data']
        as Map<String, dynamic>?;
        final serverAgree = d?['agreeNotification'] as bool?;
        if (serverAgree != null) {
          agreeNotification = serverAgree;
          notifyListeners();
        }
      }
    } catch (_) {
      agreeNotification = prev;
      notifyListeners();
    }
  }

  Future<void> logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('로그아웃', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('예', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('아니오'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await FcmApi.disableThisDevice();
      await FcmBridge.onLogout();
    } catch (_) {}

    final rt = await TokenStore.refresh();
    if (rt == null) return;

    final rsp = await AuthApi.client.post(
      '/users/logout',
      data: {'refreshToken': rt, 'allDevices': false},
      options: Options(validateStatus: (_) => true),
    );

    if (rsp.statusCode == 200) {
      await AuthService.signOut();
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  Future<void> deleteAccount(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('회원탈퇴', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('정말로 탈퇴하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('탈퇴', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('아니오'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await FcmApi.disableAll();
      await FcmBridge.onLogout();
    } catch (_) {}

    final rsp = await AuthApi.client.delete(
      '/users/me',
      options: Options(validateStatus: (_) => true),
    );
    if (rsp.statusCode == 200) {
      await AuthService.unlink();
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  Future<void> openEdit(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PetEditScreen(petId: store.petId)),
    );
    await _handleAfterPetEdit(result, context);
  }

  Future<void> tapFetchUser(BuildContext context) async {
    await fetchUserInfo(context, show: true);
  }

  void openFaq(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GuidelinePage()));
  }

  Future<void> _handleAfterPetEdit(dynamic result, BuildContext context) async {
    if (result == null) return;

    final deleted = result == 'deleted' ||
        (result is bool && result == false) ||
        (result is Map && (result['deleted'] == true || result['result'] == 'deleted'));

    if (deleted) {
      profile = PetProfile(
        id: null,
        name: '-',
        breed: '-',
        age: null,
        birthdate: null,
        gender: null,
        neutered: null,
        profileImage: null,
      );
      _fetchedPetId = null;
      _lastWatchedPetId = null;

      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      await store.initFromUserMeAndPets(baseUrl: Env.baseUrl);

      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
            (route) => false,
      );
      return;
    }

    if (result == true) {
      await fetchPetIfNeeded(store.activePetId, force: true);
      await fetchUserInfo(context);
    }
  }
}

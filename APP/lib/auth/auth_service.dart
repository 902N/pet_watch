import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' hide AuthApi;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'env.dart';
import 'auth_api.dart';
import 'package:APP/widget/pet_id.dart';
import 'package:APP/fcm/fcm_service.dart';
import 'package:APP/notifications/fcm_api.dart';

class AuthService {
  static Future<bool> signIn(BuildContext context) async {
    if (dotenv.env.isEmpty) await dotenv.load(fileName: ".env");
    try {
      final installed = await isKakaoTalkInstalled();
      final token = installed
          ? await UserApi.instance.loginWithKakaoTalk()
          : await UserApi.instance.loginWithKakaoAccount();
      final rsp = await AuthApi.loginWithKakaoRaw(token.accessToken);
      if (rsp.statusCode == 200) {
        final (a, r) = extractTokens(rsp.data);
        if (a != null && r != null) {
          await TokenStore.save(a, r);
          await _persistTokens(a, r);
          final baseUrl = dotenv.env['BASE_URL'] ?? Env.baseUrl;
          await context.read<PetIdStore>().initFromUserMeAndPets(baseUrl: baseUrl);
          final ft = await FCMService.getToken();
          if (ft != null) { await FcmApi.syncToken(ft); }
          return true;
        }
      }
      _showError(context, extractError(rsp.data));
      return false;
    } catch (_) {
      _showToast(context, '로그인 중 오류가 발생했습니다.');
      return false;
    }
  }

  static Future<void> signOut([BuildContext? context]) async {
    try { await FcmApi.disableThisDevice(); } catch (_) {}
    try { await FCMService.deleteToken(); } catch (_) {}
    await TokenStore.clear();
    await _clearPersistedTokens();
    try { await UserApi.instance.logout(); } catch (_) {}
  }

  static Future<void> unlink([BuildContext? context]) async {
    try { await FcmApi.disableThisDevice(); } catch (_) {}
    try { await FCMService.deleteToken(); } catch (_) {}
    await TokenStore.clear();
    await _clearPersistedTokens();
    try { await UserApi.instance.unlink(); } catch (_) {}
  }

  static Future<bool> reissueIfNeeded([BuildContext? context]) async {
    final r = await TokenStore.refresh();
    if (r == null || r.isEmpty) return false;
    final rsp = await AuthApi.reissueRaw(r);
    if (rsp.statusCode == 200) {
      final (a, n) = extractTokens(rsp.data);
      if (a != null && n != null) {
        await TokenStore.save(a, n);
        await _persistTokens(a, n);
        if (context != null) {
          final baseUrl = dotenv.env['BASE_URL'] ?? Env.baseUrl;
          await context.read<PetIdStore>().refreshPets(baseUrl: baseUrl);
        }
        return true;
      }
    }
    return false;
  }

  static Future<void> _persistTokens(String access, String refresh) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('access_token', access);
    await sp.setString('refresh_token', refresh);
  }

  static Future<void> _clearPersistedTokens() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('access_token');
    await sp.remove('refresh_token');
  }

  static void _showError(BuildContext context, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('로그인 실패'),
        content: Text(msg),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('확인'))],
      ),
    );
  }

  static void _showToast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

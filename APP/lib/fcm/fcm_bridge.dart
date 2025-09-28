// lib/fcm/fcm_bridge.dart
import 'package:APP/fcm/fcm_service.dart';
import 'package:APP/notifications/fcm_api.dart'; // ← 여기!

class FcmBridge {
  static bool _done = false;

  static Future<void> initAndSyncOnce() async {
    if (_done) return;
    await FCMService.init(onTokenSync: FcmApi.syncToken);
    final t = await FCMService.getToken();
    if (t != null) {
      await FcmApi.syncToken(t);
    }
    _done = true;
  }

  static Future<void> forceSync() async {
    await FCMService.init(onTokenSync: FcmApi.syncToken);
    final t = await FCMService.getToken();
    if (t != null) {
      await FcmApi.syncToken(t);
    }
    _done = true;
  }

  static Future<void> onLogout() async {
    await FcmApi.disableThisDevice();
    await FCMService.deleteToken();
    _done = false;
  }
}

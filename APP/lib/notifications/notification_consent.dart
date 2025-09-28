// lib/notifications/notification_consent.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dio/dio.dart';

import 'package:APP/fcm/fcm_bridge.dart';
import 'package:APP/notifications/fcm_api.dart';
import 'package:APP/auth/auth_api.dart';

class NotificationConsent {
  static const _kAskedKey = 'notif_consent_asked_v1';

  /// 앱 시작 시 한 번만 물어보고 서버에 동기화
  static Future<void> ensureAsked(BuildContext context) async {
    final sp = await SharedPreferences.getInstance();
    if (sp.getBool(_kAskedKey) == true) return;

    final agree = await _askDialog(context);
    if (agree == true) {
      // OS 권한 요청 (iOS/Android13+)
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true, badge: true, sound: true,
        provisional: false,
      );

      final granted = settings.authorizationStatus == AuthorizationStatus.authorized
          || (Platform.isAndroid && settings.authorizationStatus != AuthorizationStatus.denied);

      if (granted) {
        await FcmBridge.forceSync(); // 토큰 서버 등록
        await _saveAgree(true);
      } else {
        // OS 권한 거절 시 앱 동의도 false로 동기화
        await _saveAgree(false);
        await FcmApi.disableThisDevice();
      }
    } else {
      // 앱 동의 거절
      await _saveAgree(false);
      await FcmApi.disableThisDevice();
    }

    await sp.setBool(_kAskedKey, true);
  }

  static Future<void> _saveAgree(bool agree) async {
    await AuthApi.client.patch(
      '/users/me/notification',
      data: {'agreeNotification': agree},
      options: Options(validateStatus: (_) => true),
    );
  }

  static Future<bool?> _askDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('알림을 받아보시겠어요?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('산책 리마인더, 기록 알림 등을 보내드려요. 알림 권한은 설정에서 언제든 변경할 수 있습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('아니오'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('허용'),
          ),
        ],
      ),
    );
  }

  /// 개발/테스트용: 다시 물어보게 리셋
  static Future<void> resetAskedFlag() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kAskedKey);
  }
}

// lib/fcm/fcm_service.dart
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

typedef TokenSync = Future<void> Function(String token);

/// 백그라운드/종료 상태에서 data-only 메시지를 수신했을 때 호출됨.
/// (notification 메시지는 시스템이 알아서 표시하므로 여기서 수동 표시가 필요 없음)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await _FCMBgHelper.ensureInit(); // 로컬 알림/채널 초기화(한 번만)
  // notification payload가 없고 data만 있을 때 로컬 알림 표시
  final hasNotification = message.notification != null;
  if (!hasNotification) {
    final title = message.data['title']?.toString();
    final body  = message.data['body']?.toString();
    if (title != null || body != null) {
      final soundKey = _FCMChannels.pickSoundKey(
        dataSound: message.data['sound']?.toString(),
        notifSound: null,
      );
      final details = _FCMChannels.detailsFor(soundKey);
      await _FCMBgHelper.fln.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
      );
    }
  }
}

class FCMService {
  static final _messaging = FirebaseMessaging.instance;
  static final _fln = FlutterLocalNotificationsPlugin();

  static bool _inited = false;
  static TokenSync? _sync;

  /// 앱 시작 시 한 번만 호출
  static Future<void> init({TokenSync? onTokenSync}) async {
    if (_inited) return;
    await Firebase.initializeApp();

    _sync = onTokenSync;

    // 백그라운드 핸들러 등록
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 로컬 알림/채널 초기화
    await _initLocalNoti();

    // 권한(안드 13+ 알림 권한)
    await _requestPermission();

    // 포그라운드 수신 핸들러
    await _setForegroundHandlers();

    // 토큰 동기화
    await _bootstrapToken();

    _inited = true;
  }

  static Future<String?> getToken() async {
    final t = await _messaging.getToken();
    if (t != null) {
      // 개발 로그
      // ignore: avoid_print
      print('📨 FCM TOKEN: $t');
    }
    return t;
  }

  static Future<void> subscribe(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  static Future<void> unsubscribe(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  static Future<void> deleteToken() async {
    await _messaging.deleteToken();
  }

  // ------------------ 내부 구현 ------------------

  static Future<void> _initLocalNoti() async {
    const initAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const init = InitializationSettings(android: initAndroid);
    await _fln.initialize(init);

    // 알림 채널 3개 생성: default / bark / crying
    await _FCMChannels.createAll(
      _fln.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>(),
    );
  }

  static Future<void> _requestPermission() async {
    if (Platform.isAndroid) {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
    }
  }

  static Future<void> _setForegroundHandlers() async {
    // 앱이 켜져 있을 때 온 푸시를 직접 표시
    FirebaseMessaging.onMessage.listen((m) async {
      final n = m.notification;

      // 표출할 제목/본문
      final title = n?.title ?? m.data['title'];
      final body  = n?.body  ?? m.data['body'];

      // 어떤 소리를 쓸지 결정: notification.android.sound > data.sound > default
      final notifSound = n?.android?.sound;              // 서버 notification.sound
      final dataSound  = m.data['sound']?.toString();    // 서버 data.sound
      final soundKey   = _FCMChannels.pickSoundKey(
        dataSound: dataSound,
        notifSound: notifSound,
      );

      final details = _FCMChannels.detailsFor(soundKey);

      await _fln.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
      );
    });

    // iOS 스타일과 유사: 안드로이드에서도 포그라운드 시 알림 보이도록
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true, badge: true, sound: true,
    );
  }

  static Future<void> _bootstrapToken() async {
    final t = await _messaging.getToken();
    if (t != null) {
      // ignore: avoid_print
      print('📨 FCM TOKEN init: $t');
      if (_sync != null) {
        await _sync!(t);
      }
    }
    _messaging.onTokenRefresh.listen((newToken) async {
      // ignore: avoid_print
      print('🔄 FCM TOKEN refreshed: $newToken');
      if (_sync != null) {
        await _sync!(newToken);
      }
    });
  }
}

/// 채널/사운드 관련 유틸
class _FCMChannels {
  // 채널 ID 고정 (Manifest meta-data의 default_notification_channel_id와도 맞춰주는 걸 권장)
  static const defaultId = 'default_channel';
  static const barkId    = 'bark_channel';
  static const cryingId  = 'crying_channel';

  // 채널 명
  static const defaultName = 'Default';
  static const barkName    = 'Bark';
  static const cryingName  = 'Crying';

  // 채널 생성
  static Future<void> createAll(
      AndroidFlutterLocalNotificationsPlugin? androidFln,
      ) async {
    if (androidFln == null) return;

    // 중요: 안드 8.0+ 에서는 "채널 생성 시"에 소리가 묶입니다.
    // 한 번 생성된 채널의 소리는 바꿀 수 없으니, 사운드별로 채널을 각각 만듭니다.

    // 기본 채널(시스템 기본 사운드)
    const chDefault = AndroidNotificationChannel(
      defaultId,
      defaultName,
      description: 'Default notifications',
      importance: Importance.high,
      playSound: true,
    );

    // bark 채널 (raw/bark.mp3)
    const chBark = AndroidNotificationChannel(
      barkId,
      barkName,
      description: 'Bark sound notifications',
      importance: Importance.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('bark'),
    );

    // crying 채널 (raw/crying.mp3)
    const chCrying = AndroidNotificationChannel(
      cryingId,
      cryingName,
      description: 'Crying sound notifications',
      importance: Importance.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('crying'),
    );

    await androidFln.createNotificationChannel(chDefault);
    await androidFln.createNotificationChannel(chBark);
    await androidFln.createNotificationChannel(chCrying);
  }

  /// 서버 payload에서 넘어온 sound 값을 보고 어떤 채널/사운드를 쓸지 결정
  static String pickSoundKey({String? dataSound, String? notifSound}) {
    final s = (notifSound?.toLowerCase().trim() ?? dataSound?.toLowerCase().trim() ?? '');
    if (s == 'bark')   return barkId;
    if (s == 'crying') return cryingId;
    return defaultId;
  }

  /// 채널에 맞는 NotificationDetails 리턴
  static NotificationDetails detailsFor(String channelId) {
    switch (channelId) {
      case barkId:
        return const NotificationDetails(
          android: AndroidNotificationDetails(
            barkId,
            barkName,
            channelDescription: 'Bark sound notifications',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('bark'),
          ),
        );
      case cryingId:
        return const NotificationDetails(
          android: AndroidNotificationDetails(
            cryingId,
            cryingName,
            channelDescription: 'Crying sound notifications',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('crying'),
          ),
        );
      default:
        return const NotificationDetails(
          android: AndroidNotificationDetails(
            defaultId,
            defaultName,
            channelDescription: 'Default notifications',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
          ),
        );
    }
  }
}

/// 백그라운드 핸들러에서만 쓰는 초기화 헬퍼
class _FCMBgHelper {
  static final FlutterLocalNotificationsPlugin fln = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static Future<void> ensureInit() async {
    if (_ready) return;
    const initAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const init = InitializationSettings(android: initAndroid);
    await fln.initialize(init);

    final androidFln = fln.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await _FCMChannels.createAll(androidFln);

    _ready = true;
  }
}

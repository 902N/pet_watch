import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:APP/login/splash_screen.dart';
import 'package:APP/pages/main_screen/main_screen.dart';
import 'package:APP/login/login.dart';
import 'package:APP/fcm/fcm_service.dart';
import 'package:APP/widget/pet_id.dart';
import 'package:APP/auth/auth_api.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class FcmRoute {
  static Future<void> showModal({String? title, String? body}) async {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: ctx,
        barrierDismissible: true,
        builder: (_) => AlertDialog(
          title: Text(title ?? '알림'),
          content: Text(body ?? ''),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
              child: const Text('닫기'),
            ),
          ],
        ),
      );
    });
  }
}

class FcmUiBridge {
  static bool _wired = false;
  static void setup() {
    if (_wired) return;
    FirebaseMessaging.onMessage.listen((m) {
      final n = m.notification;
      final title = n?.title ?? m.data['title'];
      final body = n?.body ?? m.data['body'];
      FcmRoute.showModal(title: title, body: body);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((m) {
      final n = m.notification;
      final title = n?.title ?? m.data['title'];
      final body = n?.body ?? m.data['body'];
      FcmRoute.showModal(title: title, body: body);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final m = await FirebaseMessaging.instance.getInitialMessage();
      if (m != null) {
        final n = m.notification;
        final title = n?.title ?? m.data['title'];
        final body = n?.body ?? m.data['body'];
        FcmRoute.showModal(title: title, body: body);
      }
    });
    _wired = true;
  }
}

Future<void> _safeInit() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  final nativeKey = dotenv.env['KAKAO_NATIVE_APP_KEY'] ?? '';
  if (nativeKey.isNotEmpty) {
    KakaoSdk.init(nativeAppKey: nativeKey);
    try { await KakaoSdk.origin; } catch (_) {}
  }
  await FCMService.init();
  FcmUiBridge.setup();
  AuthApi.client;
}

Future<void> main() async {
  await _safeInit();
  runApp(
    ChangeNotifierProvider(
      create: (_) => PetIdStore(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final base = ThemeData(useMaterial3: true);
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: '오늘도펫',
      theme: base.copyWith(scaffoldBackgroundColor: const Color(0xFFF7ECFF)),
      darkTheme: base.copyWith(scaffoldBackgroundColor: const Color(0xFFF7ECFF)),
      initialRoute: '/',
      routes: {
        '/': (ctx) => const SplashScreen(),
        '/main': (ctx) => const MainScreen(),
        '/login': (ctx) => const LoginScreen(),
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
    );
  }
}

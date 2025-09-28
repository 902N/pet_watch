// lib/login/splash_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:APP/auth/env.dart';
import 'package:APP/auth/auth_api.dart' show AuthApi, TokenStore;
import 'package:APP/auth/auth_service.dart';
import 'package:APP/widget/pet_id.dart';
import 'package:APP/login/login.dart';
import 'package:APP/pages/main_screen/main_screen.dart';
import 'package:APP/login/dog_register_screen.dart';
import 'package:APP/fcm/fcm_bridge.dart';
import 'package:APP/notifications/notification_consent.dart';
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _bootstrap();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await Future.delayed(const Duration(milliseconds: 600));

    final at = await TokenStore.access();
    final rt = await TokenStore.refresh();

    String? usableAt = at;
    if ((usableAt == null || usableAt.isEmpty) && rt != null && rt.isNotEmpty) {
      final ok = await AuthService.reissueIfNeeded(context);
      if (ok) usableAt = await TokenStore.access();
    }

    if (usableAt == null || usableAt.isEmpty) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    await FcmBridge.initAndSyncOnce();
    await NotificationConsent.ensureAsked(context);
    try {
      await context.read<PetIdStore>().initFromUserMeAndPets(baseUrl: Env.baseUrl);
      final rsp = await AuthApi.client.get('/pets', options: Options(validateStatus: (_) => true));
      final raw = rsp.data is String ? jsonDecode(rsp.data) : rsp.data;
      final pets = (raw?['data'] as List?) ?? [];

      if (!mounted) return;
      if (pets.isEmpty) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const DogRegisterScreen()));
      } else {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
      }
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: Image(
          image: AssetImage('asset/image/splash_full_center.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

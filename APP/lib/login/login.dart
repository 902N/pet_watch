import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_service.dart';
import '../auth/auth_api.dart' show AuthApi, TokenStore;
import '../pages/main_screen/main_screen.dart';
import '../guide/guideline_page.dart';
import 'dog_register_screen.dart';
import '../auth/env.dart';
import '../widget/pet_id.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _loginWithKakao() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final ok = await AuthService.signIn(context);
    if (!mounted) return;

    if (!ok) {
      setState(() {
        _error = '로그인에 실패했습니다.';
        _loading = false;
      });
      return;
    }

    try {
      await context.read<PetIdStore>().initFromUserMeAndPets(baseUrl: Env.baseUrl);

      if (await OnboardingScreen.shouldShow()) {
        await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
        if (!mounted) return;
      }

      final url = '${Env.apiBase}/pets';
      final rsp = await AuthApi.client.get(
        url,
        options: Options(validateStatus: (_) => true),
      );

      if (rsp.statusCode == 200) {
        final raw = rsp.data;
        final decoded = raw is String ? jsonDecode(raw) : raw;
        final Map<String, dynamic> body = decoded as Map<String, dynamic>;
        final List pets = (body['data'] as List?) ?? [];

        if (!mounted) return;
        if (pets.isEmpty) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const DogRegisterScreen()),
                (_) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainScreen()),
                (_) => false,
          );
        }
      } else {
        setState(() => _error = '펫 정보를 불러올 수 없습니다. (code: ${rsp.statusCode})');
      }
    } catch (e) {
      setState(() => _error = '네트워크 오류: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ------- 옵션: 테스트 로그인 --------
  Future<String?> _pickScenario() async {
    const scenarios = ['default', 'spike', 'gap'];
    return showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const Text('시나리오 선택', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            for (final s in scenarios) ListTile(title: Text(s), onTap: () => Navigator.of(ctx).pop(s)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _demoLoginFlow() async {
    final scenario = await _pickScenario();
    if (scenario == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final endpoint = '${Env.baseUrl}/api/v1/auth/demo-login';
      final rsp = await AuthApi.client.post(
        endpoint,
        queryParameters: {'scenario': scenario},
        options: Options(validateStatus: (_) => true, extra: {'skipAuth': true}),
      );

      if (rsp.statusCode == 200) {
        final raw = rsp.data is String ? jsonDecode(rsp.data) : rsp.data;
        final body = raw as Map<String, dynamic>;
        final data = (body['data'] ?? {}) as Map<String, dynamic>;
        final access = (data['accessToken'] ?? '') as String;
        final refresh = (data['refreshToken'] ?? '') as String;

        if (access.isEmpty || refresh.isEmpty) {
          throw Exception('토큰이 비어 있습니다.');
        }

        await TokenStore.save(access, refresh);

        final sp = await SharedPreferences.getInstance();
        await sp.setString('access_token', access);
        await sp.setString('refresh_token', refresh);
        await sp.setString('accessToken', access);
        await sp.setString('refreshToken', refresh);

        await context.read<PetIdStore>().initFromUserMeAndPets(baseUrl: Env.baseUrl);

        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainScreen()),
              (_) => false,
        );
      } else {
        final raw = rsp.data is String ? jsonDecode(rsp.data) : rsp.data;
        final msg = (raw is Map && raw['message'] is String)
            ? raw['message'] as String
            : '데모 로그인 실패 (${rsp.statusCode})';
        setState(() => _error = msg);
      }
    } catch (e) {
      setState(() => _error = '네트워크 오류: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _LoginBgImage()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _loginWithKakao,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFEE500),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                          : const Text('카카오로 로그인'),
                    ),
                  ),
                  // 테스트 로그인 버튼 쓰려면 아래 주석 해제
                  // const SizedBox(height: 12),
                  // SizedBox(
                  //   width: double.infinity,
                  //   height: 48,
                  //   child: ElevatedButton(
                  //     onPressed: _loading ? null : _demoLoginFlow,
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: Colors.grey.shade300,
                  //       foregroundColor: Colors.black,
                  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  //       elevation: 0,
                  //     ),
                  //     child: const Text('테스트 로그인'),
                  //   ),
                  // ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginBgImage extends StatelessWidget {
  const _LoginBgImage();

  @override
  Widget build(BuildContext context) {
    return const Image(
      image: AssetImage('asset/image/splash_full_center.png'),
      fit: BoxFit.cover,
    );
  }
}

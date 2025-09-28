import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  final bool fromMenu;
  const OnboardingScreen({super.key, this.fromMenu = false});

  static Future<bool> shouldShow() async {
    final p = await SharedPreferences.getInstance();
    return !(p.getBool('guide_seen') ?? false);
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pc = PageController();
  int _index = 0;
  bool _finishing = false;

  final List<_StepData> _steps = const [
    _StepData(
      icon: Icons.edit_calendar_rounded,
      title: '기록하기',
      desc: '식사, 산책, 배변, 건강 상태 등 반려동물의 일상을\n'
          '기록하고 사진·영상도 함께 저장할 수 있습니다.',
    ),
    _StepData(
      icon: Icons.notifications_active_rounded,
      title: 'AI 알림',
      desc: '기록을 기반으로 건강 이상 징후가 감지되면\n'
          '푸시 알림으로 알려드립니다.\n',
    ),
    _StepData(
      icon: Icons.health_and_safety_rounded,
      title: '보험 추천',
      desc: '프로필과 기록을 분석해 반려동물에게 맞는\n'
          '보험 상품을 추천해드립니다.\n'
    ),
    _StepData(
      icon: Icons.person_rounded,
      title: '내 정보 관리',
      desc: '반려동물 프로필과 나의 계정을 [내정보]에서\n'
          '수정·관리할 수 있습니다.',
    ),
  ];


  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  Future<void> _markSeen() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('guide_seen', true);
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    await _markSeen();
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  void _next() {
    final last = _index >= _steps.length - 1;
    if (last) {
      _finish();
    } else {
      _pc.nextPage(duration: const Duration(milliseconds: 240), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _index >= _steps.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFEDE4FF),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => widget.fromMenu ? Navigator.pop(context, false) : _finish(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black54,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('건너뛰기'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pc,
                itemCount: _steps.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) {
                  final s = _steps[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: const Color(0xFFDCCBFF)),
                          ),
                          padding: const EdgeInsets.all(32),
                          child: Icon(s.icon, size: 80, color: const Color(0xFF6B4DE6)),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          s.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black87),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          s.desc,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_steps.length, (i) {
                      final active = i == _index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: active ? 20 : 8,
                        decoration: BoxDecoration(
                          color: active ? const Color(0xFF6B4DE6) : Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B4DE6),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(last ? '시작하기' : '다음'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepData {
  final IconData icon;
  final String title;
  final String desc;
  const _StepData({required this.icon, required this.title, required this.desc});
}

class GuidelinePage extends OnboardingScreen {
  const GuidelinePage({super.key, super.fromMenu});
}

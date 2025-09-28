import 'package:flutter/material.dart';

class IdleView extends StatelessWidget {
  const IdleView({
    super.key,
    required this.intensity,
    required this.onChangeIntensity,
    required this.onStartPressed,
  });

  final String intensity;
  final ValueChanged<String> onChangeIntensity;
  final VoidCallback onStartPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 100,
          child: FittedBox(
            fit: BoxFit.contain,
            child: Image.asset('assets/icon/app_icon_q.png'),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onStartPressed,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            child: const Text('산책 시작', style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }
}

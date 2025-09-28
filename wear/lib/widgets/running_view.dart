import 'package:flutter/material.dart';
import 'stopwatch_text.dart';

class RunningView extends StatelessWidget {
  const RunningView({
    super.key,
    required this.elapsed,
    required this.onEndPressed,
  });

  final Duration elapsed;
  final VoidCallback onEndPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: StopwatchText(duration: elapsed),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onEndPressed,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              // backgroundColor 지정 원하면 Theme 또는 styleFrom(backgroundColor: ...)
            ),
            child: const Text('산책 종료', style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }
}

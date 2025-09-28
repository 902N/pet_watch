import 'package:flutter/material.dart';

class StopwatchText extends StatelessWidget {
  const StopwatchText({super.key, required this.duration});

  final Duration duration;

  String _format(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _format(duration),
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
    );
  }
}

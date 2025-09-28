import 'dart:async';
import 'package:flutter/material.dart';
import '../wear_bridge.dart';
import '../widgets/idle_view.dart';
import '../widgets/running_view.dart';

class WalkHome extends StatefulWidget {
  const WalkHome({super.key});
  @override
  State<WalkHome> createState() => _WalkHomeState();
}

class _WalkHomeState extends State<WalkHome> {
  DateTime? _startUtc;
  String _intensity = '보통';
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  void _start() {
    _startUtc = DateTime.now().toUtc();
    _elapsed = Duration.zero;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsed = DateTime.now().toUtc().difference(_startUtc!);
      });
    });
    WearBridge.sendStart(_startUtc!, _intensity);
    setState(() {});
  }

  void _end() {
    if (_startUtc == null) return;
    final end = DateTime.now().toUtc();
    final dur = end.difference(_startUtc!).inSeconds;
    WearBridge.sendEnd(end, dur, _intensity);
    _timer?.cancel();
    _startUtc = null;
    _elapsed = Duration.zero;
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final running = _startUtc != null;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: running
                  ? RunningView(elapsed: _elapsed, onEndPressed: _end)
                  : IdleView(
                      intensity: _intensity,
                      onChangeIntensity: (v) => setState(() => _intensity = v),
                      onStartPressed: _start,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

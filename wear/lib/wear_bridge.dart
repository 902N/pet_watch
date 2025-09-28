import 'package:flutter/services.dart'; // MethodChannel

class WearBridge {
  // dart와 kotlin이 'wear_comm' 채널로 소통
  static const _ch = MethodChannel('wear_comm');

  static Future<void> sendStart(DateTime startUtc, String intensity) async {
    // 로그
    print(
      "[WearBridge] sendStart: start=${startUtc.toIso8601String()}, intensity=$intensity",
    );

    // Kotlin의 setMethodCallHandler에서 'start_walk'로 수신
    await _ch.invokeMethod('start_walk', <String, dynamic>{
      'startEpochMs': startUtc.millisecondsSinceEpoch,
      'intensity': intensity,
    });
  }

  static Future<void> sendEnd(
    DateTime endUtc,
    int durationSec,
    String intensity,
  ) async {
    print(
      "[WearBridge] sendEnd: end=${endUtc.toIso8601String()}, duration=$durationSec, intensity=$intensity",
    );

    await _ch.invokeMethod('end_walk', <String, dynamic>{
      'endEpochMs': endUtc.millisecondsSinceEpoch,
      'durationSec': durationSec,
      'intensity': intensity,
    });
  }
}

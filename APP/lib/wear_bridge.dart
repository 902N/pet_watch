import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Channel name used to exchange messages between the Android bridge and
/// Flutter. This must stay in sync with [WearBridge.CHANNEL_NAME] on Android.
const _channelName = 'com.example.project/wear';

/// A watch session start payload coming from the wearable device.
class WearStartPayload {
  const WearStartPayload({required this.startUtc, required this.intensity});

  factory WearStartPayload.fromMap(Map<String, dynamic> map) {
    return WearStartPayload(
      startUtc: DateTime.fromMillisecondsSinceEpoch(
        (map['startEpochMs'] as num).toInt(),
        isUtc: true,
      ),
      intensity: map['intensity'] as String? ?? '보통',
    );
  }

  final DateTime startUtc;
  final String intensity;
}

/// A watch session end payload coming from the wearable device.
class WearEndPayload {
  const WearEndPayload({
    required this.endUtc,
    required this.durationSec,
    required this.intensity,
  });

  factory WearEndPayload.fromMap(Map<String, dynamic> map) {
    return WearEndPayload(
      endUtc: DateTime.fromMillisecondsSinceEpoch(
        (map['endEpochMs'] as num).toInt(),
        isUtc: true,
      ),
      durationSec: (map['durationSec'] as num).toInt(),
      intensity: map['intensity'] as String? ?? '보통',
    );
  }

  final DateTime endUtc;
  final int durationSec;
  final String intensity;

  Duration get duration => Duration(seconds: durationSec);

  DateTime inferStartUtc() => endUtc.subtract(duration);
}

/// Combined walk record inferred from paired start/end events.
class WearWalkRecord {
  const WearWalkRecord({
    required this.startUtc,
    required this.endUtc,
    required this.duration,
    required this.intensity,
  });

  final DateTime startUtc;
  final DateTime endUtc;
  final Duration duration;
  final String intensity;
}

/// Thin wrapper around a [MethodChannel] that exposes start/end events as
/// streams to the Flutter layer.
class WearMessageChannel {
  WearMessageChannel._() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  static final WearMessageChannel instance = WearMessageChannel._();

  final MethodChannel _channel = const MethodChannel(_channelName);
  final _startController = StreamController<WearStartPayload>.broadcast();
  final _endController = StreamController<WearEndPayload>.broadcast();

  Stream<WearStartPayload> get onStart => _startController.stream;
  Stream<WearEndPayload> get onEnd => _endController.stream;

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'start_walk':
        final map = Map<String, dynamic>.from(call.arguments as Map);
        _startController.add(WearStartPayload.fromMap(map));
        break;
      case 'end_walk':
        final map = Map<String, dynamic>.from(call.arguments as Map);
        _endController.add(WearEndPayload.fromMap(map));
        break;
      default:
        throw MissingPluginException('Unknown wear method: ${call.method}');
    }
  }
}

/// Wires the wearable events to the existing walk posting flow. Call
/// [WearWalkSync.initialize] once during app start with the handler that
/// performs the actual network/database work. The handler will be invoked every
/// time the wearable sends a complete walk session (start + end).
class WearWalkSync {
  WearWalkSync._(this._onRecord) {
    _subscriptions.add(
      WearMessageChannel.instance.onStart.listen(_handleStart),
    );
    _subscriptions.add(
      WearMessageChannel.instance.onEnd.listen(_handleEnd),
    );
  }

  final Future<void> Function(WearWalkRecord record) _onRecord;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  WearStartPayload? _latestStart;

  static WearWalkSync? _instance;

  static WearWalkSync initialize(
    Future<void> Function(WearWalkRecord record) onRecord,
  ) {
    return _instance ??= WearWalkSync._(onRecord);
  }

  static WearWalkSync? get instance => _instance;

  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    if (identical(_instance, this)) {
      _instance = null;
    }
  }

  void _handleStart(WearStartPayload payload) {
    _latestStart = payload;
    debugPrint('[WearWalkSync] Received start: ${payload.startUtc}');
  }

  void _handleEnd(WearEndPayload payload) {
    final startUtc = (_latestStart?.startUtc ?? payload.inferStartUtc()).toUtc();
    final intensity = payload.intensity;
    final record = WearWalkRecord(
      startUtc: startUtc,
      endUtc: payload.endUtc.toUtc(),
      duration: payload.duration,
      intensity: intensity,
    );
    _latestStart = null;
    debugPrint('[WearWalkSync] Received end: ${record.endUtc} (duration: ${record.duration})');
    unawaited(_onRecord(record));
  }
}

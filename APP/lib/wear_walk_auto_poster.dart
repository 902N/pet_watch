import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:APP/auth/auth_api.dart';
import 'package:APP/pages/home_screen/record/models/walk_record_models.dart';
import 'package:APP/pages/home_screen/record/services/walk_record_service.dart';
import 'package:APP/pages/home_screen/services/record_cache_service.dart';
import 'package:APP/wear_bridge.dart';

/// Automatically posts walk records to the backend when the paired wearable
/// notifies that a walk session has ended.
class WearWalkAutoPoster {
  WearWalkAutoPoster._();

  static WearWalkSync? _sync;
  static bool get isInitialized => _sync != null;

  /// Initializes the wearable synchronisation bridge.
  static void initialize() {
    if (isInitialized) return;
    _sync = WearWalkSync.initialize(_handleRecord);
  }

  static Future<void> _handleRecord(WearWalkRecord record) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final petId = prefs.getInt('last_active_pet_id');
      String? accessToken = await TokenStore.access();
      accessToken ??= prefs.getString('access_token');
      accessToken ??= prefs.getString('accessToken');

      if (petId == null || accessToken == null || accessToken.isEmpty) {
        debugPrint(
          '[WearWalkAutoPoster] Missing credentials. petId=$petId, token?=${accessToken != null}',
        );
        return;
      }

      final startLocal = record.startUtc.toLocal();
      final durationMinutes = _durationMinutes(record.duration);

      final request = WalkRecordRequest(
        recordCategory: '산책',
        recordDateTime: _isoLocalNoOffset(startLocal),
        duration: durationMinutes,
        intensity: record.intensity,
      );

      final response = await WalkRecordService.createWalkRecord(
        petId: petId,
        accessToken: accessToken,
        request: request,
      );

      if ((response as dynamic).success != true) {
        throw Exception((response as dynamic).message);
      }

      _invalidateCaches(petId, startLocal);

      debugPrint(
        '[WearWalkAutoPoster] Walk record posted for petId=$petId start=${record.startUtc} duration=${record.duration.inSeconds}s',
      );
    } catch (e, st) {
      debugPrint('[WearWalkAutoPoster] Failed to post walk record: $e');
      debugPrint('$st');
    }
  }

  static int _durationMinutes(Duration duration) {
    final seconds = max(0, duration.inSeconds);
    final minutes = (seconds + 59) ~/ 60; // round up to nearest minute
    return max(1, minutes);
  }

  static String _isoLocalNoOffset(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    final local = dt.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = two(local.month);
    final d = two(local.day);
    final hh = two(local.hour);
    final mm = two(local.minute);
    final ss = two(local.second);
    return '$y-$m-${d}T$hh:$mm:$ss';
  }

  static void _invalidateCaches(int petId, DateTime startLocal) {
    final cache = RecordCacheService();
    final day = _dayKey(startLocal);
    cache.remove('day_records_${petId}-$day');
    cache.remove('month_records_${petId}-${startLocal.year}-${startLocal.month}');
  }

  static String _dayKey(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)}';
  }
}

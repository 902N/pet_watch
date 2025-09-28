// lib/pages/home_screen/services/record_cache_service.dart

/// A cache service for managing record-related data with TTL (Time To Live) support
///
/// This service provides:
/// - Automatic expiration of cached items
/// - Type-safe caching operations
/// - Pattern-based invalidation
/// - Memory management with size limits
class RecordCacheService {
  static final RecordCacheService _instance = RecordCacheService._internal();
  factory RecordCacheService() => _instance;
  RecordCacheService._internal();

  final Map<String, _CacheEntry> _cache = {};
  final Duration _defaultTtl = const Duration(minutes: 30);
  final int _maxCacheSize = 100;

  /// Get cached value by key
  /// Returns null if key doesn't exist or has expired
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }

    return entry.value as T?;
  }

  /// Set value in cache with optional TTL
  void set<T>(String key, T value, {Duration? ttl}) {
    // Ensure cache doesn't exceed max size
    if (_cache.length >= _maxCacheSize) {
      _evictOldest();
    }

    _cache[key] = _CacheEntry(
      value: value,
      expiredAt: DateTime.now().add(ttl ?? _defaultTtl),
    );
  }

  /// Remove specific key from cache
  void remove(String key) {
    _cache.remove(key);
  }

  /// Remove all keys matching a pattern (supports * wildcard)
  void invalidatePattern(String pattern) {
    final regex = RegExp(pattern.replaceAll('*', '.*'));
    
    // 1단계: 키를 리스트로 변환하여 안전하게 처리
    final keysToRemove = _cache.keys
        .where((key) => regex.hasMatch(key))
        .toList(); // 이터레이터를 리스트로 변환
    
    // 2단계: 리스트의 키들을 순차적으로 제거
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
  }

  /// Clear all cached data
  void clear() {
    _cache.clear();
  }

  /// Get all cache keys
  List<String> getAllKeys() {
    return _cache.keys.toList();
  }

  /// Get cache statistics
  CacheStats get stats {
    final now = DateTime.now();
    final expired = _cache.values.where((entry) => entry.expiredAt.isBefore(now)).length;
    return CacheStats(
      totalEntries: _cache.length,
      expiredEntries: expired,
      validEntries: _cache.length - expired,
    );
  }

  /// Clean up expired entries
  void cleanup() {
    final now = DateTime.now();
    final expiredKeys = _cache.entries
        .where((entry) => entry.value.expiredAt.isBefore(now))
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      _cache.remove(key);
    }
  }

  /// Evict oldest entry to make room for new ones
  void _evictOldest() {
    if (_cache.isEmpty) return;

    String? oldestKey;
    DateTime? oldestTime;

    for (final entry in _cache.entries) {
      if (oldestTime == null || entry.value.expiredAt.isBefore(oldestTime)) {
        oldestTime = entry.value.expiredAt;
        oldestKey = entry.key;
      }
    }

    if (oldestKey != null) {
      _cache.remove(oldestKey);
    }
  }
}

/// Internal cache entry with expiration support
class _CacheEntry {
  final dynamic value;
  final DateTime expiredAt;

  _CacheEntry({
    required this.value,
    required this.expiredAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiredAt);
}

/// Cache statistics for monitoring
class CacheStats {
  final int totalEntries;
  final int expiredEntries;
  final int validEntries;

  const CacheStats({
    required this.totalEntries,
    required this.expiredEntries,
    required this.validEntries,
  });

  double get hitRatio => totalEntries > 0 ? validEntries / totalEntries : 0.0;

  @override
  String toString() => 'CacheStats(total: $totalEntries, valid: $validEntries, expired: $expiredEntries, hitRatio: ${(hitRatio * 100).toStringAsFixed(1)}%)';
}
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class LocalCacheManager {
  LocalCacheManager._();

  static final LocalCacheManager instance = LocalCacheManager._();

  final Map<String, Map<String, dynamic>> _memoryCache =
      <String, Map<String, dynamic>>{};

  File _getCacheFile(String key) {
    final tempDir = Directory.systemTemp;
    final safeKey = key.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    return File('${tempDir.path}/cinetrekker_v2_$safeKey.json');
  }

  Future<void> write(
    String key,
    Map<String, dynamic> jsonMap, {
    Duration? ttl,
  }) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final isUserData =
          key.startsWith('local_') ||
          key.startsWith('guest_') ||
          key.startsWith('user_');
      final expiry = isUserData || ttl == null
          ? null
          : now + ttl.inMilliseconds;

      final envelope = <String, dynamic>{
        '_cached_at': now,
        if (expiry != null) '_expires_at': expiry,
        'data': jsonMap,
      };

      _memoryCache[key] = envelope;

      final file = _getCacheFile(key);
      final jsonString = jsonEncode(envelope);
      await file.writeAsString(jsonString);
    } catch (e) {
      debugPrint('LocalCacheManager: Failed to write cache key $key: $e');
    }
  }

  Future<Map<String, dynamic>?> read(String key) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;

      // Check memory cache first
      if (_memoryCache.containsKey(key)) {
        final cached = _memoryCache[key]!;
        final expiresAt = cached['_expires_at'] as int?;
        if (expiresAt == null || expiresAt > now) {
          final data = cached['data'];
          if (data is Map<String, dynamic>) return data;
        } else {
          _memoryCache.remove(key);
        }
      }

      final file = _getCacheFile(key);
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final decoded = jsonDecode(jsonString);
        if (decoded is Map<String, dynamic>) {
          // Handle both envelope format and legacy format
          if (decoded.containsKey('data') &&
              decoded.containsKey('_cached_at')) {
            final expiresAt = decoded['_expires_at'] as int?;
            if (expiresAt == null || expiresAt > now) {
              final payload = decoded['data'] as Map<String, dynamic>?;
              if (payload != null) {
                _memoryCache[key] = decoded;
                return payload;
              }
            } else {
              // Expired
              await clear(key);
              return null;
            }
          }
          return decoded;
        }
      }
    } catch (e) {
      debugPrint('LocalCacheManager: Failed to read cache key $key: $e');
    }
    return null;
  }

  Future<void> clear(String key) async {
    try {
      _memoryCache.remove(key);
      final file = _getCacheFile(key);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('LocalCacheManager: Failed to clear cache key $key: $e');
    }
  }

  void clearMemory() {
    _memoryCache.clear();
  }
}

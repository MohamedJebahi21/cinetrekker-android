import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class LocalCacheManager {
  LocalCacheManager._();

  static final LocalCacheManager instance = LocalCacheManager._();

  final Map<String, Map<String, dynamic>> _memoryCache =
      <String, Map<String, dynamic>>{};

  Directory? _documentsDir;

  @visibleForTesting
  void setDocumentsDirForTesting(Directory? dir) {
    _documentsDir = dir;
  }

  bool _isPersistentKey(String key) {
    return key.startsWith('local_') ||
        key.startsWith('guest_') ||
        key.startsWith('user_') ||
        key.startsWith('offline_') ||
        key.startsWith('mywatch_') ||
        key.contains('watchlist') ||
        key.contains('watched') ||
        key.contains('followed') ||
        key.contains('favorites') ||
        key.contains('collections') ||
        key.contains('queue');
  }

  Future<File> _getCacheFile(String key) async {
    final safeKey = key.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final fileName = 'cinetrekker_v2_$safeKey.json';

    if (_isPersistentKey(key)) {
      if (_documentsDir == null) {
        try {
          _documentsDir = await getApplicationDocumentsDirectory();
        } catch (_) {
          // Fallback to system temp if path_provider is unavailable (e.g. headless tests)
          _documentsDir = Directory.systemTemp;
        }
      }
      return File('${_documentsDir!.path}/$fileName');
    }

    return File('${Directory.systemTemp.path}/$fileName');
  }

  Future<void> write(
    String key,
    Map<String, dynamic> jsonMap, {
    Duration? ttl,
  }) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final isUserData = _isPersistentKey(key);
      final expiry = isUserData || ttl == null
          ? null
          : now + ttl.inMilliseconds;

      final envelope = <String, dynamic>{
        '_cached_at': now,
        if (expiry != null) '_expires_at': expiry,
        'data': jsonMap,
      };

      _memoryCache[key] = envelope;

      final file = await _getCacheFile(key);
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

      final file = await _getCacheFile(key);
      File targetFile = file;

      // Seamless migration check: if persistent file does not exist, check legacy temp location
      if (!await targetFile.exists() && _isPersistentKey(key)) {
        final safeKey = key.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
        final legacyFile =
            File('${Directory.systemTemp.path}/cinetrekker_v2_$safeKey.json');
        if (await legacyFile.exists()) {
          targetFile = legacyFile;
        }
      }

      if (await targetFile.exists()) {
        final jsonString = await targetFile.readAsString();
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
      final file = await _getCacheFile(key);
      if (await file.exists()) {
        await file.delete();
      }
      if (_isPersistentKey(key)) {
        final safeKey = key.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
        final legacyFile =
            File('${Directory.systemTemp.path}/cinetrekker_v2_$safeKey.json');
        if (await legacyFile.exists()) {
          await legacyFile.delete();
        }
      }
    } catch (e) {
      debugPrint('LocalCacheManager: Failed to clear cache key $key: $e');
    }
  }

  void clearMemory() {
    _memoryCache.clear();
  }
}

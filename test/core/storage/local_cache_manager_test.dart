import 'dart:io';

import 'package:cinetrekker_android/core/storage/local_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory testDir;
  final cache = LocalCacheManager.instance;

  setUp(() async {
    testDir = await Directory.systemTemp.createTemp('cinetrekker_cache_test_');
    cache.setDocumentsDirForTesting(testDir);
    cache.clearMemory();
  });

  tearDown(() async {
    cache.clearMemory();
    if (await testDir.exists()) {
      await testDir.delete(recursive: true);
    }
  });

  group('LocalCacheManager', () {
    test('writes and reads data successfully', () async {
      const key = 'user_test_profile';
      final payload = {'username': 'cine_fan', 'tier': 'pro'};

      await cache.write(key, payload);
      final readBack = await cache.read(key);

      expect(readBack, isNotNull);
      expect(readBack?['username'], 'cine_fan');
      expect(readBack?['tier'], 'pro');
    });

    test('memory cache returns data without re-reading file', () async {
      const key = 'local_memory_check';
      final payload = {'score': 9.5};

      await cache.write(key, payload);
      final fromMem = await cache.read(key);

      expect(fromMem?['score'], 9.5);
    });

    test('respects TTL and returns null when expired', () async {
      const key = 'transient_feed_cache';
      final payload = {'page': 1};

      // Write with negative/expired TTL
      await cache.write(key, payload, ttl: const Duration(milliseconds: -10));
      cache.clearMemory();

      final result = await cache.read(key);
      expect(result, isNull);
    });

    test('user data ignores short TTL to prevent data loss', () async {
      const key = 'user_library_state';
      final payload = {'watched_count': 42};

      await cache.write(key, payload, ttl: const Duration(milliseconds: -10));
      cache.clearMemory();

      final result = await cache.read(key);
      expect(result?['watched_count'], 42);
    });

    test('clear removes both memory and file cache', () async {
      const key = 'guest_temp_data';
      final payload = {'temporary': true};

      await cache.write(key, payload);
      expect(await cache.read(key), isNotNull);

      await cache.clear(key);
      cache.clearMemory();

      expect(await cache.read(key), isNull);
    });
  });
}

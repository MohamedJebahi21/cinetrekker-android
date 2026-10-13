import 'dart:io';

import 'package:cinetrekker_android/core/offline/offline_mutation_queue.dart';
import 'package:cinetrekker_android/core/storage/local_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory testDir;
  final queue = OfflineMutationQueue.instance;

  setUp(() async {
    testDir = await Directory.systemTemp.createTemp('cinetrekker_queue_test_');
    LocalCacheManager.instance.setDocumentsDirForTesting(testDir);
    LocalCacheManager.instance.clearMemory();
    await queue.clearQueue();
  });

  tearDown(() async {
    await queue.clearQueue();
    LocalCacheManager.instance.clearMemory();
    if (await testDir.exists()) {
      await testDir.delete(recursive: true);
    }
  });

  group('OfflineMutationQueue', () {
    test('enqueues and retrieves mutations with user isolation', () async {
      await queue.enqueue(
        OfflineMutationType.addToWatchlist,
        {'media_id': 123, 'media_type': 'movie', 'title': 'Dune'},
        userId: 'user_alpha',
      );

      await queue.enqueue(
        OfflineMutationType.markEpisodeWatched,
        {'show_id': 456, 'season_number': 1, 'episode_number': 1},
        userId: 'user_beta',
      );

      final alphaQueue = await queue.getQueueForUser('user_alpha');
      expect(alphaQueue.length, 1);
      expect(alphaQueue.first.type, OfflineMutationType.addToWatchlist);
      expect(alphaQueue.first.payload['title'], 'Dune');
      expect(alphaQueue.first.userId, 'user_alpha');

      final betaQueue = await queue.getQueueForUser('user_beta');
      expect(betaQueue.length, 1);
      expect(betaQueue.first.type, OfflineMutationType.markEpisodeWatched);
      expect(betaQueue.first.payload['show_id'], 456);

      final allMutations = await queue.getQueue();
      expect(allMutations.length, 2);
    });

    test('removes specific mutation by ID', () async {
      await queue.enqueue(
        OfflineMutationType.addToWatched,
        {'media_id': 789, 'media_type': 'movie'},
        userId: 'user_alpha',
      );

      final initial = await queue.getQueueForUser('user_alpha');
      expect(initial.length, 1);
      final mutationId = initial.first.id;

      await queue.remove(mutationId);

      final remaining = await queue.getQueueForUser('user_alpha');
      expect(remaining, isEmpty);
    });

    test('clearQueueForUser only removes mutations for designated user', () async {
      await queue.enqueue(
        OfflineMutationType.addToWatchlist,
        {'media_id': 1},
        userId: 'user_a',
      );
      await queue.enqueue(
        OfflineMutationType.followShow,
        {'show_id': 2},
        userId: 'user_b',
      );

      await queue.clearQueueForUser('user_a');

      expect(await queue.getQueueForUser('user_a'), isEmpty);
      final userBQueue = await queue.getQueueForUser('user_b');
      expect(userBQueue.length, 1);
      expect(userBQueue.first.type, OfflineMutationType.followShow);
    });
  });
}

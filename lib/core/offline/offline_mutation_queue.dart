import 'package:flutter/foundation.dart';
import '../storage/local_cache_manager.dart';

enum OfflineMutationType {
  addToWatchlist,
  removeFromWatchlist,
  addToWatched,
  removeFromWatched,
  followShow,
  unfollowShow,
  markEpisodeWatched,
  unmarkEpisodeWatched,
}

class OfflineMutation {
  const OfflineMutation({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.userId,
  });

  factory OfflineMutation.fromJson(Map<String, dynamic> json) {
    return OfflineMutation(
      id: json['id'] as String? ?? '',
      type: OfflineMutationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => OfflineMutationType.addToWatchlist,
      ),
      payload: (json['payload'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{},
      createdAt: json['created_at'] as int? ?? 0,
      userId: json['user_id'] as String?,
    );
  }

  final String id;
  final OfflineMutationType type;
  final Map<String, dynamic> payload;
  final int createdAt;
  final String? userId;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': type.name,
        'payload': payload,
        'created_at': createdAt,
        if (userId != null) 'user_id': userId,
      };
}

class OfflineMutationQueue {
  OfflineMutationQueue._();
  static final OfflineMutationQueue instance = OfflineMutationQueue._();

  static const String _queueCacheKey = 'offline_mutation_queue';

  Future<List<OfflineMutation>> getQueue() async {
    try {
      final data = await LocalCacheManager.instance.read(_queueCacheKey);
      final rawList = data?['mutations'];
      if (rawList is! List) return <OfflineMutation>[];
      return rawList
          .whereType<Map>()
          .map((m) => OfflineMutation.fromJson(m.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      debugPrint('OfflineMutationQueue: Failed to read queue: $e');
      return <OfflineMutation>[];
    }
  }

  Future<List<OfflineMutation>> getQueueForUser(String? userId) async {
    final all = await getQueue();
    if (userId == null || userId.isEmpty) {
      return all.where((m) => m.userId == null).toList();
    }
    return all.where((m) => m.userId == userId).toList();
  }

  Future<void> enqueue(
    OfflineMutationType type,
    Map<String, dynamic> payload, {
    String? userId,
  }) async {
    try {
      final current = await getQueue();
      final id = '${DateTime.now().millisecondsSinceEpoch}_${current.length}';
      final mutation = OfflineMutation(
        id: id,
        type: type,
        payload: payload,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        userId: userId,
      );
      current.add(mutation);
      await LocalCacheManager.instance.write(_queueCacheKey, <String, dynamic>{
        'mutations': current.map((m) => m.toJson()).toList(),
      });
      debugPrint('OfflineMutationQueue: Enqueued mutation ${mutation.id} (${type.name})');
    } catch (e) {
      debugPrint('OfflineMutationQueue: Failed to enqueue mutation: $e');
    }
  }

  Future<void> remove(String id) async {
    try {
      final current = await getQueue();
      current.removeWhere((m) => m.id == id);
      await LocalCacheManager.instance.write(_queueCacheKey, <String, dynamic>{
        'mutations': current.map((m) => m.toJson()).toList(),
      });
    } catch (e) {
      debugPrint('OfflineMutationQueue: Failed to remove mutation $id: $e');
    }
  }

  Future<void> clearQueueForUser(String? userId) async {
    try {
      final current = await getQueue();
      final remaining = (userId == null || userId.isEmpty)
          ? current.where((m) => m.userId != null).toList()
          : current.where((m) => m.userId != userId).toList();
      await LocalCacheManager.instance.write(_queueCacheKey, <String, dynamic>{
        'mutations': remaining.map((m) => m.toJson()).toList(),
      });
    } catch (e) {
      debugPrint('OfflineMutationQueue: Failed to clear queue for user: $e');
    }
  }

  Future<void> clear() async {
    try {
      await LocalCacheManager.instance.write(_queueCacheKey, <String, dynamic>{
        'mutations': <Map<String, dynamic>>[],
      });
    } catch (e) {
      debugPrint('OfflineMutationQueue: Failed to clear queue: $e');
    }
  }

  Future<void> clearQueue() => clear();
}

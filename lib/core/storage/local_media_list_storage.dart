import '../models/media_models.dart';
import 'local_cache_manager.dart';

class LocalMediaListStorage {
  Future<List<UserMediaItem>> readList(String key) async {
    final payload = await LocalCacheManager.instance.read(key);
    final rawItems = payload?['items'];
    if (rawItems is! List) return const <UserMediaItem>[];
    return rawItems
        .whereType<Map>()
        .map((item) => UserMediaItem.fromJson(item.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<void> writeList(String key, List<UserMediaItem> items) async {
    await LocalCacheManager.instance.write(key, <String, dynamic>{
      'items': items.map((item) => item.toJson()).toList(growable: false),
    });
  }

  Future<List<FollowedShowItem>> readFollowedShows(String key) async {
    final payload = await LocalCacheManager.instance.read(key);
    final rawItems = payload?['items'];
    if (rawItems is! List) return const <FollowedShowItem>[];
    return rawItems
        .whereType<Map>()
        .map((item) => FollowedShowItem.fromJson(item.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<void> writeFollowedShows(
    String key,
    List<FollowedShowItem> items,
  ) async {
    await LocalCacheManager.instance.write(key, <String, dynamic>{
      'items': items.map((item) => item.toJson()).toList(growable: false),
    });
  }

  Future<List<WatchedEpisodeItem>> readWatchedEpisodes(String key) async {
    final payload = await LocalCacheManager.instance.read(key);
    final rawItems = payload?['items'];
    if (rawItems is! List) return const <WatchedEpisodeItem>[];
    return rawItems
        .whereType<Map>()
        .map(
          (item) => WatchedEpisodeItem.fromJson(item.cast<String, dynamic>()),
        )
        .toList(growable: false);
  }

  Future<void> writeWatchedEpisodes(
    String key,
    List<WatchedEpisodeItem> items,
  ) async {
    await LocalCacheManager.instance.write(key, <String, dynamic>{
      'items': items.map((item) => item.toJson()).toList(growable: false),
    });
  }

  Future<List<String>> readFavorites(String key) async {
    final payload = await LocalCacheManager.instance.read(key);
    final rawItems = payload?['items'];
    if (rawItems is! List) return const <String>[];
    return rawItems.whereType<String>().toList(growable: false);
  }

  Future<void> writeFavorites(String key, List<String> items) async {
    await LocalCacheManager.instance.write(key, <String, dynamic>{
      'items': items,
    });
  }

  Future<List<Map<String, dynamic>>> readCollections(String key) async {
    final payload = await LocalCacheManager.instance.read(key);
    final rawItems = payload?['items'];
    if (rawItems is! List) return const <Map<String, dynamic>>[];
    return rawItems
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList(growable: false);
  }

  Future<void> writeCollections(
    String key,
    List<Map<String, dynamic>> items,
  ) async {
    await LocalCacheManager.instance.write(key, <String, dynamic>{
      'items': items,
    });
  }

  Future<void> clear(String key) => LocalCacheManager.instance.clear(key);
}

final localMediaListStorage = LocalMediaListStorage();

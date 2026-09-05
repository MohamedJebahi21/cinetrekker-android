import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/supabase_rest_api.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/storage/local_media_list_storage.dart';

class UserCollection {
  const UserCollection({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.itemCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final String? description;
  final int itemCount;
  final String? createdAt;
  final String? updatedAt;

  factory UserCollection.fromJson(Map<String, dynamic> json) {
    return UserCollection(
      id: json['id']?.toString() ?? '',
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled collection',
      description: json['description'] as String?,
      itemCount:
          (json['item_count'] as num?)?.toInt() ??
          (json['collection_items_count'] as num?)?.toInt() ??
          0,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'user_id': userId,
    'name': name,
    'description': description,
    'item_count': itemCount,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}

class CollectionsRepository {
  CollectionsRepository({
    required this.api,
    required this.userId,
    required this.storage,
  });

  final SupabaseRestApi api;
  final String? userId;
  final LocalMediaListStorage storage;

  static const String _guestCollectionsKey = 'guest_collections';

  bool get isSignedIn => userId != null && userId!.isNotEmpty;

  Future<List<UserCollection>> loadCollections() async {
    if (!isSignedIn) {
      final raw = await storage.readCollections(_guestCollectionsKey);
      return raw.map(UserCollection.fromJson).toList(growable: false);
    }
    final rows = await api.selectRows(
      'collections',
      equals: <String, dynamic>{'user_id': userId},
      orderBy: 'created_at',
      descending: true,
    );
    return rows.map(UserCollection.fromJson).toList(growable: false);
  }

  Future<void> createCollection({
    required String name,
    String? description,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError.value(
        name,
        'name',
        'Collection name cannot be empty.',
      );
    }

    if (!isSignedIn) {
      final existing = await loadCollections();
      final now = DateTime.now().toIso8601String();
      final newCol = UserCollection(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'guest',
        name: trimmedName,
        description: description?.trim().isEmpty == true ? null : description?.trim(),
        itemCount: 0,
        createdAt: now,
        updatedAt: now,
      );
      final updated = [...existing, newCol];
      await storage.writeCollections(
        _guestCollectionsKey,
        updated.map((c) => c.toJson()).toList(growable: false),
      );
      return;
    }

    await api.upsertRow('collections', <String, dynamic>{
      'user_id': userId,
      'name': trimmedName,
      'description': description?.trim().isEmpty == true
          ? null
          : description?.trim(),
    }, onConflict: 'user_id,name');
  }

  Future<void> deleteAccountData() async {
    if (!isSignedIn) {
      await storage.clear(_guestCollectionsKey);
      return;
    }
    await api.deleteRows(
      'collections',
      equals: <String, dynamic>{'user_id': userId},
    );
  }

  Future<void> deleteCollection(String collectionId) async {
    if (!isSignedIn) {
      final existing = await loadCollections();
      final updated = existing.where((c) => c.id != collectionId).toList();
      await storage.writeCollections(
        _guestCollectionsKey,
        updated.map((c) => c.toJson()).toList(growable: false),
      );
      return;
    }
    await api.deleteRows(
      'collections',
      equals: <String, dynamic>{'id': collectionId, 'user_id': userId},
    );
  }
}

final collectionsRepositoryProvider = Provider<CollectionsRepository>((ref) {
  final session = ref.watch(authControllerProvider).valueOrNull;
  return CollectionsRepository(
    api: ref.watch(supabaseRestApiProvider),
    userId: session?.user.id,
    storage: localMediaListStorage,
  );
});

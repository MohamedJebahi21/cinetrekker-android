import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error_messages.dart';
import '../data/collections_repository.dart';

class CollectionsState {
  const CollectionsState({
    required this.collections,
    required this.isLoading,
    required this.error,
  });

  factory CollectionsState.initial() {
    return const CollectionsState(
      collections: <UserCollection>[],
      isLoading: false,
      error: null,
    );
  }

  final List<UserCollection> collections;
  final bool isLoading;
  final String? error;

  CollectionsState copyWith({
    List<UserCollection>? collections,
    bool? isLoading,
    String? error,
  }) {
    return CollectionsState(
      collections: collections ?? this.collections,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final collectionsControllerProvider =
    NotifierProvider<CollectionsController, CollectionsState>(
      CollectionsController.new,
    );

class CollectionsController extends Notifier<CollectionsState> {
  @override
  CollectionsState build() {
    return CollectionsState.initial();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repository = ref.read(collectionsRepositoryProvider);
      final collections = await repository.loadCollections();
      state = state.copyWith(collections: collections, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: describeAppError(error));
    }
  }

  Future<void> createCollection({
    required String name,
    String? description,
  }) async {
    final repository = ref.read(collectionsRepositoryProvider);
    await repository.createCollection(name: name, description: description);
    await load();
  }

  Future<void> deleteCollection(String collectionId) async {
    final repository = ref.read(collectionsRepositoryProvider);
    await repository.deleteCollection(collectionId);
    await load();
  }
}

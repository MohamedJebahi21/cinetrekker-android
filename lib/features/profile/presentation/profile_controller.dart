import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error_messages.dart';
import '../../../core/models/media_models.dart';
import '../../../core/storage/local_media_list_storage.dart';
import '../../watchlist/data/user_library_repository.dart';
import '../data/profile_repository.dart';

class ProfileState {
  const ProfileState({
    required this.profile,
    required this.watchlistCount,
    required this.watchedCount,
    required this.averageRating,
    required this.isLoading,
    required this.error,
  });

  factory ProfileState.initial() {
    return const ProfileState(
      profile: null,
      watchlistCount: 0,
      watchedCount: 0,
      averageRating: 0,
      isLoading: false,
      error: null,
    );
  }

  final UserProfileData? profile;
  final int watchlistCount;
  final int watchedCount;
  final double averageRating;
  final bool isLoading;
  final String? error;

  List<String> get favorites => profile?.favoriteTitles ?? const <String>[];

  ProfileState copyWith({
    UserProfileData? profile,
    int? watchlistCount,
    int? watchedCount,
    double? averageRating,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      watchlistCount: watchlistCount ?? this.watchlistCount,
      watchedCount: watchedCount ?? this.watchedCount,
      averageRating: averageRating ?? this.averageRating,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final profileControllerProvider =
    NotifierProvider<ProfileController, ProfileState>(ProfileController.new);

class ProfileController extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    return ProfileState.initial();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final profileRepository = ref.read(profileRepositoryProvider);
      final libraryRepository = ref.read(userLibraryRepositoryProvider);
      if (profileRepository == null) {
        final guestFavorites = await localMediaListStorage.readFavorites('guest_favorites');
        final guestWatchlist = await libraryRepository.getWatchlist();
        final guestWatched = await libraryRepository.getWatched();
        final ratings = guestWatched
            .map((item) => item.rating)
            .whereType<double>()
            .toList(growable: false);
        final double averageRating = ratings.isEmpty
            ? 0
            : ratings.reduce((a, b) => a + b) / ratings.length;

        state = ProfileState(
          profile: UserProfileData(
            userId: 'guest',
            displayName: 'Guest Trekker',
            bio: null,
            avatarUrl: null,
            isPublic: false,
            showWatchlist: true,
            showStats: true,
            allowRecommendations: true,
            showAge: false,
            favoriteGenres: const <int>[],
            favoriteTitles: guestFavorites,
            maturityRating: 'none',
            adultContentEnabled: false,
            strictFilteringEnabled: true,
            moderateFilteringEnabled: false,
            createdAt: null,
            updatedAt: null,
          ),
          watchlistCount: guestWatchlist.length,
          watchedCount: guestWatched.length,
          averageRating: averageRating,
          isLoading: false,
          error: null,
        );
        return;
      }

      final results = await Future.wait([
        profileRepository.loadProfile(),
        libraryRepository.getWatchlist(),
        libraryRepository.getWatched(),
      ]);

      final watched = results[2] as List<UserMediaItem>;
      final ratings = watched
          .map((item) => item.rating)
          .whereType<double>()
          .toList(growable: false);
      final double averageRating = ratings.isEmpty
          ? 0
          : ratings.reduce((a, b) => a + b) / ratings.length;

      state = ProfileState(
        profile: results[0] as UserProfileData,
        watchlistCount: (results[1] as List<UserMediaItem>).length,
        watchedCount: watched.length,
        averageRating: averageRating,
        isLoading: false,
        error: null,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: describeAppError(error));
    }
  }

  Future<void> saveProfile(UserProfileData profile) async {
    final profileRepository = ref.read(profileRepositoryProvider);
    if (profileRepository == null) {
      throw StateError('Sign in to edit your profile.');
    }

    await profileRepository.saveProfile(profile);
    await load();
  }

  Future<void> save({
    required String displayName,
    required String bio,
    required bool isPublic,
    required bool showWatchlist,
    required bool showStats,
    required bool allowRecommendations,
  }) async {
    final profileRepository = ref.read(profileRepositoryProvider);
    if (profileRepository == null) {
      throw StateError('Sign in to edit your profile.');
    }

    final current = state.profile ?? await profileRepository.loadProfile();
    final updated = current.copyWith(
      displayName: displayName,
      bio: bio,
      isPublic: isPublic,
      showWatchlist: showWatchlist,
      showStats: showStats,
      allowRecommendations: allowRecommendations,
    );
    await profileRepository.saveProfile(updated);
    await load();
  }

  Future<void> toggleFavoriteTitle({
    required String mediaType,
    required int mediaId,
  }) async {
    final profileRepository = ref.read(profileRepositoryProvider);
    final key = ProfileRepository.favoriteKey(mediaType, mediaId);

    if (profileRepository == null) {
      final currentList = await localMediaListStorage.readFavorites('guest_favorites');
      final updatedList = [...currentList];
      if (updatedList.contains(key)) {
        updatedList.remove(key);
      } else {
        updatedList.add(key);
      }
      await localMediaListStorage.writeFavorites('guest_favorites', updatedList);
      final currentProfile = state.profile ??
          const UserProfileData(
            userId: 'guest',
            displayName: 'Guest Trekker',
            bio: null,
            avatarUrl: null,
            isPublic: false,
            showWatchlist: true,
            showStats: true,
            allowRecommendations: true,
            showAge: false,
            favoriteGenres: <int>[],
            favoriteTitles: <String>[],
            maturityRating: 'none',
            adultContentEnabled: false,
            strictFilteringEnabled: true,
            moderateFilteringEnabled: false,
            createdAt: null,
            updatedAt: null,
          );
      state = state.copyWith(
        profile: currentProfile.copyWith(
          favoriteTitles: List<String>.unmodifiable(updatedList),
        ),
      );
      return;
    }

    final profile = state.profile ?? await profileRepository.loadProfile();
    final favorites = [...profile.favoriteTitles];
    if (favorites.contains(key)) {
      favorites.remove(key);
    } else {
      favorites.add(key);
    }

    final updated = await profileRepository.updateFavoriteTitles(favorites);
    state = state.copyWith(profile: updated);
  }

  bool isFavorite({required String mediaType, required int mediaId}) {
    final profile = state.profile;
    if (profile == null) {
      return false;
    }

    return profile.favoriteTitles.contains(
      ProfileRepository.favoriteKey(mediaType, mediaId),
    );
  }
}

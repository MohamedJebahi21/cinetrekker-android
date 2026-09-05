import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/supabase_rest_api.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/models/media_models.dart';

class UserProfileData {
  const UserProfileData({
    required this.userId,
    required this.displayName,
    required this.bio,
    required this.avatarUrl,
    required this.isPublic,
    required this.showWatchlist,
    required this.showStats,
    required this.allowRecommendations,
    required this.showAge,
    required this.favoriteGenres,
    required this.favoriteTitles,
    required this.maturityRating,
    required this.adultContentEnabled,
    required this.strictFilteringEnabled,
    required this.moderateFilteringEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  final String userId;
  final String? displayName;
  final String? bio;
  final String? avatarUrl;
  final bool isPublic;
  final bool showWatchlist;
  final bool showStats;
  final bool allowRecommendations;
  final bool showAge;
  final List<int> favoriteGenres;
  final List<String> favoriteTitles;
  final String maturityRating;
  final bool adultContentEnabled;
  final bool strictFilteringEnabled;
  final bool moderateFilteringEnabled;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DateTime? get createdAtDate => createdAt;

  DateTime? get updatedAtDate => updatedAt;

  UserProfileData copyWith({
    String? userId,
    String? displayName,
    String? bio,
    String? avatarUrl,
    bool? isPublic,
    bool? showWatchlist,
    bool? showStats,
    bool? allowRecommendations,
    bool? showAge,
    List<int>? favoriteGenres,
    List<String>? favoriteTitles,
    String? maturityRating,
    bool? adultContentEnabled,
    bool? strictFilteringEnabled,
    bool? moderateFilteringEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfileData(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isPublic: isPublic ?? this.isPublic,
      showWatchlist: showWatchlist ?? this.showWatchlist,
      showStats: showStats ?? this.showStats,
      allowRecommendations: allowRecommendations ?? this.allowRecommendations,
      showAge: showAge ?? this.showAge,
      favoriteGenres: favoriteGenres ?? this.favoriteGenres,
      favoriteTitles: favoriteTitles ?? this.favoriteTitles,
      maturityRating: maturityRating ?? this.maturityRating,
      adultContentEnabled: adultContentEnabled ?? this.adultContentEnabled,
      strictFilteringEnabled:
          strictFilteringEnabled ?? this.strictFilteringEnabled,
      moderateFilteringEnabled:
          moderateFilteringEnabled ?? this.moderateFilteringEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory UserProfileData.fromJson(
    Map<String, dynamic> json, {
    String? fallbackUserId,
  }) {
    final genres = json['favorite_genres'];
    final titles = json['favorite_titles'];
    return UserProfileData(
      userId: json['user_id'] as String? ?? fallbackUserId ?? '',
      displayName: json['display_name'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isPublic: json['is_public'] as bool? ?? false,
      showWatchlist: json['show_watchlist'] as bool? ?? true,
      showStats: json['show_stats'] as bool? ?? true,
      allowRecommendations: json['allow_recommendations'] as bool? ?? true,
      showAge: json['show_age'] as bool? ?? false,
      favoriteGenres: genres is List
          ? genres
                .whereType<num>()
                .map((value) => value.toInt())
                .toList(growable: false)
          : const <int>[],
      favoriteTitles: titles is List
          ? titles.whereType<String>().toList(growable: false)
          : const <String>[],
      maturityRating: json['maturity_rating'] as String? ?? 'none',
      adultContentEnabled: json['adult_content_enabled'] as bool? ?? false,
      strictFilteringEnabled: json['strict_filtering_enabled'] as bool? ?? true,
      moderateFilteringEnabled:
          json['moderate_filtering_enabled'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson([String? overrideUserId]) => <String, dynamic>{
    'user_id': overrideUserId ?? userId,
    'display_name': displayName,
    'bio': bio,
    'avatar_url': avatarUrl,
    'is_public': isPublic,
    'show_watchlist': showWatchlist,
    'show_stats': showStats,
    'allow_recommendations': allowRecommendations,
    'show_age': showAge,
    'favorite_genres': favoriteGenres,
    'favorite_titles': favoriteTitles,
    'maturity_rating': maturityRating,
    'adult_content_enabled': adultContentEnabled,
    'strict_filtering_enabled': strictFilteringEnabled,
    'moderate_filtering_enabled': moderateFilteringEnabled,
  };
}

class ProfileRepository {
  ProfileRepository({required this.api, required this.userId});

  final SupabaseRestApi api;
  final String userId;

  Future<UserProfileData> loadProfile() async {
    final rows = await api.selectRows(
      'profiles',
      equals: <String, dynamic>{'user_id': userId},
    );
    if (rows.isEmpty) {
      return UserProfileData(
        userId: userId,
        displayName: null,
        bio: null,
        avatarUrl: null,
        isPublic: false,
        showWatchlist: true,
        showStats: true,
        allowRecommendations: true,
        showAge: false,
        favoriteGenres: const <int>[],
        favoriteTitles: const <String>[],
        maturityRating: 'none',
        adultContentEnabled: false,
        strictFilteringEnabled: true,
        moderateFilteringEnabled: false,
        createdAt: null,
        updatedAt: null,
      );
    }
    return UserProfileData.fromJson(rows.first, fallbackUserId: userId);
  }

  Future<UserProfileData?> loadPublicProfile(String targetUserId) async {
    final normalizedId = targetUserId.trim();
    if (normalizedId.isEmpty) return null;
    final rows = await api.selectRows(
      'profiles',
      equals: <String, dynamic>{'user_id': normalizedId},
    );
    if (rows.isEmpty) return null;
    final profile = UserProfileData.fromJson(
      rows.first,
      fallbackUserId: normalizedId,
    );
    return profile.isPublic ? profile : null;
  }

  Future<List<UserMediaItem>> loadPublicUserLibrary(
    String targetUserId, {
    String? listType,
  }) async {
    final normalizedId = targetUserId.trim();
    if (normalizedId.isEmpty) return const <UserMediaItem>[];
    final rows = await api.selectRows(
      'user_media_items',
      equals: <String, dynamic>{
        'user_id': normalizedId,
        if (listType != null) 'list_type': listType,
      },
    );
    return rows.map(UserMediaItem.fromJson).toList(growable: false);
  }

  Future<void> saveProfile(UserProfileData profile) async {
    await api.upsertRow('profiles', profile.toJson(), onConflict: 'user_id');
  }

  Future<UserProfileData> updateFavoriteTitles(List<String> titles) async {
    final profile = await loadProfile();
    final updated = profile.copyWith(
      favoriteTitles: List<String>.unmodifiable(titles),
    );
    await saveProfile(updated);
    return updated;
  }

  Future<void> deleteProfile() async {
    await api.deleteRows(
      'profiles',
      equals: <String, dynamic>{'user_id': userId},
    );
  }

  static String favoriteKey(String mediaType, int mediaId) =>
      '${mediaType.toLowerCase()}:$mediaId';

  static String favoriteLabel(String key) {
    final separator = key.indexOf(':');
    if (separator < 0) return key;
    return '${key.substring(0, separator).toUpperCase()} ${key.substring(separator + 1)}';
  }
}

final profileRepositoryProvider = Provider<ProfileRepository?>((ref) {
  final session = ref.watch(authControllerProvider).valueOrNull;
  if (session == null) return null;
  return ProfileRepository(
    api: ref.watch(supabaseRestApiProvider),
    userId: session.user.id,
  );
});

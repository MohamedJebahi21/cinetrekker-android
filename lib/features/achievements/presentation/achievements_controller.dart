import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/tmdb_api_service.dart';
import '../../../core/errors/app_error_messages.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/models/media_models.dart';
import '../../watchlist/data/user_library_repository.dart';

enum AchievementTier { bronze, silver, gold, platinum }

class AchievementItem {
  const AchievementItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.unlocked,
    required this.tier,
    this.unlockedAt,
    this.progress,
    this.target,
  });

  final String id;
  final String title;
  final String description;
  final String icon;
  final bool unlocked;
  final String? unlockedAt;
  final int? progress;
  final int? target;
  final AchievementTier tier;
}

class AchievementsState {
  const AchievementsState({
    required this.achievements,
    required this.total,
    required this.unlocked,
    required this.percentage,
    required this.isLoading,
    required this.error,
  });

  factory AchievementsState.initial() {
    return const AchievementsState(
      achievements: <AchievementItem>[],
      total: 0,
      unlocked: 0,
      percentage: 0,
      isLoading: false,
      error: null,
    );
  }

  final List<AchievementItem> achievements;
  final int total;
  final int unlocked;
  final int percentage;
  final bool isLoading;
  final String? error;

  AchievementsState copyWith({
    List<AchievementItem>? achievements,
    int? total,
    int? unlocked,
    int? percentage,
    bool? isLoading,
    String? error,
  }) {
    return AchievementsState(
      achievements: achievements ?? this.achievements,
      total: total ?? this.total,
      unlocked: unlocked ?? this.unlocked,
      percentage: percentage ?? this.percentage,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final achievementsControllerProvider =
    NotifierProvider<AchievementsController, AchievementsState>(
      AchievementsController.new,
    );

class AchievementsController extends Notifier<AchievementsState> {
  @override
  AchievementsState build() {
    return AchievementsState.initial();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repository = ref.read(userLibraryRepositoryProvider);
      final tmdb = ref.read(tmdbApiServiceProvider);
      final language = ref.read(tmdbLanguageProvider);
      final results = await Future.wait([
        repository.getWatched(),
        repository.getWatchlist(),
      ]);

      final watched = results[0];
      final watchlist = results[1];
      final achievements = await _calculateAchievements(
        watched: watched,
        watchlist: watchlist,
        tmdb: tmdb,
        language: language,
      );

      final total = achievements.length;
      final unlocked = achievements
          .where((achievement) => achievement.unlocked)
          .length;
      final percentage = total > 0 ? ((unlocked / total) * 100).round() : 0;

      state = AchievementsState(
        achievements: achievements,
        total: total,
        unlocked: unlocked,
        percentage: percentage,
        isLoading: false,
        error: null,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: describeAppError(error));
    }
  }

  Future<List<AchievementItem>> _calculateAchievements({
    required List<UserMediaItem> watched,
    required List<UserMediaItem> watchlist,
    required TmdbApiService tmdb,
    required String language,
  }) async {
    final achievements = <AchievementItem>[];

    achievements.add(
      AchievementItem(
        id: 'first-watch',
        title: 'First Steps',
        description: 'Watch your first movie or show',
        icon: '🎬',
        unlocked: watched.isNotEmpty,
        unlockedAt: watched.isNotEmpty ? watched.first.addedAt : null,
        tier: AchievementTier.bronze,
      ),
    );

    final milestones =
        <({int count, String title, String description, AchievementTier tier})>[
          (
            count: 10,
            title: 'Getting Started',
            description: 'Watch 10 titles',
            tier: AchievementTier.bronze,
          ),
          (
            count: 50,
            title: 'Enthusiast',
            description: 'Watch 50 titles',
            tier: AchievementTier.silver,
          ),
          (
            count: 100,
            title: 'Cinephile',
            description: 'Watch 100 titles',
            tier: AchievementTier.gold,
          ),
          (
            count: 250,
            title: 'Movie Buff',
            description: 'Watch 250 titles',
            tier: AchievementTier.platinum,
          ),
          (
            count: 500,
            title: 'Legend',
            description: 'Watch 500 titles',
            tier: AchievementTier.platinum,
          ),
        ];

    for (final milestone in milestones) {
      achievements.add(
        AchievementItem(
          id: 'watch-${milestone.count}',
          title: milestone.title,
          description: milestone.description,
          icon: '⭐',
          unlocked: watched.length >= milestone.count,
          progress: watched.length.clamp(0, milestone.count).toInt(),
          target: milestone.count,
          tier: milestone.tier,
        ),
      );
    }

    final genreCounts = <int, int>{};
    if (watched.isNotEmpty) {
      final details = await Future.wait(
        watched
            .take(10)
            .map(
              (item) => tmdb.details(
                mediaType: item.mediaType,
                mediaId: item.mediaId,
                language: language,
              ),
            ),
      );
      for (final detail in details) {
        for (final genre in detail.genres) {
          genreCounts.update(genre.id, (value) => value + 1, ifAbsent: () => 1);
        }
      }
    }
    final maxGenreCount = genreCounts.values.isEmpty
        ? 0
        : genreCounts.values.reduce((a, b) => a > b ? a : b);

    achievements.add(
      AchievementItem(
        id: 'genre-explorer',
        title: 'Genre Explorer',
        description: 'Watch 10 titles from the same genre',
        icon: '🎭',
        unlocked: maxGenreCount >= 10,
        progress: maxGenreCount.clamp(0, 10).toInt(),
        target: 10,
        tier: AchievementTier.silver,
      ),
    );

    final watchesByDate = <String, int>{};
    for (final item in watched) {
      final date = (item.watchedAt ?? item.addedAt).split('T').first;
      if (date.isEmpty) continue;
      watchesByDate.update(date, (value) => value + 1, ifAbsent: () => 1);
    }
    final maxInOneDay = watchesByDate.values.isEmpty
        ? 0
        : watchesByDate.values.reduce((a, b) => a > b ? a : b);

    achievements.add(
      AchievementItem(
        id: 'marathon',
        title: 'Marathon Master',
        description: 'Watch 5 titles in one day',
        icon: '🏃',
        unlocked: maxInOneDay >= 5,
        progress: maxInOneDay.clamp(0, 5).toInt(),
        target: 5,
        tier: AchievementTier.gold,
      ),
    );

    final ratedCount = watched.where((item) => item.rating != null).length;
    achievements.add(
      AchievementItem(
        id: 'rated-100',
        title: 'Critic',
        description: 'Rate 100 titles',
        icon: '⭐',
        unlocked: ratedCount >= 100,
        progress: ratedCount.clamp(0, 100).toInt(),
        target: 100,
        tier: AchievementTier.gold,
      ),
    );

    achievements.add(
      AchievementItem(
        id: 'watchlist-builder',
        title: 'Watchlist Builder',
        description: 'Add 50 titles to your watchlist',
        icon: '📋',
        unlocked: watchlist.length >= 50,
        progress: watchlist.length.clamp(0, 50).toInt(),
        target: 50,
        tier: AchievementTier.silver,
      ),
    );

    achievements.add(
      AchievementItem(
        id: 'perfect-score',
        title: 'Perfect 10',
        description: 'Give a title a 10/10 rating',
        icon: '💯',
        unlocked: watched.any((item) => item.rating == 10),
        tier: AchievementTier.bronze,
      ),
    );

    achievements.sort((a, b) {
      if (a.unlocked != b.unlocked) {
        return a.unlocked ? -1 : 1;
      }
      return 0;
    });

    return achievements;
  }
}

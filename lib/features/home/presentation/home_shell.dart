import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/media_models.dart';
import '../../../core/errors/app_error_messages.dart';
import '../../../core/motion/haptic_service.dart';
import '../../../shared/widgets/animated_content_switcher.dart';
import '../../../shared/widgets/bouncy_pressable.dart';
import '../../../shared/widgets/skeleton_loaders.dart';
import '../../../shared/widgets/app_cached_image.dart';
import '../../tv_tracking/presentation/tv_tracking_controller.dart';
import '../../watchlist/presentation/watchlist_controller.dart';
import 'home_controller.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  String _trendingWindow = 'week'; // 'day' | 'week'

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeControllerProvider);
    final l10n = ref.watch(appLocalizationsProvider);
    final authState = ref.watch(authControllerProvider);
    final user = authState.valueOrNull?.user;
    final theme = Theme.of(context);

    return AnimatedContentSwitcher(
      child: state.when(
        loading: () => CustomScrollView(
          key: const ValueKey('home-loading'),
          physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Hero skeleton
          SliverToBoxAdapter(
            child: Container(
              height: 420,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Center(
                child: AppSkeletonBox(
                  width: double.infinity,
                  height: 420,
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ),
          ),
          for (var i = 0; i < 4; i++)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: const SliverToBoxAdapter(child: PosterRailSkeleton()),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
      error: (error, _) => Center(
        key: const ValueKey('home-error'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                describeAppError(error),
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(fontSize: 14),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.read(homeControllerProvider.notifier).refresh(),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
      data: (feed) {
        final trendingItems = _trendingWindow == 'day'
            ? feed.trendingDay
            : feed.trendingWeek;

        return RefreshIndicator(
          key: const ValueKey('home-data'),
          color: theme.colorScheme.primary,
          onRefresh: ref.read(homeControllerProvider.notifier).refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. Mobile Hero Carousel matching website
              SliverToBoxAdapter(
                child: _HomeHero(
                  items: feed.trendingWeek
                      .where((m) => m.backdropPath != null)
                      .take(5)
                      .toList(),
                  onItemTap: (item) =>
                      context.push('/details/${item.mediaKind}/${item.id}'),
                ),
              ),

              // 2. Continue Watching (Always present matching website)
              SliverToBoxAdapter(
                child: _ContinueWatchingSection(
                  items: feed.continueWatching,
                  onItemTap: (item) => context.push('/details/tv/${item.id}'),
                ),
              ),

              // 3. Trending Section with Day / Week Toggle
              SliverToBoxAdapter(
                child: _SectionContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Trending',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          // Day / Week toggle group
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondary,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant,
                              ),
                            ),
                            child: Row(
                              children: [
                                _ToggleChip(
                                  label: 'Today',
                                  isActive: _trendingWindow == 'day',
                                  onTap: () =>
                                      setState(() => _trendingWindow = 'day'),
                                ),
                                _ToggleChip(
                                  label: 'This Week',
                                  isActive: _trendingWindow == 'week',
                                  onTap: () =>
                                      setState(() => _trendingWindow = 'week'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _HorizontalPosterRail(
                        items: trendingItems,
                        onTap: (item, heroTag) => context.push(
                          '/details/${item.mediaKind}/${item.id}?heroTag=${Uri.encodeComponent(heroTag)}',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. In Theaters / Now Playing
              if (feed.nowPlaying.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _SectionContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeaderWithAction(
                          title: l10n.translate('in_theaters'),
                          actionLabel: 'See all',
                          onAction: () => context.push('/calendar'),
                        ),
                        const SizedBox(height: 12),
                        _HorizontalPosterRail(
                          items: feed.nowPlaying,
                          onTap: (item, heroTag) => context.push(
                            '/details/${item.mediaKind}/${item.id}?heroTag=${Uri.encodeComponent(heroTag)}',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // 5. Watchlist Preview / Taste Matched
              if (feed.watchlistPreview.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _SectionContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeaderWithAction(
                          title: 'From Your Watchlist',
                          actionLabel: 'View list',
                          onAction: () => context.go('/watchlist'),
                        ),
                        const SizedBox(height: 12),
                        _HorizontalPosterRail(
                          items: feed.watchlistPreview,
                          onTap: (item, heroTag) => context.push(
                            '/details/${item.mediaKind}/${item.id}?heroTag=${Uri.encodeComponent(heroTag)}',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // 6. Popular in Genre Suggestions
              if (feed.genreSuggestions.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _SectionContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeaderWithAction(
                          title: 'Popular in ${feed.genreName ?? 'Top Genres'}',
                          actionLabel: 'Genres',
                          onAction: () => context.push('/genres'),
                        ),
                        const SizedBox(height: 12),
                        _HorizontalPosterRail(
                          items: feed.genreSuggestions,
                          onTap: (item, heroTag) => context.push(
                            '/details/${item.mediaKind}/${item.id}?heroTag=${Uri.encodeComponent(heroTag)}',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // 7. Quest Hub / Milestone banner matching website
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: _QuestBanner(user: user),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Container with padding
// ─────────────────────────────────────────────────────────────────────────────

class _SectionContainer extends StatelessWidget {
  const _SectionContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: child,
    );
  }
}

class _SectionHeaderWithAction extends StatelessWidget {
  const _SectionHeaderWithAction({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: theme.colorScheme.onSurface,
          ),
        ),
        BouncyPressable(
          onTap: onAction,
          child: Text(
            actionLabel,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BouncyPressable(
      onTap: () {
        Haptics.tabSwitch();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? theme.cardTheme.color : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isActive
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }
}

class _ContinueWatchingSection extends StatelessWidget {
  const _ContinueWatchingSection({
    required this.items,
    required this.onItemTap,
  });

  final List<TmdbMedia> items;
  final void Function(TmdbMedia item) onItemTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return _SectionContainer(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1E1418), theme.colorScheme.surface]
                : [
                    theme.colorScheme.surface,
                    theme.colorScheme.surfaceContainerLowest,
                  ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with red Play icon, Title, and TV Tracker button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.play_circle_fill_rounded,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              'Continue Watching',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Pick up the next released episode without hunting through your library.',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (items.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.25,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    color: theme.colorScheme.primary,
                                    size: 11,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${items.length} ready to resume',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () => context.push('/tv-tracking'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'TV Tracker',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Content: Active Cards OR Empty State Panel
            if (items.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    style: BorderStyle.solid,
                  ),
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.02),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.25,
                          ),
                        ),
                      ),
                      child: Icon(
                        Icons.tv_rounded,
                        color: theme.colorScheme.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Nothing to continue yet',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Once you start a series, the next episode will appear here for fast access.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () => context.push('/search'),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.search_rounded, size: 15),
                      label: Text(
                        'Find a show to start',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 250,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _ContinueWatchingCard(
                      item: item,
                      onTap: () => onItemTap(item),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ContinueWatchingCard extends ConsumerWidget {
  const _ContinueWatchingCard({required this.item, required this.onTap});

  final TmdbMedia item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backdropUrl = item.backdropPath != null
        ? 'https://image.tmdb.org/t/p/w780${item.backdropPath}'
        : (item.posterPath != null
              ? 'https://image.tmdb.org/t/p/w500${item.posterPath}'
              : null);

    final tvState = ref.watch(tvTrackingControllerProvider);
    final followed = tvState.followedShows
        .where((s) => s.showId == item.id)
        .firstOrNull;
    final watchedList =
        tvState.watchedEpisodes.where((ep) => ep.showId == item.id).toList()
          ..sort((a, b) {
            final aWatchedAt =
                DateTime.tryParse(a.watchedAt ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final bWatchedAt =
                DateTime.tryParse(b.watchedAt ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return bWatchedAt.compareTo(aWatchedAt);
          });

    String nextEpisodeLabel = 'Tap to resume episode';
    double progressValue = 0.35;

    if (followed?.lastWatchedSeason != null &&
        followed?.lastWatchedEpisode != null) {
      final s = followed!.lastWatchedSeason!;
      final e = followed.lastWatchedEpisode! + 1;
      nextEpisodeLabel = 'Season $s · Episode $e';
      progressValue =
          ((followed.lastWatchedEpisode ?? 1) /
                  ((followed.lastWatchedEpisode ?? 1) + 4))
              .clamp(0.15, 0.95);
    } else if (watchedList.isNotEmpty) {
      final lastWatched = watchedList.first;
      nextEpisodeLabel =
          'Season ${lastWatched.seasonNumber} · Episode ${lastWatched.episodeNumber + 1}';
      progressValue = (watchedList.length / (watchedList.length + 3)).clamp(
        0.15,
        0.95,
      );
    }

    return BouncyPressable(
      onTap: onTap,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Thumbnail with dark gradient & progress chip
              Stack(
                children: [
                  SizedBox(
                    height: 100,
                    width: double.infinity,
                    child: backdropUrl != null
                        ? AppCachedImage(
                            imageUrl: backdropUrl,
                            fit: BoxFit.cover,
                            errorIcon: Icons.tv_outlined,
                          )
                        : Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.tv_outlined),
                          ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.65),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        'Next Up',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Title and details
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'TV Series',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Compact next-episode cue. This avoids a decorative
                    // stripe while keeping the resume action visually clear.
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.09,
                        ),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_arrow_rounded,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              nextEpisodeLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progressValue,
                        minHeight: 3,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Horizontal Poster Rail matching website MediaCard
// ─────────────────────────────────────────────────────────────────────────────

class _HorizontalPosterRail extends StatelessWidget {
  const _HorizontalPosterRail({required this.items, required this.onTap});

  final List<TmdbMedia> items;
  final void Function(TmdbMedia item, String heroTag) onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: 236,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          final heroTag = 'home-poster-${item.mediaKind}-${item.id}-$index';
          final posterUrl = item.posterPath != null
              ? 'https://image.tmdb.org/t/p/w342${item.posterPath}'
              : null;

          return BouncyPressable(
            onTap: () => onTap(item, heroTag),
            child: SizedBox(
              width: 130,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poster with glass border & rating chip
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.6,
                        ),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.28 : 0.06,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (posterUrl != null)
                            Hero(
                              tag: heroTag,
                              child: AppCachedImage(
                                imageUrl: posterUrl,
                                fit: BoxFit.cover,
                                errorIcon: Icons.movie_outlined,
                              ),
                            )
                          else
                            Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.movie_outlined),
                            ),
                          // Rating Badge on top right
                          if (item.voteAverage > 0)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.15),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Color(0xFFFFC107),
                                      size: 11,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      item.voteAverage.toStringAsFixed(1),
                                      style: GoogleFonts.dmSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Title
                  Text(
                    item.displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  // Year & Type
                  Text(
                    [
                      item.year,
                      item.mediaKind == 'tv' ? 'TV' : 'Movie',
                    ].whereType<String>().join(' · '),
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.50,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Home Hero Section (Mobile layout with auto-rotation & spotlight info card)
// ─────────────────────────────────────────────────────────────────────────────

class _HomeHero extends ConsumerStatefulWidget {
  const _HomeHero({required this.items, required this.onItemTap});

  final List<TmdbMedia> items;
  final void Function(TmdbMedia item) onItemTap;

  @override
  ConsumerState<_HomeHero> createState() => _HomeHeroState();
}

class _HomeHeroState extends ConsumerState<_HomeHero> {
  int _currentIndex = 0;
  Timer? _timer;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.items.isNotEmpty) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || widget.items.isEmpty) return;
      final next = (_currentIndex + 1) % widget.items.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final item = widget.items[_currentIndex];
    final watchlistState = ref.watch(watchlistControllerProvider);
    final isInWatchlist = watchlistState.isInWatchlist(item.id, item.mediaKind);

    return Column(
      children: [
        // Backdrop Image Slider
        SizedBox(
          height: 250,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: widget.items.length,
                onPageChanged: (idx) {
                  setState(() => _currentIndex = idx);
                  _startTimer();
                },
                itemBuilder: (context, idx) {
                  final m = widget.items[idx];
                  return GestureDetector(
                    onTap: () => widget.onItemTap(m),
                    child: AppCachedImage(
                      imageUrl:
                          'https://image.tmdb.org/t/p/w780${m.backdropPath}',
                      fit: BoxFit.cover,
                      errorIcon: Icons.movie_outlined,
                    ),
                  );
                },
              ),
              // Gradient overlays
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.transparent,
                        theme.scaffoldBackgroundColor,
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),
              // Slide indicator bars at bottom of image
              Positioned(
                bottom: 8,
                left: 20,
                right: 20,
                child: Row(
                  children: List.generate(widget.items.length, (idx) {
                    final isActive = idx == _currentIndex;
                    return Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: isActive
                              ? theme.colorScheme.primary
                              : Colors.white.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),

        // Mobile Hero Card (.ct-hero-mobile-card style)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Meta row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.14,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Weekly Spotlight',
                        style: GoogleFonts.dmSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.mediaKind == 'tv' ? 'TV Series' : 'Movie',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.55,
                        ),
                      ),
                    ),
                    if (item.year != null) ...[
                      Text(
                        ' · ${item.year}',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.55,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (item.voteAverage > 0)
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFC107),
                            size: 15,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            item.voteAverage.toStringAsFixed(1),
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Title
                Text(
                  item.displayTitle,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (item.overview != null && item.overview!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.overview!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 12.5,
                      height: 1.5,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.65,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () => widget.onItemTap(item),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 42),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Details',
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    BouncyPressable(
                      onTap: () {
                        ref
                            .read(watchlistControllerProvider.notifier)
                            .toggleWatchlist(
                              mediaId: item.id,
                              mediaType: item.mediaKind,
                              title: item.displayTitle,
                              posterPath: item.posterPath,
                              backdropPath: item.backdropPath,
                              voteAverage: item.voteAverage,
                              releaseDate:
                                  item.releaseDate ?? item.firstAirDate,
                            );
                      },
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isInWatchlist
                              ? theme.colorScheme.primary.withValues(
                                  alpha: 0.15,
                                )
                              : theme.colorScheme.secondary,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isInWatchlist
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: Icon(
                          isInWatchlist
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          size: 18,
                          color: isInWatchlist
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quest / Milestone Hub Banner
// ─────────────────────────────────────────────────────────────────────────────

class _QuestBanner extends StatelessWidget {
  const _QuestBanner({required this.user});

  final dynamic user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFFD700).withValues(alpha: 0.4),
              ),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFFFFB300),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CineQuests & Trophies',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Complete monthly challenges and level up your rank.',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: () => context.push('/achievements'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Explore',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

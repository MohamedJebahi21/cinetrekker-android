import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/models/media_models.dart';
import '../../../shared/widgets/app_error_card.dart';
import '../../../shared/widgets/bouncy_pressable.dart';
import '../../../shared/widgets/app_cached_image.dart';
import 'tv_tracking_controller.dart';

class TvTrackingScreen extends ConsumerStatefulWidget {
  const TvTrackingScreen({super.key});

  @override
  ConsumerState<TvTrackingScreen> createState() => _TvTrackingScreenState();
}

class _TvTrackingScreenState extends ConsumerState<TvTrackingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tvTrackingControllerProvider.notifier).load();
    });
  }

  BoxDecoration _glassCard(ThemeData theme, bool isDark) {
    return BoxDecoration(
      color: theme.cardTheme.color ?? theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  void _showAiringScheduleDialog(
    BuildContext ctx,
    List<FollowedShowItem> shows,
  ) {
    // Filter only shows with a nextAirDate and sort ascending
    final upcoming =
        shows.where((s) => s.nextAirDate != null).toList()
          ..sort((a, b) => a.nextAirDate!.compareTo(b.nextAirDate!));

    showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AiringScheduleSheet(shows: upcoming),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tvTrackingControllerProvider);
    final session = ref.watch(authControllerProvider).valueOrNull;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'TV Tracking',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Airing Schedule',
            onPressed: () => _showAiringScheduleDialog(context, state.followedShows),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: theme.colorScheme.primary,
        onRefresh: () => ref.read(tvTrackingControllerProvider.notifier).load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (session == null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _glassCard(theme, isDark),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.cloud_sync_outlined,
                        color: theme.colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Guest Mode (Local Storage)',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tracking progress on this device. Sign in anytime to sync with web.',
                            style: GoogleFonts.dmSans(
                              fontSize: 12.5,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.60,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.tonal(
                      onPressed: () => context.push('/login'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text(
                        'Sign in',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            if (session == null) const SizedBox(height: 16),
            if (state.error != null)
              AppErrorCard(
                message: state.error!,
                onRetry: () =>
                    ref.read(tvTrackingControllerProvider.notifier).load(),
              ),
            if (state.isLoading)
              LinearProgressIndicator(
                color: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.15,
                ),
              ),
            const SizedBox(height: 12),

            _SectionHeader(
              title: 'Continue Watching',
              subtitle: 'Active TV shows you have started watching.',
            ),
            const SizedBox(height: 12),
            if (state.continueWatching.isEmpty)
              const _EmptyCopy(
                text:
                    'No active TV progress yet. Follow a show from the details page to track episodes.',
              )
            else
              ...state.continueWatching.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ContinueWatchingCard(item: item),
                ),
              ),
            const SizedBox(height: 24),

            _SectionHeader(
              title: 'Followed Shows',
              subtitle: 'TV titles tracked in your library queue.',
            ),
            const SizedBox(height: 12),
            if (state.followedShows.isEmpty)
              const _EmptyCopy(text: 'You are not following any shows yet.')
            else
              ...state.followedShows.map(
                (show) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _FollowedShowTile(
                    show: show,
                    onTap: () => context.push('/details/tv/${show.showId}'),
                    onUnfollow: () => ref
                        .read(tvTrackingControllerProvider.notifier)
                        .unfollowShow(showId: show.showId),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            _SectionHeader(
              title: 'Recent Episode History',
              subtitle: 'Latest logged TV episodes.',
            ),
            const SizedBox(height: 12),
            if (state.recentEpisodes.isEmpty)
              const _EmptyCopy(text: 'No episode watch history found.')
            else
              ...state.recentEpisodes.map(
                (episode) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RecentEpisodeTile(
                    episode: episode,
                    onTap: () => context.push('/details/tv/${episode.showId}'),
                  ),
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

class _EmptyCopy extends StatelessWidget {
  const _EmptyCopy({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: GoogleFonts.dmSans(
          fontSize: 13,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.50),
        ),
      ),
    );
  }
}

class _ContinueWatchingCard extends ConsumerWidget {
  const _ContinueWatchingCard({required this.item});

  final TvTrackingProgressItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final show = item.followedShow;

    final nextSeason = item.lastEpisode?.seasonNumber ?? 1;
    final nextEpisode = (item.lastEpisode?.episodeNumber ?? 0) + 1;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/details/tv/${show.showId}'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: show.posterPath != null
                            ? AppCachedImage(
                                imageUrl:
                                    'https://image.tmdb.org/t/p/w185${show.posterPath}',
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                child: const Icon(Icons.tv_outlined),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            show.showName ?? 'Show #${show.showId}',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Next: S$nextSeason E$nextEpisode',
                              style: GoogleFonts.dmSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.watchedEpisodeCount} episodes watched',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.55,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: () async {
                          await ref
                              .read(tvTrackingControllerProvider.notifier)
                              .markEpisodeWatched(
                                showId: show.showId,
                                seasonNumber: nextSeason,
                                episodeNumber: nextEpisode,
                                showName: show.showName,
                                posterPath: show.posterPath,
                              );
                        },
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Mark S$nextSeason E$nextEpisode Watched',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FollowedShowTile extends StatelessWidget {
  const _FollowedShowTile({
    required this.show,
    required this.onTap,
    required this.onUnfollow,
  });

  final FollowedShowItem show;
  final VoidCallback onTap;
  final VoidCallback onUnfollow;

  String _subtitleText() {
    final days = show.daysUntilAir();
    if (days == null) return 'Tracking updates enabled';
    if (days < 0) return 'Last episode aired ${-days}d ago';
    if (days == 0) return '🔴 Airing today!';
    if (days == 1) return '⏰ Airing tomorrow';
    return '📅 Airing in $days days';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final airingSoon = show.isAiringSoon();
    final days = show.daysUntilAir();
    final isToday = days == 0;

    return BouncyPressable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: airingSoon
                ? (isToday
                    ? const Color(0xFFFF5252)
                    : theme.colorScheme.primary)
                : theme.colorScheme.outlineVariant,
            width: airingSoon ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: ListTile(
            onTap: onTap,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: Container(
              width: 42,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: show.posterPath != null
                    ? AppCachedImage(
                        imageUrl:
                            'https://image.tmdb.org/t/p/w185${show.posterPath}',
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.tv_outlined, size: 20),
                      ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    show.showName ?? 'Show #${show.showId}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (airingSoon) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isToday
                          ? const Color(0xFFFF5252).withValues(alpha: 0.15)
                          : theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isToday ? 'TODAY' : 'SOON',
                      style: GoogleFonts.dmSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: isToday
                            ? const Color(0xFFFF5252)
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Text(
              _subtitleText(),
              style: GoogleFonts.dmSans(
                fontSize: 11.5,
                color: airingSoon
                    ? (isToday
                        ? const Color(0xFFFF5252)
                        : theme.colorScheme.primary)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.55),
                fontWeight:
                    airingSoon ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.bookmark_remove_outlined,
                size: 20,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
              onPressed: onUnfollow,
              tooltip: 'Unfollow',
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentEpisodeTile extends StatelessWidget {
  const _RecentEpisodeTile({required this.episode, this.onTap});

  final WatchedEpisodeItem episode;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final content = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF4CAF50),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  episode.episodeName != null && episode.episodeName!.isNotEmpty
                      ? episode.episodeName!
                      : 'Show #${episode.showId}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Season ${episode.seasonNumber}, Episode ${episode.episodeNumber}',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
            ),
        ],
      ),
    );

    if (onTap != null) {
      return BouncyPressable(
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }
}

// ---------------------------------------------------------------------------
// Airing Schedule Bottom Sheet
// ---------------------------------------------------------------------------

class _AiringScheduleSheet extends StatelessWidget {
  const _AiringScheduleSheet({required this.shows});

  final List<FollowedShowItem> shows;

  String _formatDate(String isoDate) {
    final d = DateTime.tryParse(isoDate);
    if (d == null) return isoDate;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1C1C1E)
              : theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Upcoming Air Dates',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  shows.isEmpty
                      ? 'No upcoming air dates found for your followed shows.'
                      : '${shows.length} show${shows.length == 1 ? '' : 's'} with scheduled episodes',
                  style: GoogleFonts.dmSans(
                    fontSize: 12.5,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (shows.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.event_available_outlined,
                        size: 48,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No upcoming episodes',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  itemCount: shows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final show = shows[i];
                    final days = show.daysUntilAir();
                    final isToday = days == 0;
                    final isSoon = show.isAiringSoon();

                    String daysLabel;
                    if (days == null) {
                      daysLabel = '';
                    } else if (days < 0) {
                      daysLabel = '${-days}d ago';
                    } else if (days == 0) {
                      daysLabel = 'Today';
                    } else if (days == 1) {
                      daysLabel = 'Tomorrow';
                    } else {
                      daysLabel = 'In $days days';
                    }

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5)
                            : theme.colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSoon
                              ? (isToday
                                  ? const Color(0xFFFF5252).withValues(alpha: 0.5)
                                  : theme.colorScheme.primary.withValues(alpha: 0.4))
                              : theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 48,
                            child: Center(
                              child: Text(
                                isToday ? '🔴' : (isSoon ? '⏰' : '📅'),
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  show.showName ?? 'Show #${show.showId}',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                if (show.nextEpisodeName != null &&
                                    show.nextEpisodeName!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    show.nextEpisodeName!,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.65),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 2),
                                Text(
                                  _formatDate(show.nextAirDate!),
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (daysLabel.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isToday
                                    ? const Color(0xFFFF5252).withValues(alpha: 0.12)
                                    : (isSoon
                                        ? theme.colorScheme.primary
                                            .withValues(alpha: 0.10)
                                        : theme.colorScheme.onSurface
                                            .withValues(alpha: 0.06)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                daysLabel,
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isToday
                                      ? const Color(0xFFFF5252)
                                      : (isSoon
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurface
                                              .withValues(alpha: 0.5)),
                                ),
                              ),
                            ),
                        ],
                      ),
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

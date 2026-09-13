import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/tmdb_api_service.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/models/media_models.dart';
import '../../../core/motion/haptic_service.dart';
import '../../../shared/widgets/app_cached_image.dart';
import '../../../shared/widgets/app_error_card.dart';
import '../../../shared/widgets/bouncy_pressable.dart';
import '../../profile/presentation/profile_controller.dart';
import '../../social/presentation/comments_controller.dart';
import '../../tv_tracking/presentation/tv_tracking_controller.dart';
import '../../watchlist/presentation/watchlist_controller.dart';
import '../../../shared/widgets/skeleton_loaders.dart';
import 'details_controller.dart';

class DetailsScreen extends ConsumerStatefulWidget {
  const DetailsScreen({
    super.key,
    required this.mediaType,
    required this.mediaId,
    this.heroTag,
  });

  final String mediaType;
  final int mediaId;
  final String? heroTag;

  @override
  ConsumerState<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends ConsumerState<DetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileControllerProvider.notifier).load();
      ref.read(tvTrackingControllerProvider.notifier).load();
      ref
          .read(detailsControllerProvider.notifier)
          .load(
            mediaType: widget.mediaType,
            mediaId: widget.mediaId,
            language: ref.read(tmdbLanguageProvider),
          );
      ref
          .read(commentsControllerProvider.notifier)
          .load(mediaType: widget.mediaType, mediaId: widget.mediaId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(detailsControllerProvider);
    final theme = Theme.of(context);

    ref.listen<String>(tmdbLanguageProvider, (previous, next) {
      if (previous == null || previous == next) return;
      ref
          .read(detailsControllerProvider.notifier)
          .load(
            mediaType: widget.mediaType,
            mediaId: widget.mediaId,
            language: next,
          );
      ref
          .read(commentsControllerProvider.notifier)
          .load(mediaType: widget.mediaType, mediaId: widget.mediaId);
    });

    final trailer = state.details?.videos
        .where(
          (v) =>
              v.site.toLowerCase() == 'youtube' &&
              (v.type == 'Trailer' || v.type == 'Teaser'),
        )
        .firstOrNull;

    return Scaffold(
      body: RefreshIndicator(
        color: theme.colorScheme.primary,
        onRefresh: () async {
          await ref
              .read(detailsControllerProvider.notifier)
              .refresh(
                mediaType: widget.mediaType,
                mediaId: widget.mediaId,
                language: ref.read(tmdbLanguageProvider),
              );
          await ref
              .read(commentsControllerProvider.notifier)
              .load(mediaType: widget.mediaType, mediaId: widget.mediaId);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Sliver App Bar with Backdrop
            SliverAppBar(
              pinned: true,
              expandedHeight: math
                  .min(MediaQuery.sizeOf(context).width * 0.58, 360.0)
                  .clamp(240.0, 360.0),
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.share_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () {
                      if (state.details != null) {
                        _showShareModal(context, state.details!, widget.mediaType);
                      }
                    },
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    _Backdrop(details: state.details),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.4),
                            Colors.transparent,
                            theme.scaffoldBackgroundColor,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                    if (trailer != null)
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: FilledButton.icon(
                          onPressed: () => _openTrailer(trailer.key),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.black.withValues(
                              alpha: 0.75,
                            ),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                          icon: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.redAccent,
                            size: 18,
                          ),
                          label: Text(
                            'Watch Trailer',
                            style: GoogleFonts.dmSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            if (state.isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: DetailsHeaderSkeleton(),
                ),
              )
            else if (state.error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: AppErrorCard(
                    message: state.error!,
                    onRetry: () => ref
                        .read(detailsControllerProvider.notifier)
                        .load(
                          mediaType: widget.mediaType,
                          mediaId: widget.mediaId,
                        ),
                  ),
                ),
              )
            else if (state.details != null)
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Poster + Title + ScoreRing + Status
                        _DetailsHeader(
                          details: state.details!,
                          heroTag: widget.heroTag,
                        ),
                        const SizedBox(height: 16),

                        // 2. Action Bar (Watchlist, Watched Dialog, Favorite)
                        _ActionBar(
                          mediaType: widget.mediaType,
                          mediaId: widget.mediaId,
                          details: state.details!,
                        ),
                        const SizedBox(height: 16),

                        // 3. Overview & Tagline
                        if (state.details!.tagline != null &&
                            state.details!.tagline!.isNotEmpty) ...[
                          Text(
                            '"${state.details!.tagline!}"',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if ((state.details!.overview ?? '').isNotEmpty)
                          Text(
                            state.details!.overview!,
                            style: GoogleFonts.dmSans(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.8,
                              ),
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),
                        const SizedBox(height: 20),

                        // 4. Where to Watch / Streaming Badges
                        if (state.details!.watchProviders != null &&
                            !state.details!.watchProviders!.isEmpty) ...[
                          _WhereToWatchSection(
                            providers: state.details!.watchProviders!,
                          ),
                          const SizedBox(height: 20),
                        ],

                        // 5. TV Episode Accordion Tracker (if TV show)
                        if (widget.mediaType == 'tv') ...[
                          _TvSeasonAccordion(
                            tvId: widget.mediaId,
                            details: state.details!,
                          ),
                          const SizedBox(height: 20),
                        ],

                        // 6. Cast & Crew Horizontal Rail
                        if (state.details!.cast.isNotEmpty) ...[
                          _CastRail(cast: state.details!.cast),
                          const SizedBox(height: 20),
                        ],
                      ],
                    ),
                  ),

                  // 7. Recommended Titles Rail
                  if (state.recommendations.isNotEmpty)
                    _MediaRail(
                      title: 'Recommended',
                      items: state.recommendations,
                      onTap: (item, heroTag) => context.push(
                        '/details/${item.mediaKind}/${item.id}?heroTag=${Uri.encodeComponent(heroTag)}',
                      ),
                    ),

                  // 8. Similar Titles Rail
                  if (state.similar.isNotEmpty)
                    _MediaRail(
                      title: 'Similar titles',
                      items: state.similar,
                      onTap: (item, heroTag) => context.push(
                        '/details/${item.mediaKind}/${item.id}?heroTag=${Uri.encodeComponent(heroTag)}',
                      ),
                    ),

                  const SizedBox(height: 20),

                  // 9. Community Comments / Reviews
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _CommentsSection(
                      mediaType: widget.mediaType,
                      mediaId: widget.mediaId,
                    ),
                  ),
                  const SizedBox(height: 40),
                ]),
              )
            else
              const SliverToBoxAdapter(child: SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  void _openTrailer(String key) async {
    final videoKey = key.trim();
    if (videoKey.isEmpty) {
      _showTrailerLaunchError();
      return;
    }

    try {
      // `canLaunchUrl` is intentionally avoided here. On Android 11+ it can
      // return false when the app does not declare every possible browser or
      // video handler in package visibility queries, even though launch works.
      final appUri = Uri.https('youtu.be', '/$videoKey');
      final launchedExternally = await launchUrl(
        appUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launchedExternally) {
        final browserUri = Uri.https(
          'www.youtube.com',
          '/watch',
          <String, String>{'v': videoKey},
        );
        final launchedInBrowser = await launchUrl(
          browserUri,
          mode: LaunchMode.platformDefault,
        );
        if (!launchedInBrowser) {
          _showTrailerLaunchError();
        }
      }
    } catch (_) {
      _showTrailerLaunchError();
    }
  }

  void _showTrailerLaunchError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('We couldn’t open this trailer. Please try again.'),
        duration: Duration(seconds: 3),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Details Header (Poster + Title + ScoreRing + Meta Chips)
// ─────────────────────────────────────────────────────────────────────────────

class _DetailsHeader extends StatelessWidget {
  const _DetailsHeader({required this.details, this.heroTag});

  final TmdbMediaDetails details;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final imageWidget = AppCachedImage(
      imageUrl: details.posterPath == null
          ? ''
          : 'https://image.tmdb.org/t/p/w342${details.posterPath}',
      fit: BoxFit.cover,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Poster with glass border
        Container(
          width: 110,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.08),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 2 / 3,
              child: heroTag != null
                  ? Hero(tag: heroTag!, child: imageWidget)
                  : imageWidget,
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Metadata column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                details.displayTitle,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),

              // Year · Certification · Runtime
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (details.year != null)
                    Text(
                      '${details.year}',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.65,
                        ),
                      ),
                    ),
                  if (details.certification != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        details.certification!,
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (details.runtime != null && details.runtime! > 0)
                    Text(
                      '· ${details.runtime} min',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.65,
                        ),
                      ),
                    ),
                  if (details.numberOfSeasons != null &&
                      details.numberOfSeasons! > 0)
                    Text(
                      '· ${details.numberOfSeasons} Seasons',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.65,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Score Ring & Status Badge
              Wrap(
                spacing: 10,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _ScoreRing(score: details.voteAverage),
                  if (details.status != null && details.status!.isNotEmpty)
                    _StatusBadge(status: details.status!),
                ],
              ),
              const SizedBox(height: 8),

              // Genres chips
              if (details.genres.isNotEmpty)
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: details.genres.take(3).map((g) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Text(
                        g.name,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.75,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ScoreRing matching website's Circular Score Ring
// ─────────────────────────────────────────────────────────────────────────────

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score});

  final double score;
  static const _size = 46.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = score >= 7.0
        ? const Color(0xFF4CAF50)
        : (score >= 5.0 ? const Color(0xFFFFB300) : const Color(0xFFE53935));

    final percentage = (score / 10.0).clamp(0.0, 1.0);

    return BouncyPressable(
      onTap: () {
        showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.star_rounded, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Community Score',
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  score > 0
                      ? '${(score * 10).toStringAsFixed(0)}% Approval Rating'
                      : 'Not Rated Yet',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  score >= 7.0
                      ? 'Critically Acclaimed: Highly recommended by global film critics and TMDB community voters.'
                      : (score >= 5.0
                            ? 'Mixed to Positive Reception: Average community consensus.'
                            : 'Underwhelming Consensus: Lower audience reception score.'),
                  style: GoogleFonts.dmSans(
                    fontSize: 13.5,
                    height: 1.5,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
      child: SizedBox(
        width: _size,
        height: _size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(_size, _size),
              painter: _ScoreRingPainter(
                progress: percentage,
                color: color,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.10),
              ),
            ),
            Text(
              score > 0 ? score.toStringAsFixed(1) : 'NR',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  const _ScoreRingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  final double progress;
  final Color color;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 6) / 2;
    const strokeWidth = 3.5;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final fgPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, bgPaint);
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Badge with Colored Indicator Dot
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final lower = status.toLowerCase();

    Color dotColor = Colors.grey;
    if (lower.contains('returning') || lower.contains('released')) {
      dotColor = const Color(0xFF4CAF50);
    } else if (lower.contains('production') || lower.contains('planned')) {
      dotColor = const Color(0xFF2196F3);
    } else if (lower.contains('ended')) {
      dotColor = const Color(0xFF9E9E9E);
    } else if (lower.contains('cancel')) {
      dotColor = const Color(0xFFE53935);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: dotColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: dotColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: dotColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Bar (Watchlist, Watched Dialog, Favorite Toggle)
// ─────────────────────────────────────────────────────────────────────────────

class _ActionBar extends ConsumerWidget {
  const _ActionBar({
    required this.mediaType,
    required this.mediaId,
    required this.details,
  });

  final String mediaType;
  final int mediaId;
  final TmdbMediaDetails details;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    final watchlistState = ref.watch(watchlistControllerProvider);
    final isWatchlist = watchlistState.watchlist.any(
      (item) => item.mediaId == mediaId && item.mediaType == mediaType,
    );
    final isWatched = watchlistState.watched.any(
      (item) => item.mediaId == mediaId && item.mediaType == mediaType,
    );

    ref.watch(profileControllerProvider);
    final isFavorite = ref
        .read(profileControllerProvider.notifier)
        .isFavorite(mediaType: mediaType, mediaId: mediaId);

    return Container(
      padding: const EdgeInsets.all(12),
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
      child: Row(
        children: [
          // Watchlist Button
          Expanded(
            child: FilledButton.icon(
              onPressed: () {
                final messenger = ScaffoldMessenger.of(context);
                messenger.hideCurrentSnackBar();
                if (isWatchlist) {
                  Haptics.removeFromWatchlist();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Removed "${details.displayTitle}" from Watchlist'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  ref
                      .read(watchlistControllerProvider.notifier)
                      .removeFromWatchlist(
                        mediaId: mediaId,
                        mediaType: mediaType,
                      );
                } else {
                  Haptics.addToWatchlist();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Added "${details.displayTitle}" to Watchlist'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  ref
                      .read(watchlistControllerProvider.notifier)
                      .addToWatchlist(
                        mediaId: mediaId,
                        mediaType: mediaType,
                        title: details.displayTitle,
                        posterPath: details.posterPath,
                        backdropPath: details.backdropPath,
                        voteAverage: details.voteAverage,
                        releaseDate:
                            details.releaseDate ?? details.firstAirDate,
                      );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: isWatchlist
                    ? primary.withValues(alpha: 0.15)
                    : theme.colorScheme.secondary,
                foregroundColor: isWatchlist
                    ? primary
                    : theme.colorScheme.onSurface,
                elevation: 0,
                minimumSize: const Size(0, 42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isWatchlist
                        ? primary.withValues(alpha: 0.3)
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
              ),
              icon: Icon(
                isWatchlist
                    ? Icons.bookmark_added_rounded
                    : Icons.bookmark_add_outlined,
                size: 18,
              ),
              label: Text(
                isWatchlist ? 'Watchlist' : 'Add to list',
                style: GoogleFonts.dmSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Watched Status Button (with Dialog)
          Expanded(
            child: FilledButton.icon(
              onPressed: () {
                _showWatchedDialog(context, ref);
              },
              style: FilledButton.styleFrom(
                backgroundColor: isWatched
                    ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                    : theme.colorScheme.secondary,
                foregroundColor: isWatched
                    ? const Color(0xFF4CAF50)
                    : theme.colorScheme.onSurface,
                elevation: 0,
                minimumSize: const Size(0, 42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isWatched
                        ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
              ),
              icon: Icon(
                isWatched
                    ? Icons.check_circle_rounded
                    : Icons.check_circle_outline_rounded,
                size: 18,
              ),
              label: Text(
                isWatched ? 'Watched' : 'Mark seen',
                style: GoogleFonts.dmSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Favorite Heart Button with spring bounce
          BouncyPressable(
            onTap: () {
              final messenger = ScaffoldMessenger.of(context);
              messenger.hideCurrentSnackBar();
              if (isFavorite) {
                Haptics.unfavorite();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Removed "${details.displayTitle}" from Favorites'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                Haptics.favorite();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Saved "${details.displayTitle}" to Favorites ❤️'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
              ref
                  .read(profileControllerProvider.notifier)
                  .toggleFavoriteTitle(mediaType: mediaType, mediaId: mediaId);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isFavorite
                    ? primary.withValues(alpha: 0.12)
                    : theme.colorScheme.secondary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isFavorite
                      ? primary.withValues(alpha: 0.3)
                      : theme.colorScheme.outlineVariant,
                ),
              ),
              child: Icon(
                isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_outline_rounded,
                color: isFavorite
                    ? primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.65),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showWatchedDialog(BuildContext context, WidgetRef ref) {
    double rating = 8.0;
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Text(
                'Mark as Watched',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    details.displayTitle,
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your Rating: ${rating.toStringAsFixed(1)} / 10',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Slider(
                    value: rating,
                    min: 1.0,
                    max: 10.0,
                    divisions: 18,
                    label: rating.toStringAsFixed(1),
                    onChanged: (val) {
                      if (val != rating) {
                        Haptics.selection();
                      }
                      setDialogState(() => rating = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    Haptics.markWatched();
                    await ref
                        .read(watchlistControllerProvider.notifier)
                        .markWatched(
                          mediaId: mediaId,
                          mediaType: mediaType,
                          rating: rating,
                          title: details.displayTitle,
                          posterPath: details.posterPath,
                          backdropPath: details.backdropPath,
                          voteAverage: details.voteAverage,
                          releaseDate:
                              details.releaseDate ?? details.firstAirDate,
                        );
                    if (dialogCtx.mounted) {
                      Navigator.of(dialogCtx).pop();
                    }
                    if (context.mounted) {
                      final messenger = ScaffoldMessenger.of(context);
                      messenger.hideCurrentSnackBar();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            'Marked "${details.displayTitle}" as watched (${rating.toStringAsFixed(1)} ★)',
                          ),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Where to Watch Section (Streaming Providers Badges)
// ─────────────────────────────────────────────────────────────────────────────

class _WhereToWatchSection extends StatelessWidget {
  const _WhereToWatchSection({required this.providers});

  final TmdbWatchProvidersGroup providers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.tv_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Where to Watch',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              if (providers.link != null)
                IconButton(
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  tooltip: 'View on JustWatch',
                  onPressed: () async {
                    try {
                      await launchUrl(
                        Uri.parse(providers.link!),
                        mode: LaunchMode.externalApplication,
                      );
                    } catch (_) {}
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (providers.flatrate.isNotEmpty) ...[
            Text(
              'STREAM',
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 6),
            _ProviderLogos(items: providers.flatrate, link: providers.link),
            const SizedBox(height: 12),
          ],

          if (providers.rent.isNotEmpty) ...[
            Text(
              'RENT',
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 6),
            _ProviderLogos(items: providers.rent, link: providers.link),
            const SizedBox(height: 12),
          ],

          if (providers.buy.isNotEmpty) ...[
            Text(
              'BUY',
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 6),
            _ProviderLogos(items: providers.buy, link: providers.link),
          ],
        ],
      ),
    );
  }
}

class _ProviderLogos extends StatelessWidget {
  const _ProviderLogos({required this.items, this.link});

  final List<TmdbWatchProvider> items;
  final String? link;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((p) {
        return Tooltip(
          message: p.providerName,
          child: BouncyPressable(
            onTap: link != null
                ? () async {
                    try {
                      await launchUrl(
                        Uri.parse(link!),
                        mode: LaunchMode.externalApplication,
                      );
                    } catch (_) {}
                  }
                : null,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: p.logoPath != null
                    ? AppCachedImage(
                        imageUrl: 'https://image.tmdb.org/t/p/w92${p.logoPath}',
                        fit: BoxFit.cover,
                      )
                    : Center(
                        child: Text(
                          p.providerName.isNotEmpty ? p.providerName[0] : '?',
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Interactive TV Season & Episode Accordion Tracker
// ─────────────────────────────────────────────────────────────────────────────

class _TvSeasonAccordion extends ConsumerStatefulWidget {
  const _TvSeasonAccordion({required this.tvId, required this.details});

  final int tvId;
  final TmdbMediaDetails details;

  @override
  ConsumerState<_TvSeasonAccordion> createState() => _TvSeasonAccordionState();
}

class _TvSeasonAccordionState extends ConsumerState<_TvSeasonAccordion> {
  int _selectedSeasonNumber = 1;
  TmdbSeasonDetails? _seasonData;
  bool _loadingSeason = false;
  final _seasonCache = <int, TmdbSeasonDetails>{};

  @override
  void initState() {
    super.initState();
    if (widget.details.seasons.isNotEmpty) {
      _selectedSeasonNumber = widget.details.seasons.first.seasonNumber;
      _loadSeason(_selectedSeasonNumber);
    }
  }

  Future<void> _loadSeason(int seasonNum) async {
    if (_seasonCache.containsKey(seasonNum)) {
      setState(() {
        _selectedSeasonNumber = seasonNum;
        _seasonData = _seasonCache[seasonNum];
        _loadingSeason = false;
      });
      return;
    }

    setState(() {
      _selectedSeasonNumber = seasonNum;
      _loadingSeason = true;
    });

    try {
      final data = await ref
          .read(tmdbApiServiceProvider)
          .seasonDetails(
            tvId: widget.tvId,
            seasonNumber: seasonNum,
            language: ref.read(tmdbLanguageProvider),
          );
      _seasonCache[seasonNum] = data;
      if (mounted) {
        setState(() {
          _seasonData = data;
          _loadingSeason = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingSeason = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tracking = ref.watch(tvTrackingControllerProvider);
    final controller = ref.read(tvTrackingControllerProvider.notifier);
    final followed = tracking.isFollowed(widget.tvId);

    final seasons = widget.details.seasons;
    if (seasons.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tv_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Episodes Tracker',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () async {
                  if (followed) {
                    Haptics.light();
                    await controller.unfollowShow(showId: widget.tvId);
                  } else {
                    Haptics.follow();
                    await controller.followShow(
                      showId: widget.tvId,
                      showName: widget.details.displayTitle,
                      posterPath: widget.details.posterPath,
                    );
                  }
                },
                child: Text(
                  followed ? 'Tracking ✓' : 'Track Show',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Season Tabs & Batch Action
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: seasons.map((s) {
                      final isSelected =
                          s.seasonNumber == _selectedSeasonNumber;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(s.name),
                          selected: isSelected,
                          onSelected: (_) {
                            Haptics.tabSwitch();
                            _loadSeason(s.seasonNumber);
                          },
                          selectedColor: theme.colorScheme.primary.withValues(
                            alpha: 0.2,
                          ),
                          labelStyle: GoogleFonts.dmSans(
                            fontSize: 12.5,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              if (_seasonData != null && _seasonData!.episodes.isNotEmpty) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () async {
                    Haptics.markWatched();
                    await controller.markSeasonWatched(
                      showId: widget.tvId,
                      seasonNumber: _selectedSeasonNumber,
                      episodes: _seasonData!.episodes,
                      showName: widget.details.displayTitle,
                      posterPath: widget.details.posterPath,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Marked Season $_selectedSeasonNumber as watched!',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.done_all_rounded, size: 16),
                  label: const Text('All seen', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),

          if (_loadingSeason)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator.adaptive(),
              ),
            )
          else if (_seasonData != null) ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _seasonData!.episodes.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final ep = _seasonData!.episodes[index];
                final isWatched = tracking.isEpisodeWatched(
                  showId: widget.tvId,
                  seasonNumber: ep.seasonNumber,
                  episodeNumber: ep.episodeNumber,
                );

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Episode thumbnail
                    Container(
                      width: 80,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: ep.stillPath != null
                            ? AppCachedImage(
                                imageUrl:
                                    'https://image.tmdb.org/t/p/w185${ep.stillPath}',
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                child: const Icon(Icons.tv_outlined, size: 20),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Episode Title & Air date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'E${ep.episodeNumber} · ${ep.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          if (ep.airDate != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              ep.airDate!,
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.55,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Watched Checkbox
                    Checkbox(
                      value: isWatched,
                      activeColor: theme.colorScheme.primary,
                      onChanged: (val) async {
                        if (val == true) {
                          Haptics.episodeProgress();
                          await controller.markEpisodeWatched(
                            showId: widget.tvId,
                            seasonNumber: ep.seasonNumber,
                            episodeNumber: ep.episodeNumber,
                            showName: widget.details.displayTitle,
                            posterPath: widget.details.posterPath,
                          );
                        } else {
                          Haptics.selection();
                          await controller.unmarkEpisodeWatched(
                            showId: widget.tvId,
                            seasonNumber: ep.seasonNumber,
                            episodeNumber: ep.episodeNumber,
                          );
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cast & Crew Horizontal Rail
// ─────────────────────────────────────────────────────────────────────────────

class _CastRail extends StatelessWidget {
  const _CastRail({required this.cast});

  final List<TmdbCastMember> cast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Cast',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cast.take(15).length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final member = cast[index];
              return BouncyPressable(
                onTap: () => context.push('/person/${member.id}'),
                child: SizedBox(
                  width: 80,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        backgroundImage: member.profilePath != null
                            ? CachedNetworkImageProvider(
                                'https://image.tmdb.org/t/p/w185${member.profilePath}',
                              )
                            : null,
                        child: member.profilePath == null
                            ? const Icon(Icons.person, size: 28)
                            : null,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        member.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (member.character != null &&
                          member.character!.isNotEmpty)
                        Text(
                          member.character!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            fontSize: 10.5,
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
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Media Rail (Recommended & Similar)
// ─────────────────────────────────────────────────────────────────────────────

class _MediaRail extends StatelessWidget {
  const _MediaRail({
    required this.title,
    required this.items,
    required this.onTap,
  });

  final String title;
  final List<TmdbMedia> items;
  final void Function(TmdbMedia item, String heroTag) onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
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
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                final heroTag =
                    'details-rail-${item.mediaKind}-${item.id}-$title-$index';
                final posterUrl = item.posterPath != null
                    ? 'https://image.tmdb.org/t/p/w342${item.posterPath}'
                    : null;

                return BouncyPressable(
                  onTap: () => onTap(item, heroTag),
                  child: SizedBox(
                    width: 120,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 165,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.6),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.25 : 0.05,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: posterUrl != null
                                ? Hero(
                                    tag: heroTag,
                                    child: AppCachedImage(
                                      imageUrl: posterUrl,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Container(
                                    color: theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    child: const Icon(Icons.movie_outlined),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Comments / Community Reviews Section
// ─────────────────────────────────────────────────────────────────────────────

class _CommentsSection extends ConsumerStatefulWidget {
  const _CommentsSection({required this.mediaType, required this.mediaId});

  final String mediaType;
  final int mediaId;

  @override
  ConsumerState<_CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends ConsumerState<_CommentsSection> {
  final _commentController = TextEditingController();
  double _rating = 0.0;
  bool _spoiler = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(commentsControllerProvider);
    final notifier = ref.read(commentsControllerProvider.notifier);
    final session = ref.watch(authControllerProvider).valueOrNull;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reviews & Comments',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),

        if (session == null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  size: 24,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sign in to post reviews, star ratings, and join community discussions.',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: () => context.push('/login'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Sign In',
                    style: GoogleFonts.dmSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          )
        else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _commentController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Share your thoughts on this title…',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      'Rating: ',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                    ...List.generate(5, (index) {
                      final starVal = (index + 1) * 2.0;
                      final isSelected = _rating >= starVal;
                      return GestureDetector(
                        onTap: () => setState(
                          () => _rating = _rating == starVal ? 0.0 : starVal,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Icon(
                            isSelected
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 22,
                            color: isSelected
                                ? const Color(0xFFFFC107)
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.35,
                                  ),
                          ),
                        ),
                      );
                    }),
                    if (_rating > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        '${_rating.toInt()}/10',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFFC107),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    FilterChip(
                      label: const Text('Spoiler'),
                      selected: _spoiler,
                      onSelected: (val) => setState(() => _spoiler = val),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () async {
                        final text = _commentController.text.trim();
                        if (text.isEmpty) return;
                        await notifier.addComment(
                          mediaType: widget.mediaType,
                          mediaId: widget.mediaId,
                          content: text,
                          containsSpoiler: _spoiler,
                          rating: _rating > 0 ? _rating : null,
                        );
                        _commentController.clear();
                        setState(() => _rating = 0.0);
                      },
                      child: const Text('Post Review'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 14),
        if (state.isLoading)
          const Center(child: CircularProgressIndicator.adaptive())
        else if (state.comments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No reviews yet. Be the first to share your thoughts!',
              style: GoogleFonts.dmSans(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.comments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final comment = state.comments[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color ?? theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          child: Text(
                            (comment.displayName ?? 'U')[0].toUpperCase(),
                            style: GoogleFonts.spaceGrotesk(fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          comment.displayName ?? 'Anonymous',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      comment.content,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.85,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Backdrop Image Helper
// ─────────────────────────────────────────────────────────────────────────────

class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.details});

  final TmdbMediaDetails? details;

  @override
  Widget build(BuildContext context) {
    final backdropPath = details?.backdropPath;
    if (backdropPath == null) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      );
    }

    return AppCachedImage(
      imageUrl: 'https://image.tmdb.org/t/p/original$backdropPath',
      fit: BoxFit.cover,
    );
  }
}

void _showShareModal(
  BuildContext context,
  TmdbMediaDetails details,
  String mediaType,
) {
  Haptics.buttonTap();
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final title = details.displayTitle;
  final url = 'https://cinetrekker.vercel.app/$mediaType/${details.id}';
  final vote = details.voteAverage.toStringAsFixed(1);
  final year = (details.releaseDate?.isNotEmpty ?? false)
      ? details.releaseDate!.split('-').first
      : (details.firstAirDate?.isNotEmpty ?? false)
          ? details.firstAirDate!.split('-').first
          : '';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: theme.colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Share Title',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(19),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (details.backdropPath != null)
                      AppCachedImage(
                        imageUrl:
                            'https://image.tmdb.org/t/p/w780${details.backdropPath}',
                        fit: BoxFit.cover,
                      )
                    else
                      Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.35),
                            Colors.black.withValues(alpha: 0.85),
                            Colors.black.withValues(alpha: 0.95),
                          ],
                          stops: const [0.0, 0.6, 1.0],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (details.posterPath != null)
                            Container(
                              width: 76,
                              height: 114,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white24),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black54,
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(9),
                                child: AppCachedImage(
                                  imageUrl:
                                      'https://image.tmdb.org/t/p/w185${details.posterPath}',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Color(0xFFFFB800),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      vote,
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (year.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '•  $year',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 13,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.asset(
                                        'assets/images/logo.png',
                                        width: 14,
                                        height: 14,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'CineTrekker',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Haptics.success();
                      Clipboard.setData(ClipboardData(text: '$title: $url'));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Link copied to clipboard!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copy Link'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Haptics.buttonTap();
                      final text = Uri.encodeComponent(
                        'Watching "$title" on CineTrekker! $url',
                      );
                      final waUrl = Uri.parse('https://wa.me/?text=$text');
                      try {
                        await launchUrl(
                          waUrl,
                          mode: LaunchMode.externalApplication,
                        );
                      } catch (_) {
                        // Fallback: copy link to clipboard when share app unavailable
                        await Clipboard.setData(
                          ClipboardData(text: '$title: $url'),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Link copied to clipboard!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Share Link'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
  );
}

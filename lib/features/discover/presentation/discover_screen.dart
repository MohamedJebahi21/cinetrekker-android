import 'package:flutter/material.dart';
import '../../../core/motion/haptic_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/media_models.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/app_error_card.dart';
import '../../../shared/widgets/app_cached_image.dart';
import '../../../shared/widgets/bouncy_pressable.dart';
import 'discover_controller.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _scrollController = ScrollController();
  String _mediaType = 'movie';

  // Filter state (Phase 2.3)
  RangeValues _yearRange = const RangeValues(1970, 2026);
  double _minRating = 0;
  final Set<int> _selectedGenreIds = {};

  Map<String, String> _buildFilterParams() {
    final params = <String, String>{'sort_by': 'popularity.desc'};
    if (_yearRange.start > 1970 || _yearRange.end < 2026) {
      if (_mediaType == 'movie') {
        params['primary_release_date.gte'] =
            '${_yearRange.start.round()}-01-01';
        params['primary_release_date.lte'] =
            '${_yearRange.end.round()}-12-31';
      } else {
        params['first_air_date.gte'] = '${_yearRange.start.round()}-01-01';
        params['first_air_date.lte'] = '${_yearRange.end.round()}-12-31';
      }
    }
    if (_minRating > 0) {
      params['vote_average.gte'] = _minRating.toStringAsFixed(1);
      params['vote_count.gte'] = '50';
    }
    if (_selectedGenreIds.isNotEmpty) {
      params['with_genres'] = _selectedGenreIds.join(',');
    }
    return params;
  }

  bool get _hasActiveFilters =>
      _yearRange.start > 1970 ||
      _yearRange.end < 2026 ||
      _minRating > 0 ||
      _selectedGenreIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeLoadMore);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(discoverControllerProvider.notifier).load(
            mediaType: _mediaType,
            params: _buildFilterParams(),
          );
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_maybeLoadMore);
    _scrollController.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      ref.read(discoverControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discoverControllerProvider);
    final l10n = ref.watch(appLocalizationsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ref.listen<String>(tmdbLanguageProvider, (previous, next) {
      if (previous == null || previous == next) return;
      ref
          .read(discoverControllerProvider.notifier)
          .load(mediaType: _mediaType, language: next, params: _buildFilterParams());
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.translate('discover'),
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Haptics.buttonTap();
              final items = state.items;
              if (items.isNotEmpty) {
                final randomItem = (List<TmdbMedia>.from(
                  items,
                )..shuffle()).first;
                context.push(
                  '/details/${randomItem.mediaKind}/${randomItem.id}',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '🎲 Surprising you with "${randomItem.displayTitle}"!',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            icon: const Icon(Icons.auto_awesome_rounded),
            tooltip: 'Surprise Me',
          ),
          IconButton(
            onPressed: () => _openFilterSheet(context),
            icon: Badge(
              isLabelVisible: _hasActiveFilters,
              smallSize: 8,
              child: Icon(
                Icons.tune_rounded,
                color: _hasActiveFilters ? theme.colorScheme.primary : null,
              ),
            ),
            tooltip: 'Filter',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: theme.colorScheme.primary,
        onRefresh: () => ref
            .read(discoverControllerProvider.notifier)
            .load(
              mediaType: _mediaType,
              language: ref.read(tmdbLanguageProvider),
              params: _buildFilterParams(),
            ),
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            // Toggle group (Movies / TV Shows)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              child: Row(
                children: ['movie', 'tv'].map((type) {
                  final isActive = _mediaType == type;
                  final label = type == 'movie'
                      ? l10n.translate('movies')
                      : l10n.translate('tv_shows');
                  return Expanded(
                    child: BouncyPressable(
                      onTap: () {
                        Haptics.tabSwitch();
                        setState(() => _mediaType = type);
                        ref
                            .read(discoverControllerProvider.notifier)
                            .load(
                              mediaType: type,
                              language: ref.read(tmdbLanguageProvider),
                              params: _buildFilterParams(),
                            );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isActive
                              ? (isDark ? theme.cardTheme.color : Colors.white)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.08),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            label,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurface.withValues(
                                      alpha: 0.6,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Category Shortcuts (Genres, Decades, Awards, Recommendations)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _CategoryChip(
                    icon: Icons.category_outlined,
                    label: 'Genres',
                    onTap: () => context.push('/genres'),
                  ),
                  const SizedBox(width: 8),
                  _CategoryChip(
                    icon: Icons.history_edu_outlined,
                    label: 'Decades',
                    onTap: () => context.push('/decades'),
                  ),
                  const SizedBox(width: 8),
                  _CategoryChip(
                    icon: Icons.emoji_events_outlined,
                    label: 'Awards',
                    onTap: () => context.push('/awards'),
                  ),
                  const SizedBox(width: 8),
                  _CategoryChip(
                    icon: Icons.recommend_outlined,
                    label: 'Picks For You',
                    onTap: () => context.push('/recommendations'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (state.isLoading && state.items.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator.adaptive(),
                ),
              )
            else if (state.error != null && state.items.isEmpty)
              AppErrorCard(
                message: state.error!,
                onRetry: () => ref
                    .read(discoverControllerProvider.notifier)
                    .load(
                      mediaType: _mediaType,
                      language: ref.read(tmdbLanguageProvider),
                    ),
              )
            else if (state.items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.movie_filter_outlined,
                        size: 56,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.3,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'No matching titles found',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Try adjusting your genre filters or release years.',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.55,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () {
                          ref
                              .read(discoverControllerProvider.notifier)
                              .load(
                                mediaType: _mediaType,
                                language: ref.read(tmdbLanguageProvider),
                              );
                        },
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = state.items[index];
                  final heroTag =
                      'discover-${item.mediaKind}-${item.id}-$index';
                  final posterUrl = item.posterPath != null
                      ? 'https://image.tmdb.org/t/p/w342${item.posterPath}'
                      : null;

                  return BouncyPressable(
                    onTap: () => context.push(
                      '/details/${item.mediaKind}/${item.id}?heroTag=${Uri.encodeComponent(heroTag)}',
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color ?? theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.20 : 0.04,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 72,
                                height: 105,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
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
                                          child: const Icon(
                                            Icons.movie_outlined,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.displayTitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.3,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        if (item.year != null)
                                          Text(
                                            '${item.year}',
                                            style: GoogleFonts.dmSans(
                                              fontSize: 12.5,
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.6),
                                            ),
                                          ),
                                        if (item.voteAverage > 0) ...[
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.star_rounded,
                                            size: 15,
                                            color: Color(0xFFFFC107),
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            item.voteAverage.toStringAsFixed(1),
                                            style: GoogleFonts.dmSans(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if ((item.overview ?? '').isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        item.overview!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.dmSans(
                                          fontSize: 12,
                                          height: 1.4,
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.65),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                },
              ),

            if (state.isLoading && state.items.isNotEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFilterSheet(BuildContext context) async {
    Haptics.buttonTap();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _DiscoverFilterSheet(
        initialYearRange: _yearRange,
        initialMinRating: _minRating,
        initialGenreIds: Set<int>.from(_selectedGenreIds),
        mediaType: _mediaType,
        onApply: (yearRange, minRating, genreIds) {
          setState(() {
            _yearRange = yearRange;
            _minRating = minRating;
            _selectedGenreIds
              ..clear()
              ..addAll(genreIds);
          });
          ref.read(discoverControllerProvider.notifier).load(
                mediaType: _mediaType,
                language: ref.read(tmdbLanguageProvider),
                params: _buildFilterParams(),
              );
        },
        onReset: () {
          setState(() {
            _yearRange = const RangeValues(1970, 2026);
            _minRating = 0;
            _selectedGenreIds.clear();
          });
          ref.read(discoverControllerProvider.notifier).load(
                mediaType: _mediaType,
                language: ref.read(tmdbLanguageProvider),
                params: _buildFilterParams(),
              );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ActionChip(
      onPressed: onTap,
      avatar: Icon(icon, size: 16, color: theme.colorScheme.primary),
      label: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
      backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Discover Filter Bottom Sheet (Phase 2.3)
// ---------------------------------------------------------------------------

typedef _FilterApplyCallback = void Function(
  RangeValues yearRange,
  double minRating,
  Set<int> genreIds,
);

class _DiscoverFilterSheet extends StatefulWidget {
  const _DiscoverFilterSheet({
    required this.initialYearRange,
    required this.initialMinRating,
    required this.initialGenreIds,
    required this.mediaType,
    required this.onApply,
    required this.onReset,
  });

  final RangeValues initialYearRange;
  final double initialMinRating;
  final Set<int> initialGenreIds;
  final String mediaType;
  final _FilterApplyCallback onApply;
  final VoidCallback onReset;

  @override
  State<_DiscoverFilterSheet> createState() => _DiscoverFilterSheetState();
}

class _DiscoverFilterSheetState extends State<_DiscoverFilterSheet> {
  late RangeValues _yearRange;
  late double _minRating;
  late Set<int> _selectedGenreIds;

  // Common genre list (works for both movie and TV)
  static const _movieGenres = <({int id, String label})>[
    (id: 28, label: 'Action'),
    (id: 12, label: 'Adventure'),
    (id: 16, label: 'Animation'),
    (id: 35, label: 'Comedy'),
    (id: 80, label: 'Crime'),
    (id: 99, label: 'Documentary'),
    (id: 18, label: 'Drama'),
    (id: 10751, label: 'Family'),
    (id: 14, label: 'Fantasy'),
    (id: 36, label: 'History'),
    (id: 27, label: 'Horror'),
    (id: 10402, label: 'Music'),
    (id: 9648, label: 'Mystery'),
    (id: 10749, label: 'Romance'),
    (id: 878, label: 'Sci-Fi'),
    (id: 53, label: 'Thriller'),
    (id: 10752, label: 'War'),
    (id: 37, label: 'Western'),
  ];

  static const _tvGenres = <({int id, String label})>[
    (id: 10759, label: 'Action & Adventure'),
    (id: 16, label: 'Animation'),
    (id: 35, label: 'Comedy'),
    (id: 80, label: 'Crime'),
    (id: 99, label: 'Documentary'),
    (id: 18, label: 'Drama'),
    (id: 10751, label: 'Family'),
    (id: 10762, label: 'Kids'),
    (id: 9648, label: 'Mystery'),
    (id: 10763, label: 'News'),
    (id: 10764, label: 'Reality'),
    (id: 10765, label: 'Sci-Fi & Fantasy'),
    (id: 10766, label: 'Soap'),
    (id: 10767, label: 'Talk'),
    (id: 10768, label: 'War & Politics'),
    (id: 37, label: 'Western'),
  ];

  @override
  void initState() {
    super.initState();
    _yearRange = widget.initialYearRange;
    _minRating = widget.initialMinRating;
    _selectedGenreIds = Set<int>.from(widget.initialGenreIds);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final genres =
        widget.mediaType == 'tv' ? _tvGenres : _movieGenres;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Filter Results',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      widget.onReset();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  // Year Range
                  Text(
                    'Release Year',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _yearRange.start.round().toString(),
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        _yearRange.end.round().toString(),
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: _yearRange,
                    min: 1970,
                    max: 2026,
                    divisions: 56,
                    labels: RangeLabels(
                      _yearRange.start.round().toString(),
                      _yearRange.end.round().toString(),
                    ),
                    onChanged: (v) => setState(() => _yearRange = v),
                  ),
                  const SizedBox(height: 20),

                  // Min Rating
                  Text(
                    'Minimum Rating  ★ ${_minRating == 0 ? 'Any' : _minRating.toStringAsFixed(1)}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Slider(
                    value: _minRating,
                    min: 0,
                    max: 9,
                    divisions: 18,
                    label: _minRating == 0
                        ? 'Any'
                        : _minRating.toStringAsFixed(1),
                    onChanged: (v) => setState(() => _minRating = v),
                  ),
                  const SizedBox(height: 20),

                  // Genres
                  Text(
                    'Genres',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: genres.map((g) {
                      final isSelected = _selectedGenreIds.contains(g.id);
                      return FilterChip(
                        selected: isSelected,
                        label: Text(g.label),
                        onSelected: (selected) {
                          Haptics.selection();
                          setState(() {
                            if (selected) {
                              _selectedGenreIds.add(g.id);
                            } else {
                              _selectedGenreIds.remove(g.id);
                            }
                          });
                        },
                        selectedColor:
                            theme.colorScheme.primary.withValues(alpha: 0.18),
                        checkmarkColor: theme.colorScheme.primary,
                        labelStyle: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSelected
                                ? theme.colorScheme.primary.withValues(
                                    alpha: 0.4,
                                  )
                                : theme.colorScheme.outlineVariant,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            // Apply Button
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.of(context).padding.bottom + 12,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Haptics.success();
                    widget.onApply(_yearRange, _minRating, _selectedGenreIds);
                    Navigator.of(context).pop();
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Apply Filters',
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

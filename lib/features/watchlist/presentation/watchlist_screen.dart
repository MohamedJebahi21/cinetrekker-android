import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../core/motion/haptic_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/media_models.dart';
import '../../../shared/widgets/app_error_card.dart';
import '../../../shared/widgets/app_cached_image.dart';
import '../../../shared/widgets/bouncy_pressable.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/presentation/profile_controller.dart';
import 'watchlist_controller.dart';

class WatchlistScreen extends ConsumerStatefulWidget {
  const WatchlistScreen({this.initialTab = 0, super.key});

  final int initialTab;

  @override
  ConsumerState<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends ConsumerState<WatchlistScreen> {
  late int _tabIndex;
  bool _isGridView = false;
  String _mediaFilter = 'all'; // 'all' | 'movie' | 'tv'
  String _sortBy =
      'date_added'; // 'date_added' | 'rating' | 'release_date' | 'title'

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTab.clamp(0, 2);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(watchlistControllerProvider.notifier).load();
      ref.read(profileControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(watchlistControllerProvider);
    final profileState = ref.watch(profileControllerProvider);
    final theme = Theme.of(context);

    final List<UserMediaItem> rawItems;
    if (_tabIndex == 0) {
      rawItems = state.watchlist;
    } else if (_tabIndex == 1) {
      rawItems = state.watched;
    } else {
      final favoriteKeys = profileState.favorites.toSet();
      final combined = <String, UserMediaItem>{};
      for (final item in state.watchlist) {
        final key = ProfileRepository.favoriteKey(item.mediaType, item.mediaId);
        if (favoriteKeys.contains(key)) {
          combined[key] = item;
        }
      }
      for (final item in state.watched) {
        final key = ProfileRepository.favoriteKey(item.mediaType, item.mediaId);
        if (favoriteKeys.contains(key)) {
          combined[key] = item;
        }
      }
      rawItems = combined.values.toList();
    }

    // Filter items
    var filtered = rawItems.where((item) {
      if (_mediaFilter == 'all') return true;
      return item.mediaType == _mediaFilter;
    }).toList();

    // Sort items
    if (_sortBy == 'rating') {
      filtered.sort(
        (a, b) => (b.rating ?? b.voteAverage ?? 0).compareTo(
          a.rating ?? a.voteAverage ?? 0,
        ),
      );
    } else if (_sortBy == 'release_date') {
      filtered.sort(
        (a, b) => (b.releaseDate ?? '').compareTo(a.releaseDate ?? ''),
      );
    } else if (_sortBy == 'title') {
      filtered.sort(
        (a, b) => a.displayTitle.toLowerCase().compareTo(
          b.displayTitle.toLowerCase(),
        ),
      );
    } else {
      // date_added (newest first)
      filtered.sort((a, b) => (b.addedAt).compareTo(a.addedAt));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Library',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Haptics.toggleChange();
              setState(() => _isGridView = !_isGridView);
            },
            icon: Icon(
              _isGridView
                  ? Icons.view_agenda_outlined
                  : Icons.grid_view_rounded,
            ),
            tooltip: _isGridView ? 'List view' : 'Grid view',
          ),
          IconButton(
            onPressed: () => _openSurprisePicker(context, state),
            icon: const Icon(Icons.casino_outlined),
            tooltip: 'Surprise Me',
          ),
          IconButton(
            onPressed: () => context.push('/tv-tracking'),
            icon: const Icon(Icons.tv_outlined),
            tooltip: 'TV tracking',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: theme.colorScheme.primary,
        onRefresh: () => ref.read(watchlistControllerProvider.notifier).load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            // Segmented tab switch (Watchlist vs. Watched)
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
                children: [0, 1, 2].map((idx) {
                  final isActive = _tabIndex == idx;
                  final label = idx == 0
                      ? 'Watchlist'
                      : idx == 1
                          ? 'Watched'
                          : 'Favorites';
                  final icon = idx == 0
                      ? Icons.bookmark_rounded
                      : idx == 1
                          ? Icons.check_circle_rounded
                          : Icons.favorite_rounded;
                  return Expanded(
                    child: BouncyPressable(
                      onTap: () {
                        Haptics.tabSwitch();
                        setState(() => _tabIndex = idx);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              icon,
                              size: 14,
                              color: isActive
                                  ? Colors.white
                                  : theme.colorScheme.onSurface.withValues(
                                      alpha: 0.6,
                                    ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              label,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isActive
                                    ? Colors.white
                                    : theme.colorScheme.onSurface.withValues(
                                        alpha: 0.7,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Controls Bar (Filters, View Mode, Sorting)
            Row(
              children: [
                _FilterChip(
                  label: 'All (${rawItems.length})',
                  isSelected: _mediaFilter == 'all',
                  onTap: () => setState(() => _mediaFilter = 'all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Movies',
                  isSelected: _mediaFilter == 'movie',
                  onTap: () => setState(() => _mediaFilter = 'movie'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'TV Shows',
                  isSelected: _mediaFilter == 'tv',
                  onTap: () => setState(() => _mediaFilter = 'tv'),
                ),
                const Spacer(),
                // Grid / List toggle
                IconButton(
                  onPressed: () => setState(() => _isGridView = !_isGridView),
                  icon: Icon(
                    _isGridView
                        ? Icons.view_list_rounded
                        : Icons.grid_view_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  tooltip: _isGridView ? 'List view' : 'Grid view',
                ),
                // Sort Menu
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.sort_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  tooltip: 'Sort by',
                  initialValue: _sortBy,
                  onSelected: (val) => setState(() => _sortBy = val),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'date_added',
                      child: Text('Date Added'),
                    ),
                    const PopupMenuItem(
                      value: 'rating',
                      child: Text('Rating (High to Low)'),
                    ),
                    const PopupMenuItem(
                      value: 'release_date',
                      child: Text('Release Date'),
                    ),
                    const PopupMenuItem(
                      value: 'title',
                      child: Text('Title (A to Z)'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (state.error != null)
              AppErrorCard(
                message: state.error!,
                onRetry: () =>
                    ref.read(watchlistControllerProvider.notifier).load(),
              )
            else if (state.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator.adaptive()),
              )
            else if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        _tabIndex == 0
                            ? Icons.bookmark_outline_rounded
                            : _tabIndex == 1
                                ? Icons.check_circle_outline_rounded
                                : Icons.favorite_border_rounded,
                        size: 48,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _tabIndex == 0
                            ? 'Your watchlist is empty.'
                            : _tabIndex == 1
                                ? 'No watched titles logged yet.'
                                : 'No favorite titles saved yet.',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _tabIndex == 2
                            ? 'Tap the heart icon on any movie or series to save your favorites.'
                            : 'Browse movies and series to add them here.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.55,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => context.push('/discover'),
                        icon: const Icon(Icons.explore_rounded, size: 16),
                        label: const Text('Discover Titles'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_isGridView)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.62,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  return _GridMediaCard(
                    item: item,
                    isWatchedTab: _tabIndex == 1,
                  );
                },
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  return _ListMediaCard(
                    item: item,
                    isWatchedTab: _tabIndex == 1,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _openSurprisePicker(BuildContext context, WatchlistState state) {
    Haptics.buttonTap();
    final List<UserMediaItem> items;
    if (_tabIndex == 1) {
      items = state.watched;
    } else if (_tabIndex == 2) {
      // Favorites: items from watchlist+watched that are in profileState.favorites
      final profileState = ref.read(profileControllerProvider);
      final favoriteKeys = profileState.favorites.toSet();
      final combined = <String, UserMediaItem>{};
      for (final item in state.watchlist) {
        final key = ProfileRepository.favoriteKey(item.mediaType, item.mediaId);
        if (favoriteKeys.contains(key)) combined[key] = item;
      }
      for (final item in state.watched) {
        final key = ProfileRepository.favoriteKey(item.mediaType, item.mediaId);
        if (favoriteKeys.contains(key)) combined[key] = item;
      }
      items = combined.values.toList();
    } else {
      items = state.watchlist;
    }
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No titles in this list to choose from!'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => _SurpriseRouletteDialog(items: items),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? primary.withValues(alpha: 0.14)
              : theme.colorScheme.secondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? primary.withValues(alpha: 0.3)
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

class _GridMediaCard extends ConsumerWidget {
  const _GridMediaCard({required this.item, required this.isWatchedTab});

  final UserMediaItem item;
  final bool isWatchedTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final posterUrl = item.posterPath != null && item.posterPath!.isNotEmpty
        ? 'https://image.tmdb.org/t/p/w342${item.posterPath}'
        : null;

    final heroTag = 'watchlist-grid-${item.mediaType}-${item.mediaId}';

    return BouncyPressable(
      onTap: () => context.push(
        '/details/${item.mediaType}/${item.mediaId}?heroTag=${Uri.encodeComponent(heroTag)}',
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (posterUrl != null)
                        Hero(
                          tag: heroTag,
                          child: AppCachedImage(
                            imageUrl: posterUrl,
                            fit: BoxFit.cover,
                            errorIcon: item.mediaType == 'tv'
                                ? Icons.tv_outlined
                                : Icons.movie_outlined,
                          ),
                        )
                      else
                        Center(
                          child: Icon(
                            item.mediaType == 'tv'
                                ? Icons.tv_outlined
                                : Icons.movie_outlined,
                            size: 36,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                      if ((item.rating != null && item.rating! > 0) ||
                          (item.voteAverage != null && item.voteAverage! > 0))
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 12,
                                  color: Color(0xFFFFC107),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  ((item.rating != null && item.rating! > 0)
                                          ? item.rating!
                                          : item.voteAverage!)
                                      .toStringAsFixed(1),
                                  style: GoogleFonts.dmSans(
                                    fontSize: 10.5,
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
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const SizedBox(height: 2),
                    Text(
                      '${item.mediaType == 'tv' ? 'TV Series' : 'Movie'}${item.year != null ? ' · ${item.year}' : ''}',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.55,
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

class _ListMediaCard extends ConsumerWidget {
  const _ListMediaCard({required this.item, required this.isWatchedTab});

  final UserMediaItem item;
  final bool isWatchedTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final posterUrl = item.posterPath != null && item.posterPath!.isNotEmpty
        ? 'https://image.tmdb.org/t/p/w185${item.posterPath}'
        : null;

    final heroTag = 'watchlist-list-${item.mediaType}-${item.mediaId}';

    return BouncyPressable(
      onTap: () => context.push(
        '/details/${item.mediaType}/${item.mediaId}?heroTag=${Uri.encodeComponent(heroTag)}',
      ),
      child: Container(
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
        child: Padding(
          padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 56,
                    height: 78,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: posterUrl != null
                        ? Hero(
                            tag: heroTag,
                            child: AppCachedImage(
                              imageUrl: posterUrl,
                              fit: BoxFit.cover,
                              errorIcon: item.mediaType == 'tv'
                                  ? Icons.tv_outlined
                                  : Icons.movie_outlined,
                            ),
                          )
                        : Icon(
                            item.mediaType == 'tv'
                                ? Icons.tv_outlined
                                : Icons.movie_outlined,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.4,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.mediaType == 'tv' ? 'TV Series' : 'Movie'}${item.year != null ? ' · ${item.year}' : ''}',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.55,
                          ),
                        ),
                      ),
                      if ((item.rating != null && item.rating! > 0) ||
                          (item.voteAverage != null &&
                              item.voteAverage! > 0)) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Color(0xFFFFC107),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              ((item.rating != null && item.rating! > 0)
                                      ? item.rating!
                                      : item.voteAverage!)
                                  .toStringAsFixed(1),
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    if (isWatchedTab) {
                      await ref
                          .read(watchlistControllerProvider.notifier)
                          .removeFromWatched(
                            mediaType: item.mediaType,
                            mediaId: item.mediaId,
                          );
                    } else {
                      await ref
                          .read(watchlistControllerProvider.notifier)
                          .removeFromWatchlist(
                            mediaType: item.mediaType,
                            mediaId: item.mediaId,
                          );
                    }
                  },
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}

class _SurpriseRouletteDialog extends StatefulWidget {
  const _SurpriseRouletteDialog({required this.items});

  final List<UserMediaItem> items;

  @override
  State<_SurpriseRouletteDialog> createState() =>
      _SurpriseRouletteDialogState();
}

class _SurpriseRouletteDialogState extends State<_SurpriseRouletteDialog> {
  late int _currentIndex;
  bool _isSpinning = true;
  Timer? _timer;
  int _step = 0;
  final int _maxSteps = 16;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _currentIndex = _random.nextInt(widget.items.length);
    _spin();
  }

  void _spin() {
    if (!mounted) return;
    if (_step >= _maxSteps) {
      Haptics.success();
      setState(() => _isSpinning = false);
      return;
    }

    _step++;
    Haptics.selection();
    setState(() {
      _currentIndex = _random.nextInt(widget.items.length);
    });

    final delay = 60 + (_step * _step * 1.5).toInt();
    _timer = Timer(Duration(milliseconds: delay), _spin);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.items[_currentIndex];
    final posterUrl = item.posterPath != null && item.posterPath!.isNotEmpty
        ? 'https://image.tmdb.org/t/p/w342${item.posterPath}'
        : null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.casino_rounded,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  _isSpinning ? 'Picking for You…' : 'Tonight\'s Pick! 🍿',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: 140,
              height: 210,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isSpinning
                      ? theme.colorScheme.outlineVariant
                      : theme.colorScheme.primary,
                  width: _isSpinning ? 1 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isSpinning ? Colors.black : theme.colorScheme.primary)
                        .withValues(alpha: _isSpinning ? 0.2 : 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: posterUrl != null
                    ? AppCachedImage(
                        imageUrl: posterUrl,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.movie_outlined, size: 48),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              item.displayTitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (item.voteAverage != null && item.voteAverage! > 0) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFFFB800),
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.voteAverage!.toStringAsFixed(1),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            if (_isSpinning)
              const SizedBox(
                height: 42,
                child: Center(child: CircularProgressIndicator.adaptive()),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _isSpinning = true;
                          _step = 0;
                        });
                        _spin();
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Spin Again'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.push(
                          '/details/${item.mediaType}/${item.mediaId}',
                        );
                      },
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('View Title'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

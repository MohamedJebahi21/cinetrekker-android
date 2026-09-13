import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../core/motion/haptic_service.dart';
import '../../../shared/widgets/app_error_card.dart';
import '../../../shared/widgets/app_cached_image.dart';
import '../../../shared/widgets/bouncy_pressable.dart';
import 'search_controller.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  static const _recentSearchesKey = 'cinetrekker_recent_searches';
  static const _storage = FlutterSecureStorage();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;
  String _type = 'all';
  List<String> _recentSearches = [
    'Oppenheimer',
    'Interstellar',
    'Dune',
    'The Last of Us',
    'Stranger Things',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeLoadMore);
    _loadSavedSearches();
  }

  Future<void> _loadSavedSearches() async {
    try {
      final raw = await _storage.read(key: _recentSearchesKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = (jsonDecode(raw) as List).cast<String>();
        if (decoded.isNotEmpty && mounted) {
          setState(() => _recentSearches = decoded);
        }
      }
    } catch (_) {}
  }

  Future<void> _saveSearches(List<String> list) async {
    try {
      await _storage.write(key: _recentSearchesKey, value: jsonEncode(list));
    } catch (_) {}
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.removeListener(_maybeLoadMore);
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      ref.read(searchControllerProvider.notifier).loadMore();
    }
  }

  void _scheduleSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final q = value.trim();
      if (q.isNotEmpty) {
        final updated = List<String>.from(_recentSearches);
        updated.remove(q);
        updated.insert(0, q);
        if (updated.length > 8) updated.removeLast();
        setState(() => _recentSearches = updated);
        _saveSearches(updated);
      }
      ref
          .read(searchControllerProvider.notifier)
          .search(query: value, type: _type);
    });
  }

  void _executeSearch(String query) {
    _controller.text = query;
    _scheduleSearch(query);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ref.listen<String>(tmdbLanguageProvider, (previous, next) {
      if (previous == null || previous == next) return;
      final query = _controller.text.trim();
      if (query.isEmpty) return;
      ref
          .read(searchControllerProvider.notifier)
          .search(query: query, type: _type, language: next);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Search',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: RefreshIndicator(
          color: theme.colorScheme.primary,
          onRefresh: () => ref
              .read(searchControllerProvider.notifier)
              .search(
                query: _controller.text,
                type: _type,
                language: ref.read(tmdbLanguageProvider),
              ),
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              // Search Input Field
              TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  color: theme.colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Search movies, shows, and people…',
                  hintStyle: GoogleFonts.dmSans(
                    fontSize: 15,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _controller.clear();
                            ref.read(searchControllerProvider.notifier).clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.55),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
                onChanged: _scheduleSearch,
                onSubmitted: (value) {
                  _executeSearch(value);
                },
              ),
              const SizedBox(height: 14),

              // Filter Tabs (All, Movies, TV, People)
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
                  children: ['all', 'movie', 'tv', 'person'].map((type) {
                    final isActive = _type == type;
                    final label = switch (type) {
                      'all' => 'All',
                      'movie' => 'Movies',
                      'tv' => 'TV Shows',
                      'person' => 'People',
                      _ => type,
                    };
                    return Expanded(
                      child: BouncyPressable(
                        onTap: () {
                          Haptics.tabSwitch();
                          setState(() => _type = type);
                          if (_controller.text.trim().isNotEmpty) {
                            ref
                                .read(searchControllerProvider.notifier)
                                .search(
                                  query: _controller.text,
                                  type: _type,
                                  language: ref.read(tmdbLanguageProvider),
                                );
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isActive
                                ? (isDark
                                      ? theme.cardTheme.color
                                      : Colors.white)
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
                                fontSize: 12.5,
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

              // Recent Searches (if input is empty)
              if (_controller.text.trim().isEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Searches',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (_recentSearches.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          setState(() => _recentSearches.clear());
                          _saveSearches(<String>[]);
                        },
                        child: Text(
                          'Clear all',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _recentSearches.map((term) {
                    return InputChip(
                      avatar: const Icon(Icons.history_rounded, size: 14),
                      label: Text(
                        term,
                        style: GoogleFonts.dmSans(fontSize: 12),
                      ),
                      onPressed: () => _executeSearch(term),
                      onDeleted: () {
                        setState(() {
                          _recentSearches.remove(term);
                        });
                        _saveSearches(_recentSearches);
                      },
                      deleteIcon: const Icon(Icons.close_rounded, size: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Mood & Quick Discovery Pills
                Text(
                  'Explore by Mood & Genre',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    '🔥 Trending Now',
                    '🚀 Sci-Fi',
                    '🏆 Award Winners',
                    '🍿 Feel Good',
                    '⏳ Fast Paced',
                    '👻 Horror Vault',
                    '⚡ Action Thriller',
                    '🎭 Mind-Bending',
                  ].map((mood) {
                    return BouncyPressable(
                      onTap: () {
                        Haptics.buttonTap();
                        final query = mood
                            .replaceFirst(RegExp(r'^[^\w]+'), '')
                            .trim();
                        _controller.text = query;
                        _executeSearch(query);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: Text(
                          mood,
                          style: GoogleFonts.dmSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],

              if (state.isLoading && state.results.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator.adaptive()),
                )
              else if (state.error != null)
                AppErrorCard(
                  message: state.error!,
                  onRetry: () => ref
                      .read(searchControllerProvider.notifier)
                      .search(
                        query: _controller.text,
                        type: _type,
                        language: ref.read(tmdbLanguageProvider),
                      ),
                )
              else if (state.results.isEmpty &&
                  _controller.text.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.35,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No results found for "${_controller.text.trim()}"',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Try searching with different keywords.',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.55,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = state.results[index];
                    final isPerson =
                        item.mediaKind == 'person' || item.profilePath != null;
                    final heroTag =
                        'search-${item.mediaKind}-${item.id}-$index';
                    final imageUrl = item.posterPath != null
                        ? 'https://image.tmdb.org/t/p/w342${item.posterPath}'
                        : (item.profilePath != null
                              ? 'https://image.tmdb.org/t/p/w185${item.profilePath}'
                              : null);

                    return BouncyPressable(
                      onTap: () {
                        if (isPerson) {
                          context.push('/person/${item.id}');
                        } else {
                          context.push(
                            '/details/${item.mediaKind}/${item.id}?heroTag=${Uri.encodeComponent(heroTag)}',
                          );
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              theme.cardTheme.color ?? theme.colorScheme.surface,
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
                              children: [
                                Container(
                                  width: 56,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: theme.colorScheme.outlineVariant
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: imageUrl != null
                                        ? Hero(
                                            tag: heroTag,
                                            child: AppCachedImage(
                                              imageUrl: imageUrl,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : Container(
                                            color: theme
                                                .colorScheme
                                                .surfaceContainerHighest,
                                            child: Icon(
                                              isPerson
                                                  ? Icons.person_rounded
                                                  : Icons.movie_outlined,
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.4),
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.displayTitle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.3,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  theme.colorScheme.secondary,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              isPerson
                                                  ? 'Person'
                                                  : (item.mediaKind == 'tv'
                                                        ? 'TV Series'
                                                        : 'Movie'),
                                              style: GoogleFonts.dmSans(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w600,
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.7),
                                              ),
                                            ),
                                          ),
                                          if (item.year != null) ...[
                                            const SizedBox(width: 8),
                                            Text(
                                              '${item.year}',
                                              style: GoogleFonts.dmSans(
                                                fontSize: 12,
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.55),
                                              ),
                                            ),
                                          ],
                                          if (!isPerson &&
                                              item.voteAverage > 0) ...[
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.star_rounded,
                                              size: 14,
                                              color: Color(0xFFFFC107),
                                            ),
                                            const SizedBox(width: 2),
                                            Text(
                                              item.voteAverage.toStringAsFixed(
                                                1,
                                              ),
                                              style: GoogleFonts.dmSans(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
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

              if (state.isLoading && state.results.isNotEmpty)
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
      ),
    );
  }
}

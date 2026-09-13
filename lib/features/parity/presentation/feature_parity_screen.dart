import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api/tmdb_api_service.dart';
import '../../../core/errors/app_error_messages.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/models/media_models.dart';
import '../../../shared/widgets/app_error_card.dart';
import '../../watchlist/data/user_library_repository.dart';

class FeatureParityScreen extends ConsumerStatefulWidget {
  const FeatureParityScreen({
    required this.title,
    required this.mode,
    super.key,
  });

  final String title;
  final String mode;

  @override
  ConsumerState<FeatureParityScreen> createState() =>
      _FeatureParityScreenState();
}

class _FeatureParityScreenState extends ConsumerState<FeatureParityScreen> {
  List<TmdbMedia> _items = const <TmdbMedia>[];
  List<TmdbMediaDetails> _calendarShows = const <TmdbMediaDetails>[];
  List<UserMediaItem> _libraryItems = const <UserMediaItem>[];
  int _watchlistCount = 0;
  int _watchedCount = 0;
  int _watchedEpisodesCount = 0;
  bool _loading = true;
  String? _error;
  String _browseMediaType = 'movie';
  int? _selectedGenreId;
  String _selectedDecade = '2020s';
  String _selectedAwardMode = 'oscars';

  final List<Map<String, dynamic>> _genreList = [
    {
      'id': 28,
      'name': 'Action',
      'icon': Icons.flash_on_rounded,
      'color': Color(0xFFE53935),
    },
    {
      'id': 12,
      'name': 'Adventure',
      'icon': Icons.explore_rounded,
      'color': Color(0xFFFB8C00),
    },
    {
      'id': 16,
      'name': 'Animation',
      'icon': Icons.brush_rounded,
      'color': Color(0xFF8E24AA),
    },
    {
      'id': 35,
      'name': 'Comedy',
      'icon': Icons.sentiment_very_satisfied_rounded,
      'color': Color(0xFFFFB300),
    },
    {
      'id': 80,
      'name': 'Crime',
      'icon': Icons.local_police_rounded,
      'color': Color(0xFF546E7A),
    },
    {
      'id': 99,
      'name': 'Documentary',
      'icon': Icons.videocam_rounded,
      'color': Color(0xFF43A047),
    },
    {
      'id': 18,
      'name': 'Drama',
      'icon': Icons.theater_comedy_rounded,
      'color': Color(0xFF3949AB),
    },
    {
      'id': 14,
      'name': 'Fantasy',
      'icon': Icons.auto_awesome_rounded,
      'color': Color(0xFF00ACC1),
    },
    {
      'id': 27,
      'name': 'Horror',
      'icon': Icons.nightlight_round,
      'color': Color(0xFFD81B60),
    },
    {
      'id': 878,
      'name': 'Sci-Fi',
      'icon': Icons.rocket_launch_rounded,
      'color': Color(0xFF1E88E5),
    },
    {
      'id': 53,
      'name': 'Thriller',
      'icon': Icons.speed_rounded,
      'color': Color(0xFF6D4C41),
    },
  ];

  final List<String> _decadesList = [
    '2020s',
    '2010s',
    '2000s',
    '1990s',
    '1980s',
    '1970s',
    '1960s',
    '1950s',
  ];

  final List<Map<String, String>> _awardsList = [
    {
      'id': 'oscars',
      'name': 'Academy Awards',
      'desc': 'Best Picture & Directing winners',
    },
    {
      'id': 'cannes',
      'name': 'Cannes Palme d\'Or',
      'desc': 'World cinema festival masters',
    },
    {
      'id': 'globes',
      'name': 'Golden Globes',
      'desc': 'Film & television achievements',
    },
    {
      'id': 'bafta',
      'name': 'BAFTA Film',
      'desc': 'British Academy award winners',
    },
  ];

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_load);
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final language = ref.read(tmdbLanguageProvider);
      final tmdb = ref.read(tmdbApiServiceProvider);
      final library = ref.read(userLibraryRepositoryProvider);
      final watchlist = await library.getWatchlist();
      final watched = await library.getWatched();
      final watchedEpisodes = await library.getWatchedEpisodes();
      final calendarShows = <TmdbMediaDetails>[];

      if (widget.mode == 'calendar' || widget.mode == 'upcoming') {
        final followedShows = await library.getFollowedShows();
        final futures = followedShows.take(8).map<Future<TmdbMediaDetails?>>(
          (show) async {
            try {
              return await tmdb.details(
                mediaType: 'tv',
                mediaId: show.showId,
                language: language,
              );
            } catch (_) {
              return null;
            }
          },
        );
        final results = await Future.wait(futures);
        calendarShows.addAll(results.whereType<TmdbMediaDetails>());
      }

      final response = await _loadResponse(tmdb, language, watched);
      if (!mounted) return;
      setState(() {
        _watchlistCount = watchlist.length;
        _watchedCount = watched.length;
        _watchedEpisodesCount = watchedEpisodes.length;
        _calendarShows = calendarShows;
        _libraryItems = widget.mode == 'print-watchlist' ? watchlist : watched;
        _items = response;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = describeAppError(error);
      });
    }
  }

  Future<List<TmdbMedia>> _loadResponse(
    TmdbApiService tmdb,
    String language,
    List<UserMediaItem> watched,
  ) async {
    switch (widget.mode) {
      case 'trending':
        return (await tmdb.trending(
          mediaType: 'all',
          timeWindow: 'week',
          language: language,
        )).results;
      case 'recommendations':
        if (watched.isEmpty) {
          return (await tmdb.trending(
            mediaType: 'all',
            timeWindow: 'week',
            language: language,
          )).results;
        }
        final seed = watched.first;
        return (await tmdb.recommendations(
          mediaType: seed.mediaType,
          mediaId: seed.mediaId,
          language: language,
        )).results;
      case 'calendar':
      case 'upcoming':
        return (await tmdb.nowPlayingMovies(language: language)).results;
      case 'genres':
        final genreId = _selectedGenreId ?? 28;
        return (await tmdb.discover(
          mediaType: _browseMediaType,
          language: language,
          params: <String, String>{
            'with_genres': genreId.toString(),
            'sort_by': 'popularity.desc',
          },
        )).results;
      case 'decades':
        final yearRange = _getDecadeRange(_selectedDecade);
        return (await tmdb.discover(
          mediaType: 'movie',
          language: language,
          params: <String, String>{
            'primary_release_date.gte': yearRange[0],
            'primary_release_date.lte': yearRange[1],
            'sort_by': 'vote_average.desc',
            'vote_count.gte': '300',
          },
        )).results;
      case 'awards':
        if (_selectedAwardMode == 'cannes') {
          return (await tmdb.discover(
            mediaType: 'movie',
            language: language,
            params: <String, String>{
              'with_original_language': 'fr|it|es|ja|ko|de|sv',
              'vote_average.gte': '7.4',
              'vote_count.gte': '300',
              'sort_by': 'vote_average.desc',
            },
          )).results;
        } else if (_selectedAwardMode == 'bafta') {
          return (await tmdb.discover(
            mediaType: 'movie',
            language: language,
            params: <String, String>{
              'with_origin_country': 'GB',
              'vote_average.gte': '7.5',
              'vote_count.gte': '400',
              'sort_by': 'vote_average.desc',
            },
          )).results;
        } else if (_selectedAwardMode == 'globes') {
          return (await tmdb.discover(
            mediaType: 'movie',
            language: language,
            params: <String, String>{
              'vote_average.gte': '7.8',
              'vote_count.gte': '800',
              'sort_by': 'popularity.desc',
            },
          )).results;
        } else {
          return (await tmdb.discover(
            mediaType: 'movie',
            language: language,
            params: <String, String>{
              'vote_average.gte': '8.0',
              'vote_count.gte': '1500',
              'sort_by': 'vote_average.desc',
            },
          )).results;
        }
      case 'movies':
        return (await tmdb.trending(
          mediaType: 'movie',
          timeWindow: 'week',
          language: language,
        )).results;
      case 'tv':
        return (await tmdb.trending(
          mediaType: 'tv',
          timeWindow: 'week',
          language: language,
        )).results;
      case 'watch-history':
      case 'print-watchlist':
      case 'enhanced-stats':
        return (await tmdb.trending(
          mediaType: 'all',
          timeWindow: 'week',
          language: language,
        )).results;
      default:
        return (await tmdb.trending(
          mediaType: 'movie',
          timeWindow: 'week',
          language: language,
        )).results;
    }
  }

  List<String> _getDecadeRange(String decade) {
    switch (decade) {
      case '2020s':
        return ['2020-01-01', '2029-12-31'];
      case '2010s':
        return ['2010-01-01', '2019-12-31'];
      case '2000s':
        return ['2000-01-01', '2009-12-31'];
      case '1990s':
        return ['1990-01-01', '1999-12-31'];
      case '1980s':
        return ['1980-01-01', '1989-12-31'];
      case '1970s':
        return ['1970-01-01', '1979-12-31'];
      case '1960s':
        return ['1960-01-01', '1969-12-31'];
      case '1950s':
        return ['1950-01-01', '1959-12-31'];
      default:
        return ['2020-01-01', '2029-12-31'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        color: theme.colorScheme.primary,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Mode-specific Header & Filters
            if (widget.mode == 'genres') ...[
              _buildGenresHeader(theme),
              const SizedBox(height: 16),
            ] else if (widget.mode == 'decades') ...[
              _buildDecadesHeader(theme),
              const SizedBox(height: 16),
            ] else if (widget.mode == 'awards') ...[
              _buildAwardsHeader(theme),
              const SizedBox(height: 16),
            ] else if (widget.mode == 'calendar' ||
                widget.mode == 'upcoming') ...[
              _buildCalendarHeader(theme),
              const SizedBox(height: 16),
            ] else if (widget.mode == 'quests') ...[
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator.adaptive()),
                )
              else
                _buildQuestsView(theme, isDark),
            ] else if (widget.mode == 'stats' ||
                widget.mode == 'enhanced-stats') ...[
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator.adaptive()),
                )
              else
                _buildStatsView(theme, isDark),
            ],

            if (widget.mode != 'quests' &&
                widget.mode != 'stats' &&
                widget.mode != 'enhanced-stats') ...[
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator.adaptive()),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: AppErrorCard(message: _error!, onRetry: _load),
                )
              else if (_items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.movie_filter_outlined,
                          size: 48,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.35,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No titles found.',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Refresh'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                _buildMediaGrid(theme, isDark),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildGenresHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Browse by Film Genre',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _genreList.map((g) {
              final isSelected = (_selectedGenreId ?? 28) == g['id'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  avatar: Icon(
                    g['icon'] as IconData,
                    size: 16,
                    color: g['color'] as Color,
                  ),
                  label: Text(g['name'] as String),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _selectedGenreId = g['id'] as int);
                    _load();
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDecadesHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Travel Through Cinema History',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _decadesList.map((d) {
              final isSelected = _selectedDecade == d;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(d),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _selectedDecade = d);
                    _load();
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAwardsHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Award-Winning Cinema',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _awardsList.map((a) {
            final isSelected = _selectedAwardMode == a['id'];
            return ChoiceChip(
              avatar: const Icon(
                Icons.emoji_events_rounded,
                size: 16,
                color: Color(0xFFFFB300),
              ),
              label: Text(a['name']!),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedAwardMode = a['id']!);
                _load();
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCalendarHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Release Calendar & TV Schedule',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Track upcoming theatrical debuts and returning TV series.',
          style: GoogleFonts.dmSans(
            fontSize: 12.5,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        if (_calendarShows.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Your Tracked Series Schedule',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _calendarShows.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final show = _calendarShows[index];
                return GestureDetector(
                  onTap: () => context.push('/details/tv/${show.id}'),
                  child: Container(
                    width: 120,
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color ?? theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: show.posterPath != null
                                ? CachedNetworkImage(
                                    imageUrl:
                                        'https://image.tmdb.org/t/p/w342${show.posterPath}',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  )
                                : Container(
                                    color: theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    child: const Center(
                                      child: Icon(Icons.tv_outlined),
                                    ),
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(6),
                            child: Text(
                              show.displayTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Theatrical & Now Playing Calendar',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuestsView(ThemeData theme, bool isDark) {
    final movieCount = _libraryItems
        .where((i) => i.mediaType == 'movie')
        .length;
    final quest1Progress = (movieCount / 3).clamp(0.0, 1.0);
    final quest2Progress = (_watchedEpisodesCount / 10).clamp(0.0, 1.0);
    final quest3Progress = (_watchlistCount / 5).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              Row(
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFFFFB300),
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Monthly CineQuests',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Complete challenges this month to earn XP and level up your trek rank.',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),
              _QuestTile(
                title: 'Movie Odyssey',
                desc: 'Watch 3 full feature films',
                progress: quest1Progress,
                progressLabel: '$movieCount / 3 movies',
                theme: theme,
              ),
              const Divider(height: 20),
              _QuestTile(
                title: 'Episode Marathon',
                desc: 'Track 10 TV series episodes',
                progress: quest2Progress,
                progressLabel: '$_watchedEpisodesCount / 10 episodes',
                theme: theme,
              ),
              const Divider(height: 20),
              _QuestTile(
                title: 'Watchlist Architect',
                desc: 'Add 5 titles to your watchlist',
                progress: quest3Progress,
                progressLabel: '$_watchlistCount / 5 titles',
                theme: theme,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsView(ThemeData theme, bool isDark) {
    final watchHours =
        (_watchedCount * 115 ~/ 60) + (_watchedEpisodesCount * 45 ~/ 60);
    final watchDays = (watchHours / 24).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Viewing Statistics & Insights',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatMetricBox(
                label: 'Watch Time',
                value: '$watchDays days',
                sub: '$watchHours hours estimated',
                theme: theme,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatMetricBox(
                label: 'Titles Seen',
                value: '$_watchedCount',
                sub: '$_watchlistCount in watchlist',
                theme: theme,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
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
              Text(
                'Top Categories & Breakdown',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _GenreProgressRow(
                label: 'Feature Films',
                percentage: _watchedCount > 0
                    ? (_libraryItems
                                  .where((i) => i.mediaType == 'movie')
                                  .length /
                              _watchedCount)
                          .clamp(0.1, 1.0)
                    : 0.65,
                theme: theme,
              ),
              const SizedBox(height: 8),
              _GenreProgressRow(
                label: 'TV Episodes & Series',
                percentage: _watchedCount > 0
                    ? (_watchedEpisodesCount / (_watchedCount + 1)).clamp(
                        0.1,
                        1.0,
                      )
                    : 0.35,
                theme: theme,
              ),
              const SizedBox(height: 8),
              _GenreProgressRow(
                label: 'Watchlist Discovery',
                percentage:
                    (_watchlistCount / (_watchlistCount + _watchedCount + 1))
                        .clamp(0.1, 1.0),
                theme: theme,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMediaGrid(ThemeData theme, bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        final posterUrl = item.posterPath != null
            ? 'https://image.tmdb.org/t/p/w342${item.posterPath}'
            : null;

        return GestureDetector(
          onTap: () => context.push('/details/${item.mediaKind}/${item.id}'),
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
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (posterUrl != null)
                          CachedNetworkImage(
                            imageUrl: posterUrl,
                            fit: BoxFit.cover,
                          )
                        else
                          Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.movie_outlined),
                          ),
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
                                    item.voteAverage.toStringAsFixed(1),
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
                        if (item.year != null)
                          Text(
                            '${item.year}',
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
      },
    );
  }
}

class _QuestTile extends StatelessWidget {
  const _QuestTile({
    required this.title,
    required this.desc,
    required this.progress,
    required this.progressLabel,
    required this.theme,
  });

  final String title;
  final String desc;
  final double progress;
  final String progressLabel;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              progressLabel,
              style: GoogleFonts.dmSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          desc,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: theme.colorScheme.secondary,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatMetricBox extends StatelessWidget {
  const _StatMetricBox({
    required this.label,
    required this.value,
    required this.sub,
    required this.theme,
    required this.isDark,
  });

  final String label;
  final String value;
  final String sub;
  final ThemeData theme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          Text(
            sub,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.50),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenreProgressRow extends StatelessWidget {
  const _GenreProgressRow({
    required this.label,
    required this.percentage,
    required this.theme,
  });

  final String label;
  final double percentage;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              '${(percentage * 100).toInt()}%',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 5,
            backgroundColor: theme.colorScheme.secondary,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

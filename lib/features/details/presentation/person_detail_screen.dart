import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api/tmdb_api_service.dart';
import '../../../core/errors/app_error_messages.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/models/media_models.dart';
import '../../../shared/widgets/app_error_card.dart';
import '../../../shared/widgets/app_cached_image.dart';

class PersonDetailScreen extends ConsumerStatefulWidget {
  const PersonDetailScreen({super.key, required this.personId});

  final int personId;

  @override
  ConsumerState<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends ConsumerState<PersonDetailScreen> {
  late Future<TmdbPersonDetails> _future;
  String? _lastLanguage;

  @override
  void initState() {
    super.initState();
    final language = ref.read(tmdbLanguageProvider);
    _lastLanguage = language;
    _future = ref
        .read(tmdbApiServiceProvider)
        .personDetails(personId: widget.personId, language: language);
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(tmdbLanguageProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ref.listen<String>(tmdbLanguageProvider, (previous, next) {
      if (previous == null || previous == next || next == _lastLanguage) {
        return;
      }

      _lastLanguage = next;
      setState(() {
        _future = ref
            .read(tmdbApiServiceProvider)
            .personDetails(personId: widget.personId, language: next);
      });
    });

    return Scaffold(
      body: FutureBuilder<TmdbPersonDetails>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
                ),
              ),
              body: const Center(child: CircularProgressIndicator.adaptive()),
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
                ),
              ),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: AppErrorCard(
                    message: describeAppError(snapshot.error!),
                    onRetry: () {
                      setState(() {
                        _future = ref
                            .read(tmdbApiServiceProvider)
                            .personDetails(
                              personId: widget.personId,
                              language: language,
                            );
                      });
                    },
                  ),
                ),
              ),
            );
          }

          final person = snapshot.data;
          if (person == null) {
            return Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
                ),
              ),
              body: const Center(child: Text('Person not found.')),
            );
          }

          return RefreshIndicator(
            color: theme.colorScheme.primary,
            onRefresh: () async {
              setState(() {
                _lastLanguage = language;
                _future = ref
                    .read(tmdbApiServiceProvider)
                    .personDetails(
                      personId: widget.personId,
                      language: language,
                    );
              });
              await _future;
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 320,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      person.name ?? 'Unknown person',
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w700,
                        shadows: [
                          const Shadow(color: Colors.black87, blurRadius: 8),
                        ],
                      ),
                    ),
                    background: _PersonBackdrop(person: person),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PersonHeader(person: person),
                        const SizedBox(height: 20),
                        if ((person.biography ?? '').isNotEmpty) ...[
                          Text(
                            'Biography',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            person.biography ?? '',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              height: 1.6,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.75,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        if (person.combinedCredits.isNotEmpty) ...[
                          Text(
                            'Known for',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.4,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 280,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: person.combinedCredits.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final item = person.combinedCredits[index];
                                final heroTag =
                                    'hero-${item.mediaKind}-${item.id}-person_credits';
                                return GestureDetector(
                                  onTap: () => context.push(
                                    '/details/${item.mediaKind}/${item.id}?heroTag=${Uri.encodeComponent(heroTag)}',
                                  ),
                                  child: SizedBox(
                                    width: 140,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Hero(
                                          tag: heroTag,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: theme
                                                    .colorScheme
                                                    .outlineVariant
                                                    .withValues(alpha: 0.55),
                                                width: 1,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(
                                                        alpha: isDark
                                                            ? 0.28
                                                            : 0.06,
                                                      ),
                                                  blurRadius: 16,
                                                  offset: const Offset(0, 6),
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: AspectRatio(
                                                aspectRatio: 2 / 3,
                                                child: AppCachedImage(
                                                  imageUrl:
                                                      item.imagePath == null
                                                      ? ''
                                                      : 'https://image.tmdb.org/t/p/w342${item.imagePath}',
                                                  fit: BoxFit.cover,
                                                  errorIcon: Icons.movie_outlined,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          item.displayTitle,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.dmSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            height: 1.3,
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
                        const SizedBox(height: 32),
                      ],
                    ),
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

class _PersonBackdrop extends StatelessWidget {
  const _PersonBackdrop({required this.person});

  final TmdbPersonDetails person;

  @override
  Widget build(BuildContext context) {
    final profilePath = person.profilePath;
    if (profilePath == null) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        AppCachedImage(
          imageUrl: 'https://image.tmdb.org/t/p/original$profilePath',
          fit: BoxFit.cover,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.2),
                Colors.black.withValues(alpha: 0.7),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PersonHeader extends StatelessWidget {
  const _PersonHeader({required this.person});

  final TmdbPersonDetails person;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
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
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 2 / 3,
                child: AppCachedImage(
                  imageUrl: person.profilePath == null
                      ? ''
                      : 'https://image.tmdb.org/t/p/w342${person.profilePath}',
                  fit: BoxFit.cover,
                  errorIcon: Icons.person_outline,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.name ?? 'Unknown person',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    person.knownForDepartment ?? 'Actor',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Popularity ${person.popularity.toStringAsFixed(1)}',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                if (person.birthday != null || person.deathday != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    [
                      person.birthday,
                      person.deathday != null
                          ? 'Died ${person.deathday}'
                          : null,
                    ].whereType<String>().join(' · '),
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.55,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

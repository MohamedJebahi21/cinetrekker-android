import '../../../core/api/supabase_rest_api.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/widgets/bouncy_pressable.dart';
import '../../../core/motion/haptic_service.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/auth/auth_session.dart';
import '../../../core/models/media_models.dart';
import '../../watchlist/data/user_library_repository.dart';
import '../data/profile_repository.dart';
import '../../social/data/social_repository.dart';
import '../../../shared/widgets/app_cached_image.dart';

class PublicProfileScreen extends ConsumerStatefulWidget {
  const PublicProfileScreen({required this.userId, super.key});

  final String userId;

  @override
  ConsumerState<PublicProfileScreen> createState() =>
      _PublicProfileScreenState();
}

class _PublicProfileScreenState extends ConsumerState<PublicProfileScreen> {
  UserProfileData? _profile;
  List<UserMediaItem> _recentWatched = const <UserMediaItem>[];
  int _watchedCount = 0;
  int _movieCount = 0;
  int _tvCount = 0;
  int _watchlistCount = 0;
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _followBusy = false;
  String? _error;

  CineTrekkerAuthUser? get _currentUser =>
      ref.read(authControllerProvider).valueOrNull?.user;

  bool get _isOwnProfile => _currentUser?.id == widget.userId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (widget.userId.trim().isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'This profile could not be found.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final profile = await ProfileRepository(
        api: ref.read(supabaseRestApiProvider),
        userId: widget.userId,
      ).loadPublicProfile(widget.userId);
      if (!mounted) return;
      if (profile == null) {
        setState(() {
          _isLoading = false;
          _error = 'This profile does not exist or is private.';
        });
        return;
      }

      final currentUser = _currentUser;
      final social = ref.read(socialRepositoryProvider);
      final following = currentUser != null && currentUser.id != widget.userId
          ? (await social.getFollowingIds()).contains(widget.userId)
          : false;

      var recent = const <UserMediaItem>[];
      var watched = 0;
      var movies = 0;
      var tv = 0;
      var watchlist = 0;
      final profileRepo = ProfileRepository(
        api: ref.read(supabaseRestApiProvider),
        userId: widget.userId,
      );

      if (_isOwnProfile) {
        final library = ref.read(userLibraryRepositoryProvider);
        final watchedItems = await library.getWatched();
        final watchlistItems = await library.getWatchlist();
        final unique = <String, UserMediaItem>{
          for (final item in watchedItems)
            '${item.mediaType}:${item.mediaId}': item,
        };
        recent = unique.values.take(8).toList(growable: false);
        watched = unique.length;
        movies = unique.values
            .where((item) => item.mediaType == 'movie')
            .length;
        tv = unique.values.where((item) => item.mediaType == 'tv').length;
        watchlist = watchlistItems.length;
      } else {
        final watchedItems = await profileRepo.loadPublicUserLibrary(
          widget.userId,
          listType: 'watched',
        );
        final watchlistItems = await profileRepo.loadPublicUserLibrary(
          widget.userId,
          listType: 'watchlist',
        );
        final unique = <String, UserMediaItem>{
          for (final item in watchedItems)
            '${item.mediaType}:${item.mediaId}': item,
        };
        recent = unique.values.take(8).toList(growable: false);
        watched = unique.length;
        movies = unique.values
            .where((item) => item.mediaType == 'movie')
            .length;
        tv = unique.values.where((item) => item.mediaType == 'tv').length;
        watchlist = watchlistItems.length;
      }
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _recentWatched = recent;
        _watchedCount = watched;
        _movieCount = movies;
        _tvCount = tv;
        _watchlistCount = watchlist;
        _isFollowing = following;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Unable to load this profile: $error';
      });
    }
  }

  Future<void> _toggleFollow() async {
    final session = ref.read(authControllerProvider).valueOrNull;
    final social = ref.read(socialRepositoryProvider);
    if (session == null) {
      if (mounted) context.push('/auth');
      return;
    }
    setState(() => _followBusy = true);
    try {
      if (_isFollowing) {
        Haptics.light();
        await social.unfollowUser(widget.userId);
      } else {
        Haptics.follow();
        await social.followUser(widget.userId);
      }
      if (!mounted) return;
      setState(() {
        _isFollowing = !_isFollowing;
        _followBusy = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _followBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update follow status: $error')),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Profile',
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
          ),
        ),
        body: const Center(child: CircularProgressIndicator.adaptive()),
      );
    }
    if (_error != null || _profile == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Profile',
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_off_outlined,
                  size: 56,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                ),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Profile not found.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(fontSize: 14),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.home_outlined),
                  label: Text(
                    'Go to home',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final profile = _profile!;
    final initial =
        (profile.displayName?.trim().isNotEmpty == true
                ? profile.displayName!.trim()[0]
                : '?')
            .toUpperCase();
    final canShowStats = _isOwnProfile && profile.showStats;
    final canShowWatched = _isOwnProfile && profile.showWatchlist;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          profile.displayName ?? 'Profile',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        color: theme.colorScheme.primary,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 2.5,
                  ),
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.12,
                  ),
                  backgroundImage: profile.avatarUrl == null
                      ? null
                      : CachedNetworkImageProvider(profile.avatarUrl!),
                  child: profile.avatarUrl == null
                      ? Text(
                          initial,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              profile.displayName?.trim().isNotEmpty == true
                  ? profile.displayName!.trim()
                  : 'CineTrekker user',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (profile.bio?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                profile.bio!.trim(),
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ],
            if (!_isOwnProfile) ...[
              const SizedBox(height: 18),
              Center(
                child: FilledButton.icon(
                  onPressed: _followBusy ? null : _toggleFollow,
                  style: FilledButton.styleFrom(
                    backgroundColor: _isFollowing
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.primary,
                    foregroundColor: _isFollowing
                        ? theme.colorScheme.onSurface
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: _isFollowing
                          ? BorderSide(color: theme.colorScheme.outlineVariant)
                          : BorderSide.none,
                    ),
                  ),
                  icon: _followBusy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          _isFollowing
                              ? Icons.person_remove_outlined
                              : Icons.person_add_outlined,
                          size: 18,
                        ),
                  label: Text(
                    _isFollowing ? 'Unfollow' : 'Follow',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
            if (canShowStats) ...[
              const SizedBox(height: 24),
              _StatsCard(
                watchedCount: _watchedCount,
                movieCount: _movieCount,
                tvCount: _tvCount,
                watchlistCount: _watchlistCount,
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Recently watched',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            if (canShowWatched && _recentWatched.isNotEmpty)
              ..._recentWatched.map((item) => _WatchedRow(item: item))
            else
              Container(
                padding: const EdgeInsets.all(18),
                decoration: _glassCard(theme, isDark),
                child: Text(
                  _isOwnProfile
                      ? 'No watched items yet.'
                      : 'This user’s watched activity is not public.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.watchedCount,
    required this.movieCount,
    required this.tvCount,
    required this.watchlistCount,
  });

  final int watchedCount;
  final int movieCount;
  final int tvCount;
  final int watchlistCount;

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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(label: 'Watched', value: watchedCount),
          _Stat(label: 'Movies', value: movieCount),
          _Stat(label: 'TV shows', value: tvCount),
          _Stat(label: 'Watchlist', value: watchlistCount),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.50),
          ),
        ),
      ],
    );
  }
}

class _WatchedRow extends StatelessWidget {
  const _WatchedRow({required this.item});

  final UserMediaItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        type: MaterialType.transparency,
        child: BouncyPressable(
          onTap: () =>
              context.push('/details/${item.mediaType}/${item.mediaId}'),
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              leading: item.posterPath != null
                  ? AppCachedImage(
                      imageUrl:
                          'https://image.tmdb.org/t/p/w185${item.posterPath}',
                      width: 38,
                      height: 56,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(8),
                      errorIcon: item.mediaType == 'tv' ? Icons.tv_outlined : Icons.movie_outlined,
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _posterFallback(theme, item),
                    ),
              title: Text(
                item.displayTitle,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: item.watchedAt == null
                  ? null
                  : Text(
                      'Watched ${item.watchedAt}',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.50),
                      ),
                    ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _posterFallback(ThemeData theme, UserMediaItem item) {
    return Container(
      width: 38,
      height: 56,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        item.mediaType == 'tv' ? Icons.tv_outlined : Icons.movie_outlined,
        color: theme.colorScheme.primary,
        size: 20,
      ),
    );
  }
}

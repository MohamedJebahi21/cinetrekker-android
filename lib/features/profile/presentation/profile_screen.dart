import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../shared/widgets/app_error_card.dart';
import '../data/profile_repository.dart';
import 'profile_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isPublic = false;
  bool _showWatchlist = true;
  bool _showStats = true;
  bool _allowRecommendations = true;
  String? _syncedProfileSignature;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileControllerProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _syncFields(UserProfileData? profile) {
    if (profile == null) {
      _displayNameController.clear();
      _bioController.clear();
      _isPublic = false;
      _showWatchlist = true;
      _showStats = true;
      _allowRecommendations = true;
      _syncedProfileSignature = null;
      return;
    }

    final signature =
        '${profile.userId}:${profile.updatedAt?.toIso8601String() ?? ''}';
    if (signature == _syncedProfileSignature) return;
    _displayNameController.text = profile.displayName ?? '';
    _bioController.text = profile.bio ?? '';
    _isPublic = profile.isPublic;
    _showWatchlist = profile.showWatchlist;
    _showStats = profile.showStats;
    _allowRecommendations = profile.allowRecommendations;
    _syncedProfileSignature = signature;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);
    _syncFields(state.profile);
    final session = ref.watch(authControllerProvider).valueOrNull;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    final watchedCount = state.watchedCount;
    String levelName = 'Casual Viewer';
    int nextMilestone = 50;
    int prevMilestone = 0;
    if (watchedCount <= 50) {
      levelName = 'Casual Viewer';
      nextMilestone = 50;
      prevMilestone = 0;
    } else if (watchedCount <= 150) {
      levelName = 'Movie Buff';
      nextMilestone = 150;
      prevMilestone = 50;
    } else if (watchedCount <= 300) {
      levelName = 'Cinephile';
      nextMilestone = 300;
      prevMilestone = 150;
    } else {
      levelName = 'Film Historian';
      nextMilestone = 600;
      prevMilestone = 300;
    }

    final double progress = nextMilestone == prevMilestone
        ? 1.0
        : ((watchedCount - prevMilestone) / (nextMilestone - prevMilestone))
              .clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: theme.colorScheme.primary,
        onRefresh: () => ref.read(profileControllerProvider.notifier).load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (state.error != null) ...[
              AppErrorCard(
                message: state.error!,
                onRetry: () =>
                    ref.read(profileControllerProvider.notifier).load(),
              ),
              const SizedBox(height: 16),
            ],
            if (state.isLoading) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator.adaptive()),
              ),
            ] else ...[
              // User info card
              if (session != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: _glassCard(theme, isDark),
                  child: Column(
                    children: [
                      // Avatar + Level Badge
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: primary.withValues(alpha: 0.15),
                            backgroundImage: session.user.avatarUrl != null
                                ? NetworkImage(session.user.avatarUrl!)
                                : null,
                            child: session.user.avatarUrl == null
                                ? Text(
                                    (session.user.displayName.isNotEmpty
                                            ? session.user.displayName[0]
                                            : 'U')
                                        .toUpperCase(),
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: primary,
                                    ),
                                  )
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: primary,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: theme.colorScheme.surface,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        session.user.displayName,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        session.user.email ?? '',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.55,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Cinephile Level Chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: primary.withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          levelName,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: _glassCard(theme, isDark),
                  child: Column(
                    children: [
                      Text(
                        'Welcome to CineTrekker',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in to synchronize your profile, watchlist, achievements, and stats across devices.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: () => context.push('/login'),
                        child: const Text('Sign in / Register'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Milestone Progress Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _glassCard(theme, isDark),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Next Milestone',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '$watchedCount / $nextMilestone watched',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(primary),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${nextMilestone - watchedCount > 0 ? nextMilestone - watchedCount : 0} more titles to reach the next tier!',
                      style: GoogleFonts.dmSans(
                        fontSize: 11.5,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.55,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Stats row (Watchlist, Watched, Favorites)
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Watchlist',
                      value: '${state.watchlistCount}',
                      icon: Icons.bookmark_rounded,
                      theme: theme,
                      isDark: isDark,
                      onTap: () => context.push('/watchlist'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      label: 'Watched',
                      value: '${state.watchedCount}',
                      icon: Icons.check_circle_rounded,
                      theme: theme,
                      isDark: isDark,
                      onTap: () => context.push('/watched'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      label: 'Favorites',
                      value: '${state.favorites.length}',
                      icon: Icons.favorite_rounded,
                      theme: theme,
                      isDark: isDark,
                      onTap: () => context.push('/favorites'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Navigation Links
            Container(
              decoration: _glassCard(theme, isDark),
              child: Column(
                children: [
                  _ProfileNavTile(
                    icon: Icons.folder_outlined,
                    label: 'My Collections',
                    subtitle: 'Create and organize custom lists',
                    onTap: () => context.push('/collections'),
                    theme: theme,
                  ),
                  const Divider(height: 1),
                  _ProfileNavTile(
                    icon: Icons.emoji_events_outlined,
                    label: 'Achievements & Quests',
                    subtitle: 'Badges and monthly challenges',
                    onTap: () => context.push('/achievements'),
                    theme: theme,
                  ),
                  const Divider(height: 1),
                  _ProfileNavTile(
                    icon: Icons.auto_awesome_outlined,
                    label: 'Year in Review',
                    subtitle: 'Annual wrapped summary and stats',
                    onTap: () => context.push('/year-in-review'),
                    theme: theme,
                  ),
                  const Divider(height: 1),
                  _ProfileNavTile(
                    icon: Icons.people_outline_rounded,
                    label: 'Community & People',
                    subtitle: 'Follow fellow cinephiles',
                    onTap: () => context.push('/people'),
                    theme: theme,
                  ),
                  const Divider(height: 1),
                  _ProfileNavTile(
                    icon: Icons.settings_outlined,
                    label: 'App Settings',
                    subtitle: 'Appearance, language, data & privacy',
                    onTap: () => context.push('/settings'),
                    theme: theme,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Profile Edit Form (if signed in)
            if (session != null) ...[
              Text(
                'Edit Profile',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _glassCard(theme, isDark),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _displayNameController,
                        decoration: const InputDecoration(
                          labelText: 'Display Name',
                          isDense: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter your display name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _bioController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Bio',
                          hintText: 'A few words about your movie tastes…',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Public Profile',
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          'Allow others to discover your profile and lists',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.55,
                            ),
                          ),
                        ),
                        value: _isPublic,
                        onChanged: (val) => setState(() => _isPublic = val),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () async {
                            if (!_formKey.currentState!.validate()) return;
                            await ref
                                .read(profileControllerProvider.notifier)
                                .save(
                                  displayName: _displayNameController.text
                                      .trim(),
                                  bio: _bioController.text.trim(),
                                  isPublic: _isPublic,
                                  showWatchlist: _showWatchlist,
                                  showStats: _showStats,
                                  allowRecommendations: _allowRecommendations,
                                );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Profile updated successfully'),
                                ),
                              );
                            }
                          },
                          child: const Text('Save Changes'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  BoxDecoration _glassCard(ThemeData theme, bool isDark) {
    return BoxDecoration(
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
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.theme,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final ThemeData theme;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
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
        child: Column(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileNavTile extends StatelessWidget {
  const _ProfileNavTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: theme.colorScheme.primary),
      ),
      title: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.dmSans(
          fontSize: 11.5,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
      ),
    );
  }
}

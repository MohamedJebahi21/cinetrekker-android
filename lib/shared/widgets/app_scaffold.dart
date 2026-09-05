import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/auth/auth_controller.dart';
import '../../features/profile/presentation/profile_controller.dart';
import '../../features/social/presentation/notifications_controller.dart';

class AppScaffold extends ConsumerStatefulWidget {
  const AppScaffold({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  @override
  ConsumerState<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends ConsumerState<AppScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedIndex() {
    if (widget.location.startsWith('/discover') ||
        widget.location.startsWith('/genres') ||
        widget.location.startsWith('/decades') ||
        widget.location.startsWith('/awards') ||
        widget.location.startsWith('/recommendations') ||
        widget.location.startsWith('/movies') ||
        widget.location.startsWith('/tv')) {
      return 1;
    }
    if (widget.location.startsWith('/search')) return 2;
    if (widget.location.startsWith('/watchlist') ||
        widget.location.startsWith('/watched') ||
        widget.location.startsWith('/calendar') ||
        widget.location.startsWith('/upcoming')) {
      return 3;
    }
    if (widget.location.startsWith('/profile') ||
        widget.location.startsWith('/settings') ||
        widget.location.startsWith('/achievements') ||
        widget.location.startsWith('/quests') ||
        widget.location.startsWith('/stats') ||
        widget.location.startsWith('/collections')) {
      return 4;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex();
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final surface = theme.colorScheme.surface;

    final authState = ref.watch(authControllerProvider);
    final user = authState.valueOrNull?.user;
    final profileState = ref.watch(profileControllerProvider);
    final notifsState = ref.watch(notificationsControllerProvider);
    final hasUnreadNotifs = notifsState.notifications.any((n) => !n.isRead);

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: _CineTrekkerDrawer(
        user: user,
        profileState: profileState,
        currentPath: widget.location,
        onClose: () => Navigator.of(context).pop(),
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: BoxDecoration(
            color: surface.withValues(alpha: 0.95),
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Logo & Brand
                  GestureDetector(
                    onTap: () => context.go('/'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 30,
                            height: 30,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'CineTrekker',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Search icon
                  IconButton(
                    onPressed: () => context.push('/search'),
                    icon: Icon(
                      Icons.search_rounded,
                      color: onSurface.withValues(alpha: 0.75),
                      size: 22,
                    ),
                    tooltip: 'Search',
                  ),
                  // Notifications icon (if logged in)
                  if (user != null)
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          onPressed: () => context.push('/social'),
                          icon: Icon(
                            Icons.notifications_outlined,
                            color: onSurface.withValues(alpha: 0.75),
                            size: 22,
                          ),
                          tooltip: 'Notifications',
                        ),
                        if (hasUnreadNotifs)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: surface, width: 1.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                  // Hamburger Drawer trigger
                  IconButton(
                    onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                    icon: Icon(
                      Icons.menu_rounded,
                      color: onSurface.withValues(alpha: 0.85),
                      size: 24,
                    ),
                    tooltip: 'Menu',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(bottom: false, child: widget.child),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: surface,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          backgroundColor: Colors.transparent,
          elevation: 0,
          indicatorColor: primary.withValues(alpha: 0.14),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) {
            HapticFeedback.selectionClick();
            final destination = switch (index) {
              0 => '/',
              1 => '/discover',
              2 => '/search',
              3 => '/watchlist',
              _ => '/profile',
            };
            context.go(destination);
          },
          destinations: [
            _buildNavDestination(
              context: context,
              icon: Icons.home_outlined,
              selectedIcon: Icons.home_rounded,
              label: 'Home',
              isSelected: selectedIndex == 0,
              primary: primary,
              onSurface: onSurface,
            ),
            _buildNavDestination(
              context: context,
              icon: Icons.explore_outlined,
              selectedIcon: Icons.explore_rounded,
              label: 'Discover',
              isSelected: selectedIndex == 1,
              primary: primary,
              onSurface: onSurface,
            ),
            _buildNavDestination(
              context: context,
              icon: Icons.search_outlined,
              selectedIcon: Icons.search_rounded,
              label: 'Search',
              isSelected: selectedIndex == 2,
              primary: primary,
              onSurface: onSurface,
            ),
            _buildNavDestination(
              context: context,
              icon: Icons.bookmark_outline_rounded,
              selectedIcon: Icons.bookmark_rounded,
              label: 'Watchlist',
              isSelected: selectedIndex == 3,
              primary: primary,
              onSurface: onSurface,
            ),
            _buildNavDestination(
              context: context,
              icon: Icons.person_outline_rounded,
              selectedIcon: Icons.person_rounded,
              label: 'Profile',
              isSelected: selectedIndex == 4,
              primary: primary,
              onSurface: onSurface,
            ),
          ],
        ),
      ),
    );
  }

  NavigationDestination _buildNavDestination({
    required BuildContext context,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool isSelected,
    required Color primary,
    required Color onSurface,
  }) {
    return NavigationDestination(
      icon: Icon(icon, color: onSurface.withValues(alpha: 0.55)),
      selectedIcon: Icon(selectedIcon, color: primary),
      label: label,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Navigation Drawer matching website's UnifiedNav slide-over menu
// ─────────────────────────────────────────────────────────────────────────────

class _CineTrekkerDrawer extends ConsumerWidget {
  const _CineTrekkerDrawer({
    required this.user,
    required this.profileState,
    required this.currentPath,
    required this.onClose,
  });

  final dynamic user;
  final ProfileState profileState;
  final String currentPath;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final watchedCount = profileState.watchedCount;

    // Milestone calculation matching website:
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

    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Menu',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Browse tools & library',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.55,
                          ),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: Icon(
                      Icons.close_rounded,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scrollable Menu Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                children: [
                  // User Progress Card OR Guest CTA Card
                  if (user != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color:
                            theme.cardTheme.color ?? theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: primary,
                                    width: 1.5,
                                  ),
                                ),
                                child: CircleAvatar(
                                  backgroundColor: primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  backgroundImage: user.avatarUrl == null
                                      ? null
                                      : CachedNetworkImageProvider(
                                          user.avatarUrl!,
                                        ),
                                  child: user.avatarUrl == null
                                      ? Icon(
                                          Icons.person_rounded,
                                          color: primary,
                                          size: 20,
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'TREK PROGRESS',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                        color: primary,
                                      ),
                                    ),
                                    Text(
                                      user.displayName ?? 'Cinephile',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondary,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant,
                                  ),
                                ),
                                child: Text(
                                  levelName,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$watchedCount watched',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                              Text(
                                'Next: $nextMilestone',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: theme.colorScheme.secondary,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Make every visit personal',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sign in to sync watchlist, ratings & stats across devices.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  onPressed: () {
                                    onClose();
                                    context.push('/signup');
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: primary,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(0, 36),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    'Register',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    onClose();
                                    context.push('/login');
                                  },
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 36),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    'Sign In',
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
                    const SizedBox(height: 16),
                  ],

                  // Section 1: Personal Library
                  _DrawerGroup(
                    title: 'Personal Library',
                    theme: theme,
                    items: [
                      _DrawerItem(
                        icon: Icons.home_outlined,
                        label: 'Home',
                        desc: "Your personal feed and tonight's picks.",
                        path: '/',
                        currentPath: currentPath,
                        onTap: () {
                          onClose();
                          context.go('/');
                        },
                      ),
                      _DrawerItem(
                        icon: Icons.person_outline,
                        label: 'Profile',
                        desc: 'Manage your account, rank, and stats.',
                        path: '/profile',
                        currentPath: currentPath,
                        onTap: () {
                          onClose();
                          context.go('/profile');
                        },
                      ),
                      _DrawerItem(
                        icon: Icons.bookmark_outline_rounded,
                        label: 'Watchlist',
                        desc: 'Your list of titles to watch.',
                        path: '/watchlist',
                        currentPath: currentPath,
                        onTap: () {
                          onClose();
                          context.go('/watchlist');
                        },
                      ),
                      _DrawerItem(
                        icon: Icons.folder_outlined,
                        label: 'Collections',
                        desc: 'Curate themed lists worth sharing.',
                        path: '/collections',
                        currentPath: currentPath,
                        onTap: () {
                          onClose();
                          context.push('/collections');
                        },
                      ),
                      _DrawerItem(
                        icon: Icons.tv_outlined,
                        label: 'TV Tracking',
                        desc: 'Episodes you are tracking for updates.',
                        path: '/tv-tracking',
                        currentPath: currentPath,
                        onTap: () {
                          onClose();
                          context.push('/tv-tracking');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Section 2: Discovery & Explore
                  _DrawerGroup(
                    title: 'Discovery & Explore',
                    theme: theme,
                    items: [
                      _DrawerItem(
                        icon: Icons.explore_outlined,
                        label: 'Discover',
                        desc: 'Explore recommendations and releases.',
                        path: '/discover',
                        currentPath: currentPath,
                        onTap: () {
                          onClose();
                          context.go('/discover');
                        },
                      ),
                      _DrawerItem(
                        icon: Icons.local_fire_department_outlined,
                        label: 'Trending',
                        desc: "What's popular right now.",
                        path: '/trending',
                        currentPath: currentPath,
                        onTap: () {
                          onClose();
                          context.push('/trending');
                        },
                      ),
                      _DrawerItem(
                        icon: Icons.recommend_outlined,
                        label: 'Recommendations',
                        desc: 'Taste-matched suggestions for your next watch.',
                        path: '/recommendations',
                        currentPath: currentPath,
                        onTap: () {
                          onClose();
                          context.push('/recommendations');
                        },
                      ),
                      _DrawerItem(
                        icon: Icons.category_outlined,
                        label: 'Genres',
                        desc: 'Browse by specific film categories.',
                        path: '/genres',
                        currentPath: currentPath,
                        onTap: () {
                          onClose();
                          context.push('/genres');
                        },
                      ),
                      _DrawerItem(
                        icon: Icons.history_edu_outlined,
                        label: 'Decades',
                        desc: 'Travel through cinema history.',
                        path: '/decades',
                        currentPath: currentPath,
                        onTap: () {
                          onClose();
                          context.push('/decades');
                        },
                      ),
                      _DrawerItem(
                        icon: Icons.emoji_events_outlined,
                        label: 'Awards',
                        desc: 'Browse award winners and nominees.',
                        path: '/awards',
                        currentPath: currentPath,
                        onTap: () {
                          onClose();
                          context.push('/awards');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Section 3: Community & Insights
                  _DrawerGroup(
                    title: 'Community & Insights',
                    theme: theme,
                    items: [
                      _DrawerItem(
                        icon: Icons.people_outline_rounded,
                        label: 'People',
                        desc: 'Discover public profiles and fellow cinephiles.',
                        path: '/people',
                        currentPath: currentPath,
                        onTap: () {
                          onClose();
                          context.push('/people');
                        },
                      ),
                      _DrawerItem(
                        icon: Icons.calendar_today_outlined,
                        label: 'Calendar',
                        desc: 'TV schedule and movie release tracker.',
                        path: '/calendar',
                        currentPath: currentPath,
                        onTap: () {
                          onClose();
                          context.push('/calendar');
                        },
                      ),
                      _DrawerItem(
                        icon: Icons.military_tech_outlined,
                        label: 'Achievements',
                        desc: 'Trophies and milestones unlocked.',
                        path: '/achievements',
                        currentPath: currentPath,
                        onTap: () {
                          onClose();
                          context.push('/achievements');
                        },
                      ),
                      _DrawerItem(
                        icon: Icons.auto_awesome_outlined,
                        label: 'Year In Review',
                        desc: 'Your personal annual wrapped recap.',
                        path: '/year-in-review',
                        currentPath: currentPath,
                        onTap: () {
                          onClose();
                          context.push('/year-in-review');
                        },
                      ),
                      _DrawerItem(
                        icon: Icons.forum_outlined,
                        label: 'Social & Activity',
                        desc: 'Community notifications & discussions.',
                        path: '/social',
                        currentPath: currentPath,
                        onTap: () {
                          onClose();
                          context.push('/social');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Section 4: Preferences & Settings
                  _DrawerGroup(
                    title: 'Preferences',
                    theme: theme,
                    items: [
                      _DrawerItem(
                        icon: Icons.settings_outlined,
                        label: 'Settings',
                        desc: 'Account, appearance, safety & privacy.',
                        path: '/settings',
                        currentPath: currentPath,
                        onTap: () {
                          onClose();
                          context.push('/settings');
                        },
                      ),
                      _DrawerItem(
                        icon: Icons.accessibility_new_outlined,
                        label: 'Accessibility',
                        desc: 'Text scaling, motion & visual tweaks.',
                        path: '/accessibility',
                        currentPath: currentPath,
                        onTap: () {
                          onClose();
                          context.push('/accessibility');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerGroup extends StatelessWidget {
  const _DrawerGroup({
    required this.title,
    required this.theme,
    required this.items,
  });

  final String title;
  final ThemeData theme;
  final List<_DrawerItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ),
        const SizedBox(height: 4),
        ...items,
      ],
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.desc,
    required this.path,
    required this.currentPath,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String desc;
  final String path;
  final String currentPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = currentPath == path;
    final primary = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? primary.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? primary.withValues(alpha: 0.25)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isActive
                      ? primary.withValues(alpha: 0.15)
                      : theme.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isActive
                      ? primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13.5,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: isActive ? primary : theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      desc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive)
                Icon(Icons.arrow_forward_ios_rounded, size: 12, color: primary),
            ],
          ),
        ),
      ),
    );
  }
}

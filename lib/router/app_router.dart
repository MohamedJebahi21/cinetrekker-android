import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/auth_controller.dart';
import '../core/errors/app_error_messages.dart';
import '../core/motion/motion_tokens.dart';
import '../core/utils/analytics_service.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/achievements/presentation/achievements_screen.dart';
import '../features/discover/presentation/discover_screen.dart';
import '../features/details/presentation/details_screen.dart';
import '../features/details/presentation/person_detail_screen.dart';
import '../features/collections/presentation/collections_screen.dart';
import '../features/home/presentation/home_shell.dart';
import '../features/profile/presentation/public_profile_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/search/presentation/search_screen.dart';
import '../features/social/presentation/people_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/settings/presentation/feedback_screen.dart';
import '../features/settings/presentation/privacy_policy_screen.dart';
import '../features/settings/presentation/accessibility_screen.dart';
import '../features/settings/presentation/about_screen.dart';
import '../features/settings/presentation/cookies_screen.dart';
import '../features/settings/presentation/terms_screen.dart';
import '../features/social/presentation/social_screen.dart';
import '../features/tv_tracking/presentation/tv_tracking_screen.dart';
import '../features/year_in_review/presentation/year_in_review_screen.dart';
import '../features/watchlist/presentation/watchlist_screen.dart';
import '../features/parity/presentation/feature_parity_screen.dart';
import '../shared/widgets/app_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Premium transition: subtle slide-up + fade-in
Page<T> buildPageWithSlideTransition<T>({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: MotionTokens.pageEnter,
    reverseTransitionDuration: MotionTokens.pageExit,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
        return child;
      }
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.08),
          end: Offset.zero,
        ).chain(CurveTween(curve: MotionTokens.easeOut)).animate(animation),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
  );
}

/// Premium transition: clean cross-fade for tab switching
Page<T> buildPageWithFadeTransition<T>({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: MotionTokens.tabEnter,
    reverseTransitionDuration: MotionTokens.tabExit,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
        return child;
      }
      return FadeTransition(
        opacity: CurveTween(curve: MotionTokens.easeInOut).animate(animation),
        child: child,
      );
    },
  );
}

GoRoute parityRoute({
  required String path,
  required String title,
  required String mode,
}) => GoRoute(
  path: path,
  pageBuilder: (context, state) => buildPageWithFadeTransition(
    state: state,
    child: FeatureParityScreen(title: title, mode: mode),
  ),
);

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    observers: [ref.read(analyticsObserverProvider)],
    redirect: (context, state) {
      final location = state.uri.path;
      final isAuthRoute =
          location == '/auth' ||
          location == '/login' ||
          location == '/signup' ||
          location == '/auth/callback' ||
          location == '/auth/reset' ||
          location == '/reset';
      final hasSession = authState.valueOrNull != null;

      if (hasSession && isAuthRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      // ── Full-screen routes (no bottom nav) ────────────────────────
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/login',
        pageBuilder: (context, state) => buildPageWithSlideTransition(
          state: state,
          child: const AuthScreen(initialMode: AuthMode.signIn),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/signup',
        pageBuilder: (context, state) => buildPageWithSlideTransition(
          state: state,
          child: const AuthScreen(initialMode: AuthMode.signUp),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/auth/callback',
        pageBuilder: (context, state) => buildPageWithSlideTransition(
          state: state,
          child: const AuthScreen(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/auth',
        pageBuilder: (context, state) => buildPageWithSlideTransition(
          state: state,
          child: const AuthScreen(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/auth/reset',
        pageBuilder: (context, state) => buildPageWithSlideTransition(
          state: state,
          child: const AuthScreen(initialMode: AuthMode.reset),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/reset',
        pageBuilder: (context, state) => buildPageWithSlideTransition(
          state: state,
          child: const AuthScreen(initialMode: AuthMode.reset),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/details/:mediaType/:mediaId',
        pageBuilder: (context, state) {
          final mediaType = state.pathParameters['mediaType'] ?? 'movie';
          final mediaId =
              int.tryParse(state.pathParameters['mediaId'] ?? '') ?? 0;
          final heroTag = state.uri.queryParameters['heroTag'];
          return buildPageWithSlideTransition(
            state: state,
            child: DetailsScreen(
              mediaType: mediaType,
              mediaId: mediaId,
              heroTag: heroTag,
            ),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/person/:personId',
        pageBuilder: (context, state) {
          final personId =
              int.tryParse(state.pathParameters['personId'] ?? '') ?? 0;
          return buildPageWithSlideTransition(
            state: state,
            child: PersonDetailScreen(personId: personId),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/feedback',
        pageBuilder: (context, state) => buildPageWithSlideTransition(
          state: state,
          child: const FeedbackScreen(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/user/:userId',
        pageBuilder: (context, state) => buildPageWithSlideTransition(
          state: state,
          child: PublicProfileScreen(
            userId: state.pathParameters['userId'] ?? '',
          ),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/about',
        pageBuilder: (context, state) => buildPageWithSlideTransition(
          state: state,
          child: const AboutScreen(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/cookies',
        pageBuilder: (context, state) => buildPageWithSlideTransition(
          state: state,
          child: const CookiesScreen(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/terms',
        pageBuilder: (context, state) => buildPageWithSlideTransition(
          state: state,
          child: const TermsScreen(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/privacy',
        pageBuilder: (context, state) => buildPageWithSlideTransition(
          state: state,
          child: const PrivacyPolicyScreen(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/people',
        pageBuilder: (context, state) => buildPageWithSlideTransition(
          state: state,
          child: const PeopleScreen(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/collections',
        pageBuilder: (context, state) => buildPageWithSlideTransition(
          state: state,
          child: const CollectionsScreen(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/achievements',
        pageBuilder: (context, state) => buildPageWithSlideTransition(
          state: state,
          child: const AchievementsScreen(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/year-in-review',
        pageBuilder: (context, state) => buildPageWithSlideTransition(
          state: state,
          child: const YearInReviewScreen(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/tv-tracking',
        pageBuilder: (context, state) => buildPageWithSlideTransition(
          state: state,
          child: const TvTrackingScreen(),
        ),
      ),

      // ── Shell routes (with bottom nav bar) ────────────────────────
      ShellRoute(
        builder: (context, state, child) {
          return AppScaffold(location: state.uri.toString(), child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => buildPageWithFadeTransition(
              state: state,
              child: const HomeShell(),
            ),
          ),
          GoRoute(
            path: '/discover',
            pageBuilder: (context, state) => buildPageWithFadeTransition(
              state: state,
              child: const DiscoverScreen(),
            ),
          ),
          GoRoute(
            path: '/search',
            pageBuilder: (context, state) => buildPageWithFadeTransition(
              state: state,
              child: const SearchScreen(),
            ),
          ),
          GoRoute(
            path: '/watchlist',
            pageBuilder: (context, state) => buildPageWithFadeTransition(
              state: state,
              child: const WatchlistScreen(),
            ),
          ),
          GoRoute(
            path: '/watched',
            pageBuilder: (context, state) => buildPageWithFadeTransition(
              state: state,
              child: const WatchlistScreen(initialTab: 1),
            ),
          ),
          GoRoute(
            path: '/favorites',
            pageBuilder: (context, state) => buildPageWithFadeTransition(
              state: state,
              child: const WatchlistScreen(initialTab: 2),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => buildPageWithFadeTransition(
              state: state,
              child: const ProfileScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => buildPageWithFadeTransition(
              state: state,
              child: const SettingsScreen(),
            ),
          ),
          GoRoute(
            path: '/social',
            pageBuilder: (context, state) => buildPageWithFadeTransition(
              state: state,
              child: const SocialScreen(),
            ),
          ),
          GoRoute(
            path: '/following',
            pageBuilder: (context, state) => buildPageWithFadeTransition(
              state: state,
              child: const PeopleScreen(),
            ),
          ),
          GoRoute(
            path: '/notifications',
            pageBuilder: (context, state) => buildPageWithFadeTransition(
              state: state,
              child: const SocialScreen(),
            ),
          ),
          parityRoute(
            path: '/quests',
            title: 'CineQuests & Challenges',
            mode: 'quests',
          ),
          parityRoute(path: '/trending', title: 'Trending', mode: 'trending'),
          parityRoute(
            path: '/recommendations',
            title: 'Recommendations',
            mode: 'recommendations',
          ),
          parityRoute(path: '/calendar', title: 'Calendar', mode: 'calendar'),
          parityRoute(path: '/upcoming', title: 'Upcoming', mode: 'upcoming'),
          parityRoute(path: '/stats', title: 'Statistics', mode: 'stats'),
          parityRoute(
            path: '/enhanced-stats',
            title: 'Enhanced statistics',
            mode: 'enhanced-stats',
          ),
          parityRoute(path: '/movies', title: 'Movies', mode: 'movies'),
          parityRoute(path: '/tv', title: 'TV shows', mode: 'tv'),
          parityRoute(path: '/genres', title: 'Genres', mode: 'genres'),
          parityRoute(path: '/decades', title: 'Decades', mode: 'decades'),
          parityRoute(path: '/awards', title: 'Awards', mode: 'awards'),
          parityRoute(
            path: '/watch-history',
            title: 'Watch history',
            mode: 'watch-history',
          ),
          parityRoute(
            path: '/print-watchlist',
            title: 'Print watchlist',
            mode: 'print-watchlist',
          ),
          GoRoute(
            path: '/accessibility',
            pageBuilder: (context, state) => buildPageWithFadeTransition(
              state: state,
              child: const AccessibilityScreen(),
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Page not found',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                state.error != null
                    ? describeAppError(state.error!)
                    : 'This route does not exist.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
});

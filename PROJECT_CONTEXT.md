# CineTrekker Android — Project Context & System State

## 1. Project Overview
- **Name**: CineTrekker Android
- **Type**: Native Android cinema discovery, tracking, and companion application built with Flutter.
- **Audience**: Cinema enthusiasts, TV series binge-watchers, and film collectors who want a fast, intentional, and ad-free experience.
- **Core Goals**:
  - Seamless movie and TV series discovery powered by TMDB metadata.
  - Granular personal watchlist, watched history, and season/episode tracking.
  - Social interactions (reviews, comments, user following, public profiles).
  - Rich cinephile analytics (ratings distribution, watch time, 6-month viewing timeline, rank progression).
  - Offline-first reliability with optimistic local mutations and automated remote sync.
  - Flagship Android ergonomics: Material You styling, AMOLED pure black, haptic feedback, custom typography scaling, and TalkBack accessibility.
- **Current Status**: **Production Release v1.1.0 (Build 3)**. Fully audited, signed with production upload key, and published on GitHub Releases.

---

## 2. Technology Stack & Dependencies

### Core Framework & Runtime:
- **Flutter SDK**: 3.x (Dart 3.9+ / 3.x)
- **Target OS**: Android 7.0+ (minSdkVersion: 24, targetSdkVersion: 36, compileSdkVersion: 36)
- **Native Android Engine**: Kotlin 2.2.20, Gradle 8.14.2, Android Gradle Plugin 8.11.1, NDK 28.2.13676358

### Production Dependencies (from `pubspec.yaml`):
- `flutter_riverpod: ^2.6.1` — State management (AsyncNotifier, Notifier, Provider, StreamProvider)
- `go_router: ^16.1.0` (resolved `16.3.0`) — Declarative URL-driven navigation & custom page transitions
- `dio: ^5.9.0` — HTTP networking, timeout handling, token auto-refresh interceptors
- `flutter_secure_storage: ^9.2.4` — Encrypted key-value storage for OAuth tokens and session data
- `google_fonts: ^6.2.1` (resolved `6.3.3`) — Runtime font loading (`Space Grotesk`, `DM Sans`)
- `cached_network_image: ^3.4.1` — Network poster/backdrop caching with memory & disk cache
- `sentry_flutter: ^8.14.2` — Crash reporting and error diagnostics
- `url_launcher: ^6.3.1` — Safe external URL launching (trailer YouTube links, legal URLs)
- `app_links: ^6.4.1` — Android deep linking and App Links (`/auth/callback`)
- `crypto: ^3.0.6` — SHA-256 code verifier generation for PKCE OAuth 2.0 flow
- `flutter_localizations` (SDK) — Internationalization delegates

---

## 3. Environment Variables & Constants

All runtime configuration is injected via `--dart-define` or `--dart-define-from-file=.env`:

| Key | Mandatory | Description | Fallback / Behavior |
|---|---|---|---|
| `CINETREKKER_SUPABASE_URL` | **Yes** | Base URL for Supabase backend project | App shows config error if missing |
| `CINETREKKER_SUPABASE_ANON_KEY`| **Yes** | Anonymous client API key for Supabase PostgREST/Auth | App shows config error if missing |
| `CINETREKKER_API_BASE_URL` | **Yes** | Base URL for backend server proxy (`https://cinetrekker.vercel.app`) | Routes `/api/tmdb-proxy` & `/api/feedback` |
| `CINETREKKER_SENTRY_DSN` | No | Sentry DSN endpoint for crash analytics | If omitted, crashes log locally only |

### Storage Keys (`AppConstants` in `lib/core/constants/app_constants.dart`):
- `cinetrekker_theme_style`: Theme choice (`system`, `light`, `dark`, `oled`).
- `cinetrekker_text_scale`: Preset text scale (`system`, `large`, `xLarge`).
- `cinetrekker_font_size_scale`: Fine-grained text scaling multiplier (`0.85` to `1.30`).
- `cinetrekker_locale_style`: Active locale (`system`, `en`, `ar`, `fr`, `es`, `de`, `tr`).
- `cinetrekker_auth_session`: Encrypted JSON representation of `CineTrekkerAuthSession`.
- `cinetrekker_content_safety`: Adult content filtering and maturity ratings.
- `cinetrekker_reduced_motion`: Reduced motion override (`system`, `standard`, `reduced`).

---

## 4. Complete Riverpod Provider Registry

The application maintains 35 Riverpod providers:

| Provider Name | Type | Purpose | File Location |
|---|---|---|---|
| `apiClientProvider` | `Provider<Dio>` | Base Dio client pointing to `apiBaseUrl` | `lib/core/api/api_client.dart` |
| `tmdbApiServiceProvider` | `Provider<TmdbApiService>` | TMDB proxy client with in-flight deduplication & 24h cache | `lib/core/api/tmdb_api_service.dart` |
| `supabaseRestApiProvider` | `Provider<SupabaseRestApi>` | Supabase PostgREST client with 401 token auto-refresh | `lib/core/api/supabase_rest_api.dart` |
| `authControllerProvider` | `AsyncNotifierProvider<AuthController, CineTrekkerAuthSession?>` | PKCE OAuth 2.0, sign in/up, session refresh, secure storage | `lib/core/auth/auth_controller.dart` |
| `themeControllerProvider` | `NotifierProvider<ThemeController, CineTrekkerThemeStyle>` | Light, Dark, OLED Pure Black theme state | `lib/core/theme/theme_controller.dart` |
| `textScaleControllerProvider` | `NotifierProvider<TextScaleController, CineTrekkerTextScaleStyle>` | 3-step text scale preset state | `lib/core/accessibility/text_scale_controller.dart` |
| `fontSizeScaleControllerProvider` | `NotifierProvider<FontSizeScaleController, double>` | Continuous 0.85×–1.30× font scaling state | `lib/core/accessibility/text_scale_controller.dart` |
| `reducedMotionControllerProvider` | `NotifierProvider<ReducedMotionController, CineTrekkerMotionStyle>` | Reduced motion and animation preferences | `lib/core/accessibility/reduced_motion_controller.dart` |
| `localeControllerProvider` | `NotifierProvider<LocaleController, CineTrekkerLocaleStyle>` | Active app locale and language selection | `lib/core/localization/locale_controller.dart` |
| `tmdbLanguageProvider` | `Provider<String>` | Language code passed to TMDB proxy | `lib/core/localization/locale_controller.dart` |
| `appLocalizationsProvider` | `Provider<AppLocalizations>` | Localized string catalog lookup | `lib/core/localization/app_localizations.dart` |
| `contentSafetyControllerProvider`| `NotifierProvider<ContentSafetyController, CineTrekkerContentSafety>`| Maturity rating and adult content filtering | `lib/core/content_safety/content_safety_controller.dart` |
| `connectivityProvider` | `StreamProvider<bool>` | Live network connectivity listener | `lib/core/widgets/offline_banner.dart` |
| `analyticsServiceProvider` | `Provider<AnalyticsService>` | Navigation and interaction analytics logger | `lib/core/utils/analytics_service.dart` |
| `analyticsObserverProvider` | `Provider<AnalyticsObserver>` | GoRouter route observation adapter | `lib/core/utils/analytics_service.dart` |
| `appRouterProvider` | `Provider<GoRouter>` | Declarative router configuration | `lib/router/app_router.dart` |
| `homeControllerProvider` | `AsyncNotifierProvider<HomeController, HomeFeedData>` | Landing feed (spotlight, trending, top rated) | `lib/features/home/presentation/home_controller.dart` |
| `homeRepositoryProvider` | `Provider<HomeRepository>` | Multi-rail TMDB aggregator | `lib/features/home/data/home_repository.dart` |
| `searchControllerProvider` | `NotifierProvider<SearchController, SearchState>` | Debounced multi-search and mood filters | `lib/features/search/presentation/search_controller.dart` |
| `discoverControllerProvider` | `NotifierProvider<DiscoverController, DiscoverState>` | Multi-criteria discover matrix | `lib/features/discover/presentation/discover_controller.dart` |
| `detailsControllerProvider` | `NotifierProvider<DetailsController, DetailsState>` | Media details, cast, recommendations, videos | `lib/features/details/presentation/details_controller.dart` |
| `watchlistControllerProvider` | `NotifierProvider<WatchlistController, WatchlistState>` | Library items, tabs, filtering, batch selection | `lib/features/watchlist/presentation/watchlist_controller.dart` |
| `userLibraryRepositoryProvider` | `Provider<UserLibraryRepository>` | Library repository with optimistic caching & offline queue | `lib/features/watchlist/data/user_library_repository.dart` |
| `tvTrackingControllerProvider` | `NotifierProvider<TvTrackingController, TvTrackingState>` | TV progress, followed shows, air schedule | `lib/features/tv_tracking/presentation/tv_tracking_controller.dart` |
| `collectionsControllerProvider` | `NotifierProvider<CollectionsController, CollectionsState>` | Curated and user collections | `lib/features/collections/presentation/collections_controller.dart` |
| `collectionsRepositoryProvider` | `Provider<CollectionsRepository>` | Collections database repository | `lib/features/collections/data/collections_repository.dart` |
| `achievementsControllerProvider` | `NotifierProvider<AchievementsController, AchievementsState>` | Gamified viewing achievements | `lib/features/achievements/presentation/achievements_controller.dart` |
| `profileControllerProvider` | `NotifierProvider<ProfileController, ProfileState>` | Personal profile data, stats, favorites | `lib/features/profile/presentation/profile_controller.dart` |
| `profileRepositoryProvider` | `Provider<ProfileRepository?>` | Profile database repository | `lib/features/profile/data/profile_repository.dart` |
| `peopleControllerProvider` | `NotifierProvider<PeopleController, PeopleState>` | Following/followers network | `lib/features/social/presentation/people_controller.dart` |
| `commentsControllerProvider` | `NotifierProvider<CommentsController, CommentsState>` | Title comments, reviews, likes | `lib/features/social/presentation/comments_controller.dart` |
| `notificationsControllerProvider`| `NotifierProvider<NotificationsController, NotificationsState>`| User activity notifications | `lib/features/social/presentation/notifications_controller.dart` |
| `socialRepositoryProvider` | `Provider<SocialRepository>` | Social database repository | `lib/features/social/data/social_repository.dart` |
| `feedbackRepositoryProvider` | `Provider<FeedbackRepository>` | In-app feedback submission service | `lib/features/settings/data/feedback_repository.dart` |
| `yearInReviewControllerProvider` | `NotifierProvider<YearInReviewController, YearInReviewState>` | Annual viewing retrospective | `lib/features/year_in_review/presentation/year_in_review_controller.dart` |

---

## 5. Database Schema & Tables (Supabase PostgreSQL)

Authoritative SQL defined in `docs/supabase_rls_apply.sql`:

1. **`public.profiles`**:
   - Columns: `user_id` (PK, UUID), `display_name`, `bio`, `avatar_url`, `is_public` (bool), `show_watchlist` (bool), `show_stats` (bool), `allow_recommendations` (bool), `show_age` (bool), `favorite_genres` (int[]), `favorite_titles` (text[]), `maturity_rating`, `adult_content_enabled`, `strict_filtering_enabled`, `moderate_filtering_enabled`, `created_at`, `updated_at`.
   - RLS: Public read for public profiles (`is_public = true or auth.uid() = user_id`); owner insert/update/delete.
2. **`public.user_watchlist`**:
   - Columns: `id` (int), `user_id` (UUID), `media_id` (int), `media_type` (text), `title`, `poster_path`, `backdrop_path`, `vote_average` (numeric), `release_date`, `added_at` (timestamp).
   - RLS: Owner-only select, insert, update, delete (`auth.uid() = user_id`).
3. **`public.user_watched`**:
   - Columns: `id` (int), `user_id` (UUID), `media_id` (int), `media_type` (text), `title`, `poster_path`, `backdrop_path`, `vote_average`, `release_date`, `rating` (numeric 1.0–10.0), `note`, `status`, `watched_at`, `added_at`.
   - RLS: Owner-only select, insert, update, delete (`auth.uid() = user_id`).
4. **`public.followed_shows`**:
   - Columns: `user_id` (UUID), `show_id` (int), `show_title`, `poster_path`, `last_watched_season` (int), `last_watched_episode` (int), `next_air_date` (ISO date), `next_episode_name`, `created_at`.
   - RLS: Owner-only select, insert, update, delete.
5. **`public.watched_episodes`**:
   - Columns: `user_id` (UUID), `show_id` (int), `season_number` (int), `episode_number` (int), `watched_at`.
   - RLS: Owner-only select, insert, delete.
6. **`public.comments`**:
   - Columns: `id` (UUID), `user_id` (UUID), `media_type`, `media_id` (int), `content`, `rating`, `contains_spoiler` (bool), `likes_count` (int), `created_at`.
   - RLS: Authenticated read (`true`); author insert/update/delete (`auth.uid() = user_id`).
7. **`public.comment_likes`**:
   - Columns: `user_id` (UUID), `comment_id` (UUID), `created_at`.
   - RLS: Authenticated read; owner insert/delete.
8. **`public.notifications`**:
   - Columns: `id` (UUID), `user_id` (UUID), `type`, `message`, `data` (jsonb), `is_read` (bool), `created_at`.
   - RLS: Owner-only select, update, delete (`auth.uid() = user_id`).
9. **`public.user_follows` / `public.follows`**:
   - Columns: `follower_id` (UUID), `following_id` (UUID), `created_at`.
   - RLS: Authenticated read; insert requires `auth.uid() = follower_id`; delete allows either party.
10. **`public.collections` & `public.collection_items`**:
    - Columns: `id`, `user_id`, `name`, `description`, `item_count`, `created_at`, `updated_at`.
    - RLS: Owner-only CRUD for custom user collections.

---

## 6. Complete Routes Map

All routes in `lib/router/app_router.dart`:

### Full-Screen Routes (Root Navigator):
- `/login`: `AuthScreen(initialMode: AuthMode.signIn)`
- `/signup`: `AuthScreen(initialMode: AuthMode.signUp)`
- `/auth`: `AuthScreen()`
- `/auth/reset` & `/reset`: `AuthScreen(initialMode: AuthMode.reset)`
- `/auth/callback`: `AuthScreen()` (OAuth deep link callback handler)
- `/details/:mediaType/:mediaId`: `DetailsScreen(mediaType, mediaId, heroTag)`
- `/person/:personId`: `PersonDetailScreen(personId)`
- `/user/:userId`: `PublicProfileScreen(userId)`
- `/tv-tracking`: `TvTrackingScreen`
- `/collections`: `CollectionsScreen`
- `/achievements`: `AchievementsScreen`
- `/year-in-review`: `YearInReviewScreen`
- `/feedback`: `FeedbackScreen`
- `/privacy`: `PrivacyPolicyScreen`
- `/terms`: `TermsScreen`
- `/cookies`: `CookiesScreen`
- `/about`: `AboutScreen`

### Shell Routes (Persistent Bottom Nav):
- `/`: `HomeShell`
- `/discover`: `DiscoverScreen`
- `/search`: `SearchScreen`
- `/watchlist`: `WatchlistScreen(initialTab: 0)` (Watchlist tab)
- `/watched`: `WatchlistScreen(initialTab: 1)` (Watched tab)
- `/favorites`: `WatchlistScreen(initialTab: 2)` (Favorites tab)
- `/profile`: `ProfileScreen`
- `/settings`: `SettingsScreen`
- `/social`: `SocialScreen`
- `/following`: `PeopleScreen`
- `/notifications`: `SocialScreen`
- `/accessibility`: `AccessibilityScreen`
- `/stats` & `/enhanced-stats`: `FeatureParityScreen(mode: 'stats')`
- `/calendar`: `FeatureParityScreen(mode: 'calendar')`
- `/quests`: `FeatureParityScreen(mode: 'quests')`
- `/trending`: `FeatureParityScreen(mode: 'trending')`
- `/recommendations`: `FeatureParityScreen(mode: 'recommendations')`
- `/upcoming`: `FeatureParityScreen(mode: 'upcoming')`
- `/movies`: `FeatureParityScreen(mode: 'movies')`
- `/tv`: `FeatureParityScreen(mode: 'tv')`
- `/genres`: `FeatureParityScreen(mode: 'genres')`
- `/decades`: `FeatureParityScreen(mode: 'decades')`
- `/awards`: `FeatureParityScreen(mode: 'awards')`
- `/watch-history`: `FeatureParityScreen(mode: 'watch-history')`
- `/print-watchlist`: `FeatureParityScreen(mode: 'print-watchlist')`

---

## 7. Project Map (Where to Look)

| Feature / Task | Primary File | Supporting Files | Tests |
|---|---|---|---|
| **Authentication & OAuth** | `lib/core/auth/auth_controller.dart` | `lib/core/auth/auth_session.dart`, `lib/features/auth/presentation/auth_screen.dart` | `test/core/auth/auth_session_test.dart` |
| **Movie / TV Details Screen**| `lib/features/details/presentation/details_screen.dart` | `lib/features/details/presentation/details_controller.dart`, `lib/core/api/tmdb_api_service.dart` | Manual / Widget verification |
| **In-App Trailers & Story Cards**| `lib/features/details/presentation/details_screen.dart` | `lib/core/motion/haptic_service.dart`, `lib/core/accessibility/app_semantics.dart` | Manual verification |
| **Watchlist & Batch Actions**| `lib/features/watchlist/presentation/watchlist_screen.dart` | `lib/features/watchlist/data/user_library_repository.dart`, `lib/core/offline/offline_mutation_queue.dart` | Integration tests |
| **TV Tracking & Air Reminders**| `lib/features/tv_tracking/presentation/tv_tracking_screen.dart`| `lib/features/tv_tracking/presentation/tv_tracking_controller.dart`, `lib/core/models/media_models.dart` | Integration tests |
| **Cinephile Analytics & Charts**| `lib/features/parity/presentation/feature_parity_screen.dart` | `lib/features/watchlist/data/user_library_repository.dart` | Manual verification |
| **Search & Mood Chips** | `lib/features/search/presentation/search_screen.dart` | `lib/features/search/presentation/search_controller.dart` | Manual verification |
| **Font Scaling & Accessibility**| `lib/features/settings/presentation/settings_screen.dart` | `lib/core/accessibility/text_scale_controller.dart`, `lib/core/accessibility/app_semantics.dart`, `lib/app.dart` | `flutter analyze` |
| **Theme & AMOLED Black** | `lib/core/theme/theme_controller.dart` | `lib/core/theme/app_theme.dart`, `lib/app.dart` | `flutter analyze` |
| **Routing & Shell** | `lib/router/app_router.dart` | `lib/shared/widgets/app_scaffold.dart`, `lib/features/home/presentation/home_shell.dart` | `test/core/analytics_observer_test.dart` |
| **Supabase REST & RLS** | `lib/core/api/supabase_rest_api.dart` | `docs/supabase_rls.md`, `docs/supabase_rls_apply.sql` | `test/core/api/supabase_rest_api_test.dart` |
| **Social, Comments & Follows**| `lib/features/social/presentation/social_screen.dart` | `lib/features/social/data/social_repository.dart`, `lib/features/social/presentation/comments_controller.dart` | `test/features/social/social_repository_test.dart` |
| **In-App User Feedback** | `lib/features/settings/presentation/feedback_screen.dart` | `lib/features/settings/data/feedback_repository.dart` | Manual verification |

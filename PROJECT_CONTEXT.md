# CineTrekker Android — Project Context & System State

## 1. Project Overview
- **Name**: CineTrekker Android
- **Type**: Native Android cinema discovery, tracking, and companion application built with Flutter.
- **Audience**: Cinema enthusiasts, TV series binge-watchers, and film collectors who want a fast, intentional, and ad-free experience.
- **Core Goals**:
  - Seamless movie and TV series discovery powered by TMDB.
  - Granular watchlist, watched history, and season/episode tracking.
  - Social interactions (reviews, comments, user following, public profiles).
  - Rich cinephile analytics (ratings distribution, watch time, 6-month viewing timeline, rank progression).
  - Offline-first reliability with optimistic local mutations and automated remote sync.
  - Flagship Android ergonomics: Material You styling, AMOLED pure black, haptic feedback, custom typography scaling, and TalkBack accessibility.
- **Current Status**: **Production Release v1.1.0 (Build 3)**. Fully audited, signed with production upload key, and published on GitHub Releases.

---

## 2. Technology Stack
- **Framework**: Flutter 3.x (Dart 3.9+ / 3.x)
- **Target Platform**: Android 7.0+ (API 24 to Android 16 / API 36)
- **State Management**: [Riverpod 2.6.1](https://riverpod.dev) (`AsyncNotifierProvider`, `NotifierProvider`, `Provider`)
- **Navigation & Routing**: [GoRouter 16.3.0](https://pub.dev/packages/go_router) with custom slide and fade transitions
- **Network / HTTP Client**: [Dio 5.9.0](https://pub.dev/packages/dio) with interceptors for token auto-refresh and error handling
- **Backend & Database**: [Supabase](https://supabase.com) (PostgREST API `/rest/v1`, GoTrue Auth `/auth/v1`, PostgreSQL with Row Level Security)
- **Movie / TV Metadata**: [The Movie Database (TMDB) API](https://www.themoviedb.org) routed via a backend server proxy (`/api/tmdb-proxy`)
- **Streaming Providers**: JustWatch data integrated via TMDB API
- **Local Storage & Security**:
  - `flutter_secure_storage 9.2.4` for auth tokens and encrypted user preferences
  - File-based cache (`LocalCacheManager`) with TTL and in-flight request deduplication
  - Offline sync engine (`OfflineMutationQueue`)
- **Typography & Fonts**: `google_fonts 6.3.3` (Space Grotesk for headings, DM Sans for body)
- **Image Caching**: `cached_network_image 3.4.1` with custom skeleton shimmer loaders
- **Monitoring & Crash Reporting**: `sentry_flutter 8.14.2`
- **Tactile & Motion**: Native platform haptics (`HapticFeedback`) and spring physics (`BouncyPressable`)

---

## 3. Repository Structure
```
cinetrekker-android/
├── AI_RULES.md                   # Permanent AI agent operating guidelines
├── PROJECT_CONTEXT.md            # Canonical current project state and project map (this file)
├── ARCHITECTURE.md               # Technical architecture, system layers, and flow traces
├── CHANGELOG.md                  # Chronological engineering log
├── DEFINITION_OF_DONE.md         # Quality gates and completion checklist
├── README.md                     # Public repository documentation
├── pubspec.yaml                  # Flutter package definition and version (1.1.0+3)
├── analysis_options.yaml         # Lint rules and static analysis configuration
├── .env.example                  # Environment variable template
├── android/                      # Native Android project (Gradle 8.14, AGP 8.11, Kotlin 2.2)
│   ├── app/                      # App module, ProGuard rules, signing configurations
│   └── key.properties            # Play App Signing keystore credentials (gitignored)
├── assets/                       # Bundled static assets (logo, fallback graphics)
├── docs/                         # Supabase RLS policies and SQL migrations
│   ├── supabase_rls.md           # RLS specification and table documentation
│   └── supabase_rls_apply.sql    # Executable SQL script for Supabase database
├── lib/
│   ├── main.dart                 # Application entry point, Sentry initialization, error zones
│   ├── app.dart                  # CineTrekkerApp widget, MaterialApp.router, theme & text scaling
│   ├── router/                   # GoRouter route declarations and navigation shell
│   ├── shared/                   # Reusable UI widgets across features (pressables, loaders, cards)
│   ├── core/                     # Foundational infrastructure layers
│   │   ├── accessibility/        # TextScaleController, AppSemantics engine
│   │   ├── api/                  # Dio clients, Supabase REST API, TMDB proxy service
│   │   ├── auth/                 # AuthController (OAuth PKCE, session management, storage)
│   │   ├── constants/            # Environment definitions, storage keys, constants
│   │   ├── content_safety/       # Maturity ratings and adult content filtering
│   │   ├── errors/               # User-friendly error parsing and crash fallback
│   │   ├── localization/         # Multi-language locale controller (en, ar, fr, es, de, tr)
│   │   ├── models/               # Core domain data models
│   │   ├── motion/               # HapticService, motion tokens, spring curves
│   │   ├── offline/              # OfflineMutationQueue and offline action replay
│   │   ├── storage/              # LocalCacheManager and secure storage abstraction
│   │   ├── theme/                # Light, Dark, and AMOLED OLED Pure Black themes
│   │   └── widgets/              # Offline banner, startup config gate
│   └── features/                 # Modular feature domains
│       ├── home/                 # Main landing feed (trending, spotlight, rails)
│       ├── search/               # Search screen, debounce, mood discovery chips
│       ├── discover/             # Filter-driven discover matrix (genres, year, rating)
│       ├── details/              # Title details, cast, trailers, 9:16 story card generator
│       ├── watchlist/            # Library, multi-select batch actions, CSV/JSON export
│       ├── tv_tracking/          # TV season/episode tracker, air reminders, schedule modal
│       ├── collections/          # Cinematic movie collections browser
│       ├── achievements/         # Cinephile badges and unlockable achievements
│       ├── parity/               # Analytics dashboard, stats charts, milestones
│       ├── social/               # User profile, following/followers, comments, notifications
│       ├── profile/              # Personal & public profile screens, favorite titles
│       ├── settings/             # Settings, font scaler slider, theme, export, legal
│       └── year_in_review/       # Annual retrospective summary
└── test/                         # Unit and integration test suite
```

---

## 4. Application Architecture
CineTrekker adopts a **feature-first, unidirectional data flow** architecture with Riverpod:
1. **Presentation Layer**: Widgets (`ConsumerWidget` / `ConsumerStatefulWidget`) observe state from Riverpod providers. UI responds strictly to state and dispatches user actions to notifiers.
2. **Controller Layer**: `AsyncNotifier` or `Notifier` classes encapsulate business logic, form validation, and UI state transitions.
3. **Repository Layer**: Aggregates remote REST calls and local cache access, providing clean domain entities to controllers.
4. **Data Layer**:
   - `TmdbApiService` proxies metadata queries through the backend proxy with automatic caching.
   - `SupabaseRestApi` performs authenticated CRUD operations over PostgREST with RLS.
   - `OfflineMutationQueue` intercepts mutations when offline, writes optimistic state locally, and queues remote sync.

---

## 5. Routes
All routes are managed via `GoRouter` in `lib/router/app_router.dart`:

### Shell Routes (Within Persistent Bottom Navigation):
- `/`: `HomeShell` — Trending spotlight, top rated, recommendations feed.
- `/discover`: `DiscoverScreen` — Multi-filter browse by genre, release year, rating.
- `/search`: `SearchScreen` — Instant search with curated Mood Chips.
- `/watchlist`: `WatchlistScreen` (tab 0: Watchlist, tab 1: Watched, tab 2: Favorites).
- `/watched`: Direct link to `WatchlistScreen` with Watched tab active.
- `/favorites`: Direct link to `WatchlistScreen` with Favorites tab active.
- `/profile`: `ProfileScreen` — User profile, stats summary, lists, achievements.
- `/settings`: `SettingsScreen` — Theme, font scaler, language, export, account deletion.
- `/social`: `SocialScreen` — Community activity feed and notifications.
- `/stats` / `/enhanced-stats`: `FeatureParityScreen(mode: 'stats')` — Analytics dashboard.
- `/calendar`: `FeatureParityScreen(mode: 'calendar')` — Release calendar.
- `/quests`: `FeatureParityScreen(mode: 'quests')` — CineQuests challenges.
- `/trending`: `FeatureParityScreen(mode: 'trending')` — Extended trending list.
- `/movies`: `FeatureParityScreen(mode: 'movies')` — Movies catalog.
- `/tv`: `FeatureParityScreen(mode: 'tv')` — TV shows catalog.
- `/genres`: `FeatureParityScreen(mode: 'genres')` — Genre grid.
- `/accessibility`: `AccessibilityScreen` — Accessibility settings overview.

### Full-Screen Routes (Overlay / Root Navigator):
- `/login`, `/signup`, `/auth`, `/auth/reset`, `/reset`: Authentication flows.
- `/auth/callback`: Deep link OAuth callback handler.
- `/details/:mediaType/:mediaId`: Comprehensive movie/TV details, trailer modal, cast, story cards.
- `/person/:personId`: Cast/crew filmography and biography.
- `/user/:userId`: Public user profile, their watched titles and lists.
- `/tv-tracking`: TV episode tracking dashboard and Airing Schedule sheet.
- `/collections`: Official collections browser.
- `/achievements`: Achievements and badges list.
- `/year-in-review`: Year-in-review visual recap.
- `/feedback`: In-app user feedback form.
- `/privacy`, `/terms`, `/cookies`, `/about`: Legal and application info screens.

---

## 6. Core Features
1. **Movie & TV Details**: High-resolution backdrops, animated score ring, synopsis, streaming provider badges (JustWatch), trailer preview modal, cast rail, and recommendations.
2. **In-App Trailer Preview**: 16:9 thumbnail preview modal with options to play in-app browser or launch external YouTube app.
3. **9:16 Social Story Card Generator**: Exports 2.0× high-definition share cards with backdrop, poster, rating pill, genre tags, and CineTrekker watermark directly to clipboard.
4. **Library & Watchlist Power Tools**:
   - Multi-select batch mode with item counts, batch delete, and batch export.
   - RFC-4180 CSV export and formatted JSON export.
   - Offline mutation queue allowing instant local updates when disconnected.
5. **TV Episode Tracking & Air Reminders**:
   - Episode-level watched tracking per season.
   - Live air countdown badges (`TODAY`, `SOON`, `📅 Airing in X days`).
   - Airing Schedule bottom sheet displaying upcoming air dates sorted chronologically.
6. **Cinephile Analytics**:
   - 5-tier Cinephile Rank progression banner (Film Novice → Master Film Connoisseur).
   - 4 KPI metric cards (Watch Time, Titles Seen, Average Score, Episodes).
   - Interactive 6-month viewing timeline bar chart with tap-to-inspect tooltips.
   - Interactive 5-tier rating distribution histogram with score breakdown.
7. **Search & Mood Chips**: Real-time debounced search with curated quick-discovery mood chips (Trending, Sci-Fi, Award Winners, Feel Good, <90m, Horror).
8. **"Surprise Me" Roulette**: Animated random picker selecting an unwatched title from your library.
9. **Accessibility & Independent Typography Scaling**:
   - Continuous 0.85× to 1.30× font scaling slider with quick presets and live sample preview card.
   - Centralized `AppSemantics` engine for TalkBack announcements.

---

## 7. Business Logic & Constraints
- **Guest Mode vs. Signed-In**: CineTrekker functions fully in guest mode using local cache and storage. Once signed in via Supabase, cloud synchronization automatically takes place and the offline mutation queue flushes pending actions.
- **Rating Scale**: User ratings are normalized to a 1.0–10.0 range (with 0.5 or 0.1 increments).
- **Watchlist vs. Watched**: When a title is marked as watched, it is added to the watched list with an optional score and review date.
- **TMDB Proxy Rule**: Never query `api.themoviedb.org` directly from the client. All TMDB traffic must pass through `Environment.apiBaseUrl + '/api/tmdb-proxy'` to preserve API key confidentiality.
- **Row Level Security (RLS)**: User operations must strictly match `auth.uid() = user_id`. Client-side user ID filters are for convenience only; security is enforced at the database level.

---

## 8. Data Model Summary
Key models located in `lib/core/models/media_models.dart`:
- `TmdbMedia`: Core representation of a movie or TV show.
- `TmdbMediaDetails`: Extended details (runtime, genres, cast, videos, seasons, watch providers).
- `UserMediaItem`: Library entry containing `mediaId`, `mediaType`, `status`, `rating`, `addedAt`, `watchedAt`.
- `FollowedShowItem`: Tracked TV show with `lastWatchedSeason`, `lastWatchedEpisode`, `nextAirDate`, `nextEpisodeName`.
- `WatchedEpisodeItem`: Specific logged episode with season and episode numbers.
- `TmdbPersonDetails`: Cast/crew profile, biography, and filmography.
- `OfflineMutation`: Queue entry with `id`, `type`, `payload`, and `created_at`.
- `CineTrekkerAuthSession`: User session with `accessToken`, `refreshToken`, `expiresAt`, `user`.

---

## 9. Authentication & Security
- **Authentication Method**: Supabase Auth (GoTrue REST API) with OAuth 2.0 PKCE.
- **Supported Providers**: Email/password, Google OAuth, GitHub OAuth.
- **Tokens**: Stored securely using `flutter_secure_storage`. Automatically refreshed on 401 response via Dio interceptor.
- **Environment Ingestion**: Injected strictly via `--dart-define` or `--dart-define-from-file=.env`. No secrets exist in client code.
- **Content Safety**: Maturity rating filters (`G`, `PG`, `PG-13`, `R`, `NC-17`) stored in `ContentSafetyController` to filter adult content.

---

## 10. Design System & Tokens
- **Primary Color**: Signature CineTrekker Red (`#E50914`).
- **Surface Modes**:
  - Light: Clean editorial surfaces (`#F8F9FA`).
  - Dark: Deep cinematic charcoal (`#121212`).
  - AMOLED: Pure black (`#000000`) for OLED power efficiency.
- **Typography**:
  - Headings: `GoogleFonts.spaceGrotesk` (weights 600, 700, 800).
  - Body / Subtitles: `GoogleFonts.dmSans` (weights 400, 500, 600).
- **Motion Tokens** (`lib/core/motion/motion_tokens.dart`):
  - Fast: 150ms (`Curves.easeOutCubic`)
  - Medium: 250ms (`Curves.easeInOutCubic`)
  - Emphasis: 400ms (`Curves.easeOutBack`)
  - Page Transitions: 240ms slide-up & fade
- **Haptics**: Centralized in `Haptics` (`selection`, `light`, `buttonTap`, `addToWatchlist`, etc.).

---

## 11. Known Issues & Tech Debt
- None currently blocking.
- `flutter-sdk` and Gradle wrapper display deprecation warnings for future Kotlin 2.3+ / Gradle 9+ upgrades. Build succeeds cleanly with zero issues.

---

## 12. Project Map (Where to Look)

| Feature / Area | Primary Files | Supporting Files | Tests |
|---|---|---|---|
| **Auth & Session** | `lib/core/auth/auth_controller.dart` | `lib/core/auth/auth_session.dart`, `lib/features/auth/presentation/auth_screen.dart` | `test/core/auth/auth_session_test.dart` |
| **Movie / TV Details** | `lib/features/details/presentation/details_screen.dart` | `lib/features/details/presentation/details_controller.dart`, `lib/core/api/tmdb_api_service.dart` | Manual / Widget verification |
| **Watchlist & Library** | `lib/features/watchlist/presentation/watchlist_screen.dart` | `lib/features/watchlist/data/user_library_repository.dart`, `lib/core/offline/offline_mutation_queue.dart` | Integration tests |
| **TV Tracking & Air Dates**| `lib/features/tv_tracking/presentation/tv_tracking_screen.dart` | `lib/features/tv_tracking/presentation/tv_tracking_controller.dart`, `lib/core/models/media_models.dart` | Integration tests |
| **Analytics & Stats** | `lib/features/parity/presentation/feature_parity_screen.dart` | `lib/features/watchlist/data/user_library_repository.dart` | Manual verification |
| **Theme & Typography** | `lib/features/settings/presentation/settings_screen.dart` | `lib/core/theme/theme_controller.dart`, `lib/core/accessibility/text_scale_controller.dart`, `lib/app.dart` | `flutter analyze` |
| **Routing & Navigation** | `lib/router/app_router.dart` | `lib/shared/widgets/app_scaffold.dart`, `lib/features/home/presentation/home_shell.dart` | `test/core/analytics_observer_test.dart` |
| **Supabase REST & RLS** | `lib/core/api/supabase_rest_api.dart` | `docs/supabase_rls.md`, `docs/supabase_rls_apply.sql` | `test/core/api/supabase_rest_api_test.dart` |
| **Accessibility Engine** | `lib/core/accessibility/app_semantics.dart` | `lib/core/accessibility/text_scale_controller.dart` | `flutter analyze` |

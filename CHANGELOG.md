# CineTrekker Android — Engineering Changelog

## 2026-10-19 — Release v1.1.5: Native OS Episode Notifications, Android 13+ Permissions & Exact Alarms

### Added
* **Native Operating System Notifications**:
  * Integrated `flutter_local_notifications` and `timezone` for offline, native device alerts when new episodes or seasons of tracked TV series air.
  * Dedicated Android notification channel (`episode_releases`: "Episode & Release Reminders") with high importance, heads-up banner, and sound.
  * Automatic synchronization of device alarm triggers whenever tracked series, watch status, or reminder preferences change.
* **Android 13+ Notification Permissions & Exact Alarms**:
  * Added `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`, and `RECEIVE_BOOT_COMPLETED` permissions to `AndroidManifest.xml`.
  * Configured `ScheduledNotificationReceiver` and `ScheduledNotificationBootReceiver` for reliable alarm restoration across device reboots.
  * Enabled Android core library desugaring in Gradle for reliable modern date/time scheduling across all Android API versions.
* **Notification Scheduling Controls**:
  * Customizable delivery hour dropdown in Settings (e.g., 8:00 AM, 9:00 AM, 12:00 PM, 6:00 PM, 8:00 PM).
  * Configurable Quiet Hours (10:00 PM – 8:00 AM) that automatically delay late-night episode notifications until the next morning.
  * "Test notification" action in Settings to immediately verify notification permissions, sound, and banner rendering on the device.
* **Notification Deep Linking**:
  * Tapping any scheduled or immediate notification navigates directly to the series details page (`/tv/:showId`), supporting foreground, background, and cold app launch.
* **Automated Tests**:
  * Added unit tests for scheduled date arithmetic, quiet-hour adjustments, and deterministic notification ID generation. Device IANA timezone discovery and physical-device notification delivery were not verified for this release.

### Published v1.1.5 artifacts and verification

- [Release page](https://github.com/MohamedJebahi21/cinetrekker-android/releases/tag/v1.1.5)
- [Download APK](https://github.com/MohamedJebahi21/cinetrekker-android/releases/download/v1.1.5/cinetrekker-v1.1.5.apk) — SHA-256: `0b3d078e388803b60f0f3c46423469c1c793d8ffb6d480e48d8f98fe7cef22f8`
- [Download AAB](https://github.com/MohamedJebahi21/cinetrekker-android/releases/download/v1.1.5/cinetrekker-v1.1.5.aab) — SHA-256: `b26ab013e4519f496b7622e762c859a1347d4ea0aa115cc85592e73bc806b2b4`
- [CI run #49](https://github.com/MohamedJebahi21/cinetrekker-android/actions/runs/39251141897): analysis passed and 62 tests passed.
- [Release workflow #10](https://github.com/MohamedJebahi21/cinetrekker-android/actions/runs/39251418864): succeeded; both assets uploaded.

> CI and release build results do not replace physical-device validation. Exact-alarm permission behavior, device-local timezone accuracy, reboot restoration, notification tap routing, and actual notification delivery still require device testing.

---

## 2026-10-18 — Release v1.1.4: In-App Update Checker, Episode Release Reminders & Calendar Sync

### Added
* **In-App Update Checker**: Integrated GitHub Release checking accessible via Settings > "Check for updates", navigation drawer, and About screen with semver comparison, release notes preview modal, and direct APK download redirection.
* **Episode & Release Reminders**:
  * Track upcoming air dates and next episode details parsed directly from TMDB metadata for followed series.
  * Customizable reminder preferences in Settings with configurable lead timing (on air day, 1 day before, 2 days before) and reminder hour.
  * Per-show notification mute overrides on the Airing Schedule sheet.
  * One-tap device Google Calendar event creation pre-populated with episode title, series name, and air dates.
* **Metadata Persistence**: Enhanced local durable storage and Supabase schema compatibility to store and sync `next_air_date` and `next_episode_name`.
* **Testing & Analysis Quality**: Expanded automated test suite to 56 tests with zero static analysis warnings or infos.

---

## 2026-10-14 — Release v1.1.3: Native Android Polish, Durable Offline Sync & Discovery Upgrades

### Added
* **Durable Storage & Persistence**: Migrated all local and library caches from `Directory.systemTemp` to permanent app documents storage with automatic migration fallback, preventing OS-driven cache evictions.
* **User-Isolated Offline Mutation Queue**: Expanded `OfflineMutationQueue` to support 8 distinct operations covering movie, watchlist, TV show, and episode tracking with per-user queue isolation and automatic flush when connectivity is restored.
* **TV Season Lifecycle & Unmark Support**: Added dynamic season-level toggle allowing users to unmark an entire watched season in one tap with atomic batch rollback and offline mutation queueing.
* **Search Results Sorting**: Integrated interactive sorting options (Popularity / Relevance, Highest Rated, Newest Release) with memoized list sorting.
* **Home "Recently Watched" Carousel**: Added a horizontal rail on the home screen showing recently finished titles with star ratings and direct detail links.
* **Viewing Insights & Social Recap**: Year in Review now computes weekday viewing distributions from actual timestamps, tracks episode totals, and provides one-tap clipboard export.
* **Native Android 12+ Experience**: Added adaptive vector launcher icons, dark/light Android 12 splash screen themes, and native ZoomPageTransitionsBuilder navigation transitions.
* **Expanded Test Suite**: Added test coverage for offline mutation queues and recap generation, reaching 41 passing tests.

---

## 2026-09-21 — Release v1.1.2: Hotfix — Kotlin 2.2 + sentry_flutter compatibility

### Fixed
* **Kotlin 2.2 compile error**: `sentry_flutter` 8.14.2 shipped Kotlin sources targeting language version 1.6, which Kotlin 2.2.20 rejects. Upgraded `sentry_flutter` to `9.30.0` (fully Kotlin 2.2 compatible) and explicitly set `kotlinOptions { languageVersion = "1.9" }` in `android/app/build.gradle.kts`.
* GitHub Actions release workflow now completes successfully and publishes a signed APK with secrets baked in.

---

## 2026-09-21 — Release v1.1.1: Hotfix — Compile-time secrets injection

### Fixed
* **"Undefined secrets" startup error**: Release APK on GitHub was built before the `--dart-define-from-file` step was wired to GitHub Actions secrets. Rebuilt with all `CINETREKKER_*` secrets correctly injected at compile time via the release workflow. Bumped version to `1.1.1+4`.

---

## 2026-09-14 — Release v1.1.0: Major Feature Upgrade & Flagship Experience

### Added
* **Cinephile Analytics Dashboard**: 5-tier Cinephile Rank milestone banner, 4 KPI metrics (Watch Time, Titles Seen, Average Score, Episodes), interactive 6-month viewing timeline bar chart with tap-to-inspect tooltips, and 5-tier rating distribution histogram in `lib/features/parity/presentation/feature_parity_screen.dart`.
* **Branded 9:16 Social Story Card Generator**: `RepaintBoundary` high-definition 2.0× story card with backdrop, centered poster, rating badge, genre pills, and CineTrekker watermark with clipboard export.
* **In-App Trailer Preview Modal**: 16:9 YouTube thumbnail preview sheet with in-app browser and external app launch modes in `lib/features/details/presentation/details_screen.dart`.
* **TV Episode Air Reminders**: Followed shows now display `TODAY`, `SOON`, and countdown subtitles; added draggable Airing Schedule bottom sheet calendar in `lib/features/tv_tracking/presentation/tv_tracking_screen.dart`.
* **Watchlist Power Tools & Offline Architecture**: Batch multi-select mode with deletion and export; RFC-4180 CSV & formatted JSON export; `OfflineMutationQueue` with optimistic local caching and auto-sync on reconnect.
* **Search Mood Chips & Roulette**: Quick-discovery mood pills and animated "Surprise Me" roulette randomizer in `lib/features/search/presentation/search_screen.dart` and `watchlist_screen.dart`.
* **Independent Font Size Scaler**: Continuous 0.85×–1.30× slider with quick presets (`System`, `Large`, `Extra Large`) and live sample preview in `lib/features/settings/presentation/settings_screen.dart`.
* **TalkBack & Semantics Engine**: Centralized `AppSemantics` in `lib/core/accessibility/app_semantics.dart` providing accessibility announcements for watchlist, ratings, favorites, and multi-select.

### Changed
* Bumped app version to `1.1.0+3` across `pubspec.yaml` and `about_screen.dart`.
* Upgraded `FollowedShowItem` model with `nextAirDate` and countdown calculation methods.
* Enhanced `UserLibraryRepository` to support optimistic local-first caching.

### Fixed
* Addressed `announce` deprecation in Flutter SDK by adopting modern `SemanticsService.sendAnnouncement`.
* Replaced direct YouTube launcher with safe modal preview bottom sheet.

### Files affected
* `lib/app.dart`
* `lib/core/accessibility/app_semantics.dart`
* `lib/core/accessibility/text_scale_controller.dart`
* `lib/core/constants/app_constants.dart`
* `lib/core/models/media_models.dart`
* `lib/core/offline/offline_mutation_queue.dart`
* `lib/features/details/presentation/details_screen.dart`
* `lib/features/parity/presentation/feature_parity_screen.dart`
* `lib/features/settings/presentation/about_screen.dart`
* `lib/features/settings/presentation/settings_screen.dart`
* `lib/features/tv_tracking/presentation/tv_tracking_screen.dart`
* `lib/features/watchlist/data/user_library_repository.dart`
* `lib/features/watchlist/presentation/watchlist_screen.dart`
* `pubspec.yaml`

### Database changes
* None (uses existing Supabase tables and RLS policies).

### API changes
* Added `nextAirDate` and `nextEpisodeName` parsing support in TMDB model bindings.

### Tests
* Ran full test suite: 22/22 unit and integration tests passing.

### Verification
* Static analysis: `flutter analyze` passed with 0 issues.
* Release builds: Built signed universal release APK (`66.0 MB`) and Android App Bundle (`61.7 MB`).
* Published GitHub Release `v1.1.0`.

### Remaining risks
* None.

---

## 2026-09-13 — Release v1.0.1: Production Audit & Quality Release

### Added
* Missing `in_theaters` translation across all 6 supported locales (`en`, `es`, `fr`, `de`, `tr`, `ar`).
* Back button overlay on authentication screen for smooth guest navigation.
* Deep linking for social notifications to jump straight to target movie/TV details.
* TMDB attribution and legal link compliance in Settings.

### Fixed
* Parallelized TV calendar queries with `Future.wait` to eliminate UI stutter.
* Added clipboard copy fallback with SnackBar when native Android share intents fail.
* Added `BouncyPressable` spring physics to cards, chips, and cast rails.

### Files affected
* `lib/core/localization/`
* `lib/features/auth/presentation/auth_screen.dart`
* `lib/features/social/`
* `lib/features/settings/presentation/about_screen.dart`
* `pubspec.yaml`

### Database changes
* None.

### API changes
* None.

### Tests
* 22/22 unit tests passing.

### Verification
* `flutter analyze` clean with 0 issues.
* Release binaries published to GitHub Releases `v1.0.1`.

### Remaining risks
* None.

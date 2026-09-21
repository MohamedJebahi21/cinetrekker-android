# CineTrekker Android — Engineering Changelog

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

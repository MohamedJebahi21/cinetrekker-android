<div align="center">

<img src="play-store/play-icon-512.png" alt="CineTrekker Logo" width="120" height="120" style="border-radius:24px"/>

# CineTrekker

**Premium Android Cinema Companion**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10%2B-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Android](https://img.shields.io/badge/Android-7.0%2B-3DDC84?logo=android)](https://developer.android.com)
[![License](https://img.shields.io/badge/License-Proprietary-red)](LICENSE)
[![Build](https://img.shields.io/github/actions/workflow/status/MohamedJebahi21/cinetrekker-android/ci.yml?branch=main&label=CI&logo=github-actions&logoColor=white)](https://github.com/MohamedJebahi21/cinetrekker-android/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/MohamedJebahi21/cinetrekker-android?label=Latest%20Release&color=success)](https://github.com/MohamedJebahi21/cinetrekker-android/releases/latest)

*Discover. Track. Share.*

</div>

---

## ⬇️ Download the latest release

**CineTrekker v1.1.5** includes native episode reminders. Download the APK directly to your Android device:

<div align="center">

[![Download APK](https://img.shields.io/badge/Download%20APK-v1.1.5-2ea44f?style=for-the-badge&logo=android&logoColor=white)](https://github.com/MohamedJebahi21/cinetrekker-android/releases/download/v1.1.5/cinetrekker-v1.1.5.apk)

[**View release notes and all downloads**](https://github.com/MohamedJebahi21/cinetrekker-android/releases/tag/v1.1.5) · [All releases](https://github.com/MohamedJebahi21/cinetrekker-android/releases)

</div>

To install the APK, allow **Install unknown apps** for your browser or file manager when Android prompts you, then open the downloaded APK. The app requires **Android 7.0 (API 24)** or higher. On Android 13+, grant notification permission in Settings to receive episode reminders.

---

## ✨ Features

| Feature | Description |
|---|---|
| 🎬 **Movie & TV Discovery** | Browse trending, top-rated, and upcoming titles powered by TMDB |
| 📋 **Watchlist Management** | Save movies and TV shows to your personal watchlist |
| 📺 **TV Season Tracking** | Track watched episodes season by season |
| 🔔 **Native Episode Notifications** | Schedule OS notifications for upcoming episodes, with delivery-time controls, quiet hours, reboot restoration, and tap-to-open show details |
| 🔄 **In-App Update Checker** | Check GitHub Releases and open the latest download page from Settings |
| 🎭 **People Profiles** | Explore cast and crew filmographies |
| 📦 **Collections** | Browse official movie collections (e.g. Marvel, DC, Bond) |
| 🏆 **Achievements** | Unlock cinematic achievements as you track your viewing |
| 🔍 **Intelligent Search** | Search movies, TV shows, and people in real time |
| 📡 **Where to Watch** | See streaming availability with provider logos via JustWatch |
| 🌙 **Dark / Light / AMOLED** | Three system-aware themes with Material You design |
| 🌍 **Region Aware** | Content filtered by your streaming region |
| 🔒 **Secure Auth** | OAuth 2.0 (PKCE) via Supabase with session persistence |
| 📱 **App Shortcuts** | Long-press icon to jump to Search, Trending, Watchlist, or Discover |
| 🔙 **Predictive Back** | Native Android 14 back gesture animation support |
| 🎴 **Share Cards** | Cinematic 9:16 share cards for movies and shows |

---

## 🏗️ Architecture

CineTrekker is built with a clean, feature-first architecture:

```
lib/
├── core/
│   ├── api/          # TMDB + Supabase REST clients
│   ├── auth/         # OAuth 2.0 (PKCE) auth controller & deep link handler
│   ├── constants/    # Environment variables & app-wide constants
│   ├── errors/       # Crash fallback & error boundary
│   ├── notifications/# Native episode notification scheduling and routing
│   ├── reminders/    # Reminder preferences and schedule computation
│   ├── storage/      # Secure session + durable app data storage
│   ├── theme/        # Material You theme + colors
│   └── widgets/      # Shared core widgets (offline banner, etc.)
├── features/
│   ├── home/         # Home screen & trending content
│   ├── search/       # Full-text search
│   ├── details/      # Movie / TV show detail screen
│   ├── discover/     # Filter & genre discovery
│   ├── watchlist/    # Personal watchlist
│   ├── tv_tracking/  # Episode & season tracker
│   ├── collections/  # Official collections browser
│   ├── people/       # Cast & crew profiles
│   ├── achievements/ # Gamified viewing achievements
│   ├── social/       # Comments & in-app notifications
│   └── settings/     # App settings, theme, region, reminders, legal
└── shared/
    └── widgets/      # App-wide shared UI components
```

**Tech Stack:**
- **State Management**: [Riverpod](https://riverpod.dev) (AsyncNotifier)
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router)
- **Backend**: [Supabase](https://supabase.com) (Auth, Database, REST + RLS)
- **Movie Data**: [TMDB API](https://www.themoviedb.org/documentation/api) via server proxy
- **Local Notifications**: [`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications) and [`timezone`](https://pub.dev/packages/timezone)
- **Local Storage**: `flutter_secure_storage` (sessions) + durable app data cache
- **Crash reporting**: [Sentry](https://sentry.io) (optional via `CINETREKKER_SENTRY_DSN`)

---

## 🚀 Getting Started

### Prerequisites

| Tool | Version |
|---|---|
| Flutter | 3.x stable |
| Dart | 3.10+ |
| Android Studio | Giraffe or later |
| Java | 17+ |
| Android | minSdk 24 (Android 7.0)+ |

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/MohamedJebahi21/cinetrekker-android.git
   cd cinetrekker-android
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app (zero-config development)**
   The app includes production fallback endpoints for a basic run:
   ```bash
   flutter run
   ```
   Or press **F5** in VS Code to use the `CineTrekker (Development)` launch profile.

4. **Optional: Custom Environment Overrides**
   To point to your own Supabase instance or staging backend:
   ```bash
   cp .env.example .env
   # Edit .env with your own configuration
   flutter run --dart-define-from-file=.env
   ```

### Building a Release APK

For local signing, configure `android/key.properties` and the keystore as described in the Android Gradle signing configuration. Then:

```bash
flutter pub get
flutter build apk --release --obfuscate \
  --split-debug-info=build/debug-info \
  --dart-define-from-file=.env
```

The APK will be at `build/app/outputs/flutter-apk/app-release.apk`. The repository's automated release workflow also requires configured GitHub Actions secrets for signing and production dart-defines; see [`.github/workflows/release.yml`](.github/workflows/release.yml).

---

## 🔐 Environment Variables

| Variable | Description | Required for custom config |
|---|---|---|
| `CINETREKKER_SUPABASE_URL` | Your Supabase project URL | ✅ |
| `CINETREKKER_SUPABASE_ANON_KEY` | Your Supabase anonymous key | ✅ |
| `CINETREKKER_API_BASE_URL` | Base URL for the CineTrekker backend / TMDB proxy | ✅ |
| `CINETREKKER_SENTRY_DSN` | Sentry DSN for crash reporting | optional |

> Never commit your `.env` file. It is listed in `.gitignore`. Use [`.env.example`](.env.example) as a reference. GitHub Actions accepts `CINETREKKER_`-prefixed secrets and legacy unprefixed fallbacks.

### Backend security (RLS)

Client-side filters are **not** authorization. Apply and verify Supabase Row Level Security before release. See [`docs/supabase_rls.md`](docs/supabase_rls.md) and [`docs/supabase_rls_apply.sql`](docs/supabase_rls_apply.sql). Review the SQL against the live schema before applying it.

---

## 🔔 Episode Notifications

Native scheduled episode notifications are enabled from the app's reminder controls in Settings. Users can configure the lead time and delivery hour, enable quiet hours, and test delivery. Android 13 and later require notification permission. Android exact-alarm restrictions and device battery settings can affect delivery; check Android app permissions if alarms are delayed or suppressed. Tapping a notification opens its TV show in the app.

---

## 🔁 CI / CD

| Workflow | Trigger | Description |
|---|---|---|
| [CI](.github/workflows/ci.yml) | Push / PR to `main` | Runs `flutter analyze` and `flutter test` |
| [Release](.github/workflows/release.yml) | Push tag `v*` | Builds obfuscated APK + AAB and creates a GitHub Release |

To publish the next version, update `pubspec.yaml`, `lib/core/constants/app_constants.dart`, and `CHANGELOG.md`, then create and push a new version tag that targets the release commit:

```bash
git tag v1.1.6
git push origin v1.1.6
```

The release workflow requires its documented GitHub Actions signing and backend secrets; it creates the release and uploads the APK and AAB. Verify CI and the release workflow before sharing the links.

---

## 📂 Project Structure (Key Files)

| File | Purpose |
|---|---|
| `lib/main.dart` | App entry point, crash boundary, Riverpod + Sentry setup |
| `lib/app.dart` | MaterialApp, GoRouter, theme wiring and notification tap handling |
| `lib/core/auth/auth_controller.dart` | OAuth 2.0 PKCE session management |
| `lib/core/auth/oauth_callback_host.dart` | Deep link + shortcut routing |
| `lib/core/api/tmdb_api_service.dart` | TMDB REST client with caching |
| `lib/core/api/supabase_rest_api.dart` | Supabase backend client + 401 refresh |
| `lib/core/notifications/local_notification_service.dart` | Native OS notification initialization, scheduling, permissions, and tap payloads |
| `lib/core/reminders/episode_reminder_controller.dart` | Reminder preferences and native notification sync |
| `android/app/src/main/AndroidManifest.xml` | Manifest, notification permissions/receivers, and deep links |
| `android/app/src/main/res/xml/shortcuts.xml` | Static launcher shortcuts |
| `docs/supabase_rls.md` | Required RLS policy checklist |
| `.github/workflows/ci.yml` | CI pipeline |
| `.github/workflows/release.yml` | Release automation |

---

## 📸 Screenshots

> _Screenshots coming soon._

---

## 📄 License

This project is proprietary software. All rights reserved.
© 2026 Mohamed Jebahi. Unauthorized copying, modification, or distribution is prohibited.

---

## 🙏 Acknowledgements

- Movie and TV data provided by [The Movie Database (TMDB)](https://www.themoviedb.org). _This product uses the TMDB API but is not endorsed or certified by TMDB._
- Streaming provider data via [JustWatch](https://www.justwatch.com).
- Backend powered by [Supabase](https://supabase.com).
- Notification scheduling powered by [`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications).

---

<div align="center">
Made with ❤️ by <a href="https://github.com/MohamedJebahi21">Mohamed Jebahi</a>
</div>

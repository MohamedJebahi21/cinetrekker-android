<div align="center">

<img src="play-store/play-icon-512.png" alt="CineTrekker Logo" width="120" height="120" style="border-radius:24px"/>

# CineTrekker

**Premium Android Cinema Companion**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Android](https://img.shields.io/badge/Android-7.0%2B-3DDC84?logo=android&logoColor=white)](https://developer.android.com)
[![License](https://img.shields.io/badge/License-Proprietary-red)](LICENSE)
[![Build](https://img.shields.io/github/actions/workflow/status/MohamedJebahi21/cinetrekker-android/ci.yml?branch=main&label=CI&logo=github-actions&logoColor=white)](https://github.com/MohamedJebahi21/cinetrekker-android/actions)
[![Release](https://img.shields.io/github/v/release/MohamedJebahi21/cinetrekker-android?label=Latest%20Release&color=success)](https://github.com/MohamedJebahi21/cinetrekker-android/releases/latest)

*Discover. Track. Share.*

</div>

---

## ⬇️ Download

> **Get the latest release directly on your Android device:**

<div align="center">

[![Download APK](https://img.shields.io/badge/Download%20APK-v1.0.0-2ea44f?style=for-the-badge&logo=android&logoColor=white)](https://github.com/MohamedJebahi21/cinetrekker-android/releases/latest/download/cinetrekker-v1.0.0.apk)

</div>

> **Note:** Before installing, go to **Settings → Security → Install unknown apps** and enable it for your browser or file manager. CineTrekker requires **Android 7.0 (API 24)** or higher.

All releases are available on the [**Releases page**](https://github.com/MohamedJebahi21/cinetrekker-android/releases).

---

## ✨ Features

| Feature | Description |
|---|---|
| 🎬 **Movie & TV Discovery** | Browse trending, top-rated, and upcoming titles powered by TMDB |
| 📋 **Watchlist Management** | Save movies and TV shows to your personal watchlist |
| 📺 **TV Season Tracking** | Track which episodes you've watched, season by season |
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
│   ├── storage/      # Secure session + local file cache
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
│   ├── social/       # Comments & notifications
│   └── settings/     # App settings, theme, region, legal
└── shared/
    └── widgets/      # App-wide shared UI components
```

**Tech Stack:**
- **State Management**: [Riverpod](https://riverpod.dev) (AsyncNotifier)
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router)
- **Backend**: [Supabase](https://supabase.com) (Auth, Database, REST + RLS)
- **Movie Data**: [TMDB API](https://www.themoviedb.org/documentation/api) via server proxy
- **Local Storage**: `flutter_secure_storage` (sessions) + file cache (offline)
- **Crash reporting**: [Sentry](https://sentry.io) (optional via `CINETREKKER_SENTRY_DSN`)

---

## 🚀 Getting Started

### Prerequisites

| Tool | Version |
|---|---|
| Flutter | 3.x |
| Dart | 3.9+ |
| Android Studio | Giraffe or later |
| Java | 17+ |
| Android | minSdk 24 (Android 7.0)+ |

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/MohamedJebahi21/cinetrekker-android.git
   cd cinetrekker-android
   ```

2. **Copy the environment template**
   ```bash
   cp .env.example .env
   ```

3. **Fill in your environment variables** in `.env`:
   ```env
   CINETREKKER_SUPABASE_URL=https://your-project.supabase.co
   CINETREKKER_SUPABASE_ANON_KEY=your-anon-key
   CINETREKKER_API_BASE_URL=https://cinetrekker.vercel.app
   CINETREKKER_SENTRY_DSN=
   ```
   > You will need a [Supabase](https://supabase.com) project and a [TMDB API key](https://www.themoviedb.org/settings/api) on the server proxy.  
   > Config is injected at **build/run time** via `--dart-define` / `--dart-define-from-file`. It is **not** bundled as an APK asset.

4. **Install dependencies**
   ```bash
   flutter pub get
   ```

5. **Run the app**
   ```bash
   flutter run --dart-define-from-file=.env
   ```

### Building a Release APK

```bash
flutter build apk --release \
  --obfuscate \
  --split-debug-info=build/debug-info \
  --dart-define-from-file=.env
```

The signed APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

> Release builds require `android/key.properties` and enable R8 minify + resource shrinking.

---

## 🔐 Environment Variables

| Variable | Description | Required |
|---|---|---|
| `CINETREKKER_SUPABASE_URL` | Your Supabase project URL | ✅ |
| `CINETREKKER_SUPABASE_ANON_KEY` | Your Supabase anonymous key | ✅ |
| `CINETREKKER_API_BASE_URL` | Base URL for the CineTrekker backend / TMDB proxy | ✅ |
| `CINETREKKER_SENTRY_DSN` | Sentry DSN for production crash reporting | optional |

> **Caution:** Never commit your `.env` file. It is listed in `.gitignore`. Use `.env.example` as a reference template only.  
> Prefer GitHub Actions secrets named with the `CINETREKKER_` prefix (legacy unprefixed names are still accepted as fallbacks in CI).

### Backend security (RLS)

Client-side filters are **not** authorization. Apply and verify Supabase Row Level Security before release — see [`docs/supabase_rls.md`](docs/supabase_rls.md).

---

## 🔁 CI / CD

This repository uses GitHub Actions for continuous integration and automated releases:

| Workflow | Trigger | Description |
|---|---|---|
| [CI](.github/workflows/ci.yml) | Push / PR to `main` | Runs `flutter analyze` and `flutter test` |
| [Release](.github/workflows/release.yml) | Push tag `v*` | Builds obfuscated APK + AAB with `--dart-define-from-file`, creates GitHub Release |

To publish a new release:
```bash
git tag v1.2.0
git push origin v1.2.0
```
The Release workflow will automatically build and attach the APK to a GitHub Release.

---

## 📂 Project Structure (Key Files)

| File | Purpose |
|---|---|
| `lib/main.dart` | App entry point, crash boundary, Riverpod + Sentry setup |
| `lib/app.dart` | MaterialApp, GoRouter, theme wiring |
| `lib/core/auth/auth_controller.dart` | OAuth 2.0 PKCE session management |
| `lib/core/auth/oauth_callback_host.dart` | Deep link + shortcut routing |
| `lib/core/api/tmdb_api_service.dart` | TMDB REST client with caching |
| `lib/core/api/supabase_rest_api.dart` | Supabase backend client + 401 refresh |
| `android/app/src/main/AndroidManifest.xml` | Manifest, permissions, deep links |
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
© 2025 Mohamed Jebahi. Unauthorized copying, modification, or distribution is prohibited.

---

## 🙏 Acknowledgements

- Movie and TV data provided by [The Movie Database (TMDB)](https://www.themoviedb.org). _This product uses the TMDB API but is not endorsed or certified by TMDB._
- Streaming provider data via [JustWatch](https://www.justwatch.com).
- Backend powered by [Supabase](https://supabase.com).

---

<div align="center">
Made with ❤️ by <a href="https://github.com/MohamedJebahi21">Mohamed Jebahi</a>
</div>

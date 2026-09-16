# CineTrekker Android — Technical Architecture & Invariants

This document details the architectural design, component layers, data flows, and technical invariants of the CineTrekker Android codebase.

---

## 1. System Layers & Dependency Hierarchy

CineTrekker is architected in four distinct layers following a unidirectional data flow:

```
┌────────────────────────────────────────────────────────┐
│                   Presentation Layer                   │
│   Widgets, Screens, Dialogs, BottomSheets, Pressables  │
└───────────────────────────┬────────────────────────────┘
                            │ Dispatches User Actions
                            │ Observes State
┌───────────────────────────▼────────────────────────────┐
│                    Controller Layer                    │
│   Riverpod AsyncNotifier & Notifier Providers          │
└───────────────────────────┬────────────────────────────┘
                            │ Queries / Mutates Entities
┌───────────────────────────▼────────────────────────────┐
│                    Repository Layer                    │
│   Domain logic, Cache management, Offline Queue        │
└───────────────────────────┬────────────────────────────┘
                            │ Network / Storage I/O
┌───────────────────────────▼────────────────────────────┐
│                       Data Layer                       │
│  TmdbApiService (Proxy) │ SupabaseRestApi (PostgREST)  │
│  LocalCacheManager      │ FlutterSecureStorage         │
└────────────────────────────────────────────────────────┘
```

### Invariants:
1. **Widgets never call APIs directly**: Widgets communicate strictly with Riverpod controllers or repositories.
2. **Repositories never depend on UI context**: Repositories are pure Dart classes handling network, local cache, and error transformation.
3. **State is immutable**: State classes use `copyWith` and immutable collections.

---

## 2. Technical Data Flows

### A. TMDB Movie/TV Metadata Fetch Flow (with Caching & In-Flight Deduplication)
```
User navigates to Title Details (/details/:mediaType/:mediaId)
   │
   ▼
DetailsScreen reads detailsControllerProvider
   │
   ▼
DetailsController.load(mediaType: mediaType, mediaId: mediaId)
   │
   ▼
TmdbApiService.fetchDetails(mediaType, mediaId)
   │
   ▼
TmdbApiService._fetchJson(endpoint)
   │
   ├─► 1. Check in-flight request map (_inFlightRequests[cacheKey])
   │      └─► If pending: return existing Future (Deduplicates concurrent bursts)
   │
   ├─► 2. Execute HTTP GET to /api/tmdb-proxy on Environment.apiBaseUrl
   │      │
   │      ├─► Success (HTTP 200):
   │      │     ├─► Asynchronously write payload to LocalCacheManager (TTL: 24h)
   │      │     └─► Parse JSON into TmdbMediaDetails domain model
   │      │
   │      └─► Network / Timeout / Socket Error:
   │            ├─► Read LocalCacheManager snapshot for cacheKey
   │            ├─► If cache hit: return cached data (Graceful offline degradation)
   │            └─► If cache miss: throw user-friendly AppError
   ▼
DetailsController updates state (DetailsState(details: data, isLoading: false))
   ▼
DetailsScreen renders UI / AppErrorCard with retry
```

### B. Library Mutation & Offline Replay Flow
```
User taps "Add to Watchlist" or "Mark as Watched"
   │
   ▼
WatchlistController calls UserLibraryRepository.addToWatchlist(...)
   │
   ├─► 1. Optimistic Local Write:
   │      Updates LocalMediaListStorage immediately so UI reflects change instantly
   │
   ├─► 2. Check Authentication & Network:
   │      │
   │      ├─► Signed-in & Online:
   │      │     Send POST /rest/v1/user_watchlist via SupabaseRestApi.upsertRow
   │      │
   │      └─► Offline or Network Glitch:
   │            Enqueue OfflineMutation into OfflineMutationQueue
   │            (stored persistently in file cache via LocalCacheManager)
   │
   ▼
On next successful library fetch or network reconnect:
   UserLibraryRepository._flushMutationQueue() iterates queue FIFO:
   - For each OfflineMutation: execute remote SupabaseRestApi call
   - On success: remove mutation from OfflineMutationQueue
   - On error: stop flush and preserve remaining queue for next retry
```

### C. Authentication & Session Auto-Refresh Flow
```
App Startup (main.dart -> StartupConfigGate -> CineTrekkerApp)
   │
   ▼
AuthController.build():
   Read session JSON from FlutterSecureStorage (key: 'cinetrekker_auth_session')
   │
   ├─► Valid and unexpired: restore CineTrekkerAuthSession
   │
   ├─► Expired but has refreshToken:
   │      Execute POST /auth/v1/token?grant_type=refresh_token
   │      Update secure storage and restore session
   │
   └─► Invalid / empty: enter Guest Mode (session is null)
   │
During App Execution (Dio Interceptor in SupabaseRestApi):
   On HTTP 401 Unauthorized response from Supabase PostgREST:
      1. Trigger AuthController.refreshSession()
      2. If refreshed: update Authorization header to 'Bearer $refreshedToken'
      3. Replay request seamlessly via dio.fetch(requestOptions)
      4. If refresh fails: propagate error to UI
```

---

## 3. Database Architecture & Row Level Security (RLS)

All cloud data is hosted on Supabase (PostgreSQL) and accessed via PostgREST `/rest/v1`.

### Security Model:
- **Zero Client-Side Trust**: Client passes `user_id` strictly for query convenience, but PostgreSQL RLS guarantees that only rows where `auth.uid() = user_id` can be read or written.
- **Public Tables**: `public.profiles` allows public read access for users where `is_public = true`.
- **Private Tables**: `user_watchlist`, `user_watched`, `watched_episodes`, `followed_shows`, `notifications`, `collections` are strictly private to the authenticated owner (`auth.uid() = user_id`).
- **Social Tables**: `comments` and `comment_likes` can be read by authenticated users, but mutations require `auth.uid() = user_id`.
- **Follows Table**: `user_follows` enforces `auth.uid() = follower_id` on insert, and either party can delete the edge.

Refer to `docs/supabase_rls.md` and `docs/supabase_rls_apply.sql` for the authoritative schema definitions.

---

## 4. Routing & Shell Architecture

The router in `lib/router/app_router.dart` uses **GoRouter** with a dual navigator hierarchy:
- **`_rootNavigatorKey`**: Used for full-screen routes that overlay and hide the bottom navigation bar (`/details/:mediaType/:mediaId`, `/person/:personId`, `/auth`, `/login`, `/tv-tracking`, `/feedback`, etc.).
- **`ShellRoute` with `AppScaffold`**: Wraps core tabs (`/`, `/discover`, `/search`, `/watchlist`, `/profile`, `/settings`, `/social`) to maintain persistent bottom navigation and tab state.
- **Predictive & Custom Transitions**:
  - `buildPageWithSlideTransition`: Slide-up + fade-in (240ms) for detail and modal pages.
  - `buildPageWithFadeTransition`: Cross-fade (180ms) for bottom navigation tab switching.
  - Honors `disableAnimations` / `reducedMotionStyle`.

---

## 5. Architectural Constraints (Must Not Break)

1. **TMDB Secret Protection**: Never embed TMDB API tokens into client code or `.env`. The client must only ever query `/api/tmdb-proxy`.
2. **Offline Resilience**: Guest mode and offline usage must always display cached content and allow local list edits. Do not block the app behind a mandatory login screen.
3. **Typography Scaling**: Font size scaling operates on `MediaQuery.textScaler` in `lib/app.dart`. Widgets must use `GoogleFonts.spaceGrotesk` and `GoogleFonts.dmSans` without hardcoded line wrapping constraints that clip at 1.30× scale.
4. **Haptics and Semantics**: User mutations (watchlist, favorites, rating submissions) must trigger tactile feedback via `Haptics` and screen-reader announcements via `AppSemantics` (`SemanticsService.sendAnnouncement`).

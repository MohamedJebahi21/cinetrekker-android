# CineTrekker Android — Technical Architecture

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
User navigates to Title Details
   │
   ▼
DetailsScreen reads detailsControllerProvider(mediaType, mediaId)
   │
   ▼
DetailsController calls TmdbApiService.fetchDetails(mediaType, mediaId)
   │
   ├─► Check in-flight request map (_inFlightRequests)
   │     └─► If pending: return existing Future (Deduplication)
   │
   ├─► Execute HTTP GET to /api/tmdb-proxy on Environment.apiBaseUrl
   │     │
   │     ├─► Success:
   │     │     ├─► Asynchronously write payload to LocalCacheManager (TTL: 24h)
   │     │     └─► Parse into TmdbMediaDetails model
   │     │
   │     └─► Network / Timeout Error:
   │           ├─► Check LocalCacheManager for cached snapshot
   │           ├─► If cache hit: return cached data (Graceful degradation)
   │           └─► If cache miss: throw user-friendly AppError
   ▼
DetailsController updates state with AsyncData / AsyncError
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
   │      Update LocalMediaListStorage immediately so UI reflects change instantly
   │
   ├─► 2. Check Authentication & Network:
   │      │
   │      ├─► Signed-in & Online:
   │      │     Send POST/UPSERT via SupabaseRestApi
   │      │
   │      └─► Offline or Network Failure:
   │            Enqueue mutation into OfflineMutationQueue
   │            (stored persistently via LocalCacheManager)
   │
   ▼
On next successful library load or network reconnect:
   UserLibraryRepository._flushMutationQueue() iterates queue FIFO:
   - For each OfflineMutation: execute remote Supabase call
   - On success: remove from queue
   - On error: stop flush and preserve remaining queue for next retry
```

### C. Authentication & Session Auto-Refresh Flow
```
App Startup (main.dart -> StartupConfigGate -> CineTrekkerApp)
   │
   ▼
AuthController.build():
   Read session JSON from FlutterSecureStorage
   │
   ├─► Valid and unexpired: restore CineTrekkerAuthSession
   │
   ├─► Expired but has refresh token:
   │      Execute POST /auth/v1/token?grant_type=refresh_token
   │      Update secure storage and restore session
   │
   └─► Invalid / empty: enter Guest Mode (session is null)
   │
During App Execution (Dio Interceptor in SupabaseRestApi):
   On 401 Unauthorized response from Supabase PostgREST:
      1. Trigger AuthController.refreshSession()
      2. If refreshed: update Authorization header and retry request seamlessly
      3. If refresh fails: propagate 401 and prompt re-authentication
```

---

## 3. Database Architecture & Row Level Security (RLS)

All cloud data is hosted on Supabase (PostgreSQL) and accessed via PostgREST.

### Security Model:
- **Zero Client-Side Trust**: Client passes `user_id` strictly for querying ergonomics, but PostgreSQL RLS guarantees that only rows where `auth.uid() = user_id` can be read or written.
- **Public Tables**: `public.profiles` allows public read access for users where `is_public = true`.
- **Private Tables**: `watchlist`, `watched`, `tv_progress`, `favorites`, `notifications`, `collections_user` are strictly private to the authenticated owner.
- **Social Tables**: `comments` and `comment_likes` can be read by authenticated users, but mutations require `auth.uid() = user_id`.

Refer to `docs/supabase_rls.md` and `docs/supabase_rls_apply.sql` for the authoritative schema definitions.

---

## 4. Routing & Shell Architecture

The router in `lib/router/app_router.dart` uses **GoRouter** with a dual navigator hierarchy:
- **`_rootNavigatorKey`**: Used for full-screen routes that overlay and hide the bottom navigation bar (e.g. `/details`, `/auth`, `/login`, `/tv-tracking`, `/feedback`).
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
4. **Haptics and Semantics**: User mutations (watchlist, favorites, rating submissions) must trigger tactile feedback via `Haptics` and screen-reader announcements via `AppSemantics`.

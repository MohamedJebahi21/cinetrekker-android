# CineTrekker Android — Definition of Done (DoD)

Any engineering task, bug fix, or feature implementation performed on this repository is NOT complete until all applicable items below are satisfied.

---

## 1. Functionality & Logic
- [ ] Intended behavior works completely as specified.
- [ ] Edge cases (network timeouts, empty data, unexpected nulls, rapid multi-taps) are handled gracefully.
- [ ] Existing functionality is preserved without unintended side effects or regressions.
- [ ] Offline resilience is verified (actions either execute from local cache or enqueue to `OfflineMutationQueue`).

## 2. Code Quality & Standards
- [ ] Static analysis passes with **0 errors, 0 warnings, 0 fatal infos**:
  ```bash
  flutter analyze
  ```
- [ ] Code strictly reuses existing design tokens, models, and shared components from `lib/shared/widgets/`:
  - `BouncyPressable` for tactile spring buttons and cards
  - `AppCachedImage` for shimmer-loaded network images
  - `AppErrorCard` for standardized error recovery
  - `AppScaffold` for shell layouts
- [ ] No duplicate abstractions or parallel data stores are introduced.
- [ ] Code is formatted according to standard Dart conventions:
  ```bash
  dart format .
  ```
- [ ] No dead code, temporary debug prints (`print()`), or commented-out code blocks left behind.

## 3. UI, Tactile & Accessibility
- [ ] **Complete State Handling**:
  - [ ] **Loading State**: Displays skeleton shimmer (`SkeletonLoader`) or subtle indicator.
  - [ ] **Empty State**: Displays clear iconography, friendly copy, and primary action.
  - [ ] **Error State**: Displays `AppErrorCard` with recoverable retry button.
  - [ ] **Success State**: Displays floating SnackBar and haptic confirmation.
- [ ] **Tactile Feedback**: Interactive touch targets trigger appropriate `Haptics` (`selection`, `light`, `buttonTap`, `addToWatchlist`, etc.).
- [ ] **Spring Physics**: Interactive buttons and cards use `BouncyPressable`.
- [ ] **Typography & Text Scaling**: Verified to render without layout overflow or text clipping at scales from **0.85× up to 1.30×**.
- [ ] **Screen Reader (TalkBack)**: Important mutations announce state changes via `AppSemantics` (`SemanticsService.sendAnnouncement`). Interactive buttons have descriptive `Semantics` labels.

## 4. Security & Privacy
- [ ] No hardcoded API keys, bearer tokens, or sensitive credentials exist in code or commit history.
- [ ] TMDB requests strictly route through `/api/tmdb-proxy` on `Environment.apiBaseUrl`.
- [ ] Supabase queries conform to Row Level Security (RLS) policies defined in `docs/supabase_rls.md`.
- [ ] Auth sessions are persisted only via encrypted `FlutterSecureStorage`.
- [ ] User privacy and content safety settings (adult content filtering) are honored.

## 5. Performance & Efficiency
- [ ] Network requests take advantage of `LocalCacheManager` and in-flight deduplication where appropriate.
- [ ] Lists and grids use lazy item builders (`ListView.builder`, `GridView.builder`) with cached images (`AppCachedImage`).
- [ ] Unnecessary widget rebuilds and provider invalidations are avoided.

## 6. Testing & Automated Verification
- [ ] Full test suite passes:
  ```bash
  flutter test
  ```
- [ ] New core logic, utility methods, or models include corresponding unit tests under `test/`.
- [ ] If native Android build files (`android/`) are touched, verify compilation:
  ```bash
  flutter build apk --release
  ```

## 7. Mandatory Documentation Protocol
- [ ] **`PROJECT_CONTEXT.md`** updated to reflect feature changes, status, or known issues.
- [ ] **`ARCHITECTURE.md`** updated if data flows, component relationships, or technical constraints were altered.
- [ ] **`CHANGELOG.md`** updated with a factual, standardized entry under the corresponding date/version.
- [ ] No documentation contradicts the actual source code.

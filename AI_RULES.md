# AI Engineering Rules & Repository Operating System

## 1. Repository Authority
The repository is the ultimate and sole source of truth.
- Do NOT rely on prior chat memory, outside assumptions, or hallucinated APIs.
- Always inspect the actual source code, configurations, and models to verify current behavior.
- If documentation and code ever disagree, treat the source code as evidence, investigate the discrepancy, resolve it, and update the documentation.

## 2. Mandatory Context Loading
Before starting any non-trivial implementation, debugging, or refactoring task, you MUST read the following foundational documents in order:
1. `AI_RULES.md` (this file)
2. `PROJECT_CONTEXT.md` (current state, tech stack, feature status, project map)
3. `ARCHITECTURE.md` (system layers, data flows, offline architecture, state flow)
4. `DEFINITION_OF_DONE.md` (quality gates, verification checklists, standards)

Then, inspect the primary and supporting source files for the feature as indexed in the Project Map in `PROJECT_CONTEXT.md`.

## 3. Mandatory Engineering Workflow
Every task must strictly proceed through the 7 engineering stages:
```
UNDERSTAND ──> INVESTIGATE ──> PLAN ──> IMPLEMENT ──> TEST ──> VERIFY ──> DOCUMENT
```
1. **UNDERSTAND**: Clarify the requirement, user goals, and boundaries.
2. **INVESTIGATE**: Search and inspect existing code, models, controllers, and tests. Trace the full flow.
3. **PLAN**: Choose the cleanest architectural approach matching existing patterns. Identify affected files.
4. **IMPLEMENT**: Write focused, clean code adhering to existing conventions.
5. **TEST**: Run automated tests (`flutter test`) and static analysis (`flutter analyze`).
6. **VERIFY**: Check edge cases, error states, empty states, text scaling, haptics, and TalkBack semantics.
7. **DOCUMENT**: Update `PROJECT_CONTEXT.md`, `CHANGELOG.md`, and `ARCHITECTURE.md` as required.

## 4. No Guessing Principle
AI agents must NEVER assume or invent:
- File paths or directory locations
- REST endpoints or backend proxy routes
- Database tables, columns, or relations
- Environment variables or secrets
- Packages or external dependencies
- Business rules or licensing constraints
- Authentication states or authorization bypasses

If uncertain, query the codebase using grep, file inspection, or terminal verification.

## 5. Existing-Code-First Principle
Before creating any new widget, service, helper, provider, or abstraction:
- Search the repository for existing implementations that can be reused or extended.
- Reuse shared components from `lib/shared/widgets/` (e.g., `BouncyPressable`, `AppCachedImage`, `AppErrorCard`, `SkeletonLoader`).
- Reuse core services from `lib/core/` (e.g., `Haptics`, `AppSemantics`, `LocalCacheManager`, `OfflineMutationQueue`, `describeAppError`).
- Avoid duplicate logic, parallel state stores, or redundant abstraction layers.

## 6. Minimal-Change Principle
- Make the smallest correct change that completely solves the problem.
- Do NOT refactor unrelated files, reformat unchanged code, or rename classes outside the scope.
- Do NOT replace existing packages or introduce new dependencies without explicit justification.
- If an unrelated defect or debt is discovered during investigation, document it in `PROJECT_CONTEXT.md` under **Known Issues** rather than modifying it opportunistically.

## 7. Preserve Existing Functionality
- Treat existing features, route parameters, offline queue mutations, and tests as critical contracts.
- Never delete or bypass existing behavior unless specifically instructed by the user.

## 8. Security & Secret Protection
- Secrets and API keys must NEVER be hardcoded, logged, or checked into version control.
- Configuration is provided at build/run time via `--dart-define` / `--dart-define-from-file=.env` via `lib/core/constants/environment.dart`.
- The Android client talks to TMDB strictly through the server-side proxy `/api/tmdb-proxy` on `Environment.apiBaseUrl` so that TMDB API keys remain unexposed.
- Supabase access uses the anonymous key + OAuth 2.0 PKCE user access token. Row Level Security (RLS) policies defined in `docs/supabase_rls.md` must be respected. Never rely on client-side authorization for sensitive data.

## 9. UI & Design System Guidelines
- Design system follows **Material You** with editorial cinema aesthetics: signature CineTrekker red accent (`#E50914`), deep neutral surfaces, and AMOLED true black (`#000000`).
- Typography uses Google Fonts: **Space Grotesk** for headings/titles and **DM Sans** for body/metadata.
- Always provide complete UI states:
  - **Loading State**: Shimmer skeleton loader or linear progress bar.
  - **Empty State**: Informative icon, friendly explanation, and primary call-to-action.
  - **Error State**: `AppErrorCard` with user-friendly copy and retry callback.
  - **Success Feedback**: Floating SnackBar and subtle haptic feedback (`Haptics`).
- Accessibility:
  - Support font scaling from 0.85× to 1.30× without UI clipping.
  - Announce major state changes to screen readers using `AppSemantics`.
  - Provide descriptive `Semantics` wrappers for interactive icons and buttons.
- Tactile & Motion:
  - Wrap interactive elements with `BouncyPressable` spring physics.
  - Respect system `disableAnimations` / `reducedMotionStyle`.

## 10. Verification & Quality Gates
Before declaring any task complete:
- Run `flutter analyze` — Must report **0 errors, 0 warnings**.
- Run `flutter test` — All tests must pass.
- Verify release/build integrity when touching native Android configurations.

## 11. Self-Maintaining Documentation Protocol
After completing ANY meaningful change:
1. Update `PROJECT_CONTEXT.md` (features, status, known issues, recent changes).
2. Update `ARCHITECTURE.md` (if component relationships, data flow, or models changed).
3. Record an entry in `CHANGELOG.md` following the standardized format.
4. Verify all documentation accurately reflects the codebase. Never leave stale claims.

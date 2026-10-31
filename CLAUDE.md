# Claude Code — Repository Guidelines


> **Current source of truth:** read `AI_RULES.md`, `PROJECT_CONTEXT.md`, `ARCHITECTURE.md`, and `DEFINITION_OF_DONE.md` before non-trivial work. The last verified published release is v1.1.5; any v1.1.6 material in the working tree is unreleased until CI and release assets are verified. Share/export/deletion implementation boundaries and known limitations are documented in `PROJECT_CONTEXT.md` and `ARCHITECTURE.md`. In particular, current app deletion removes app data and signs out but does not delete the Supabase Auth identity.

You are working on the **CineTrekker Android** codebase.

## Mandatory Context
Before making any changes, inspect the canonical engineering documents:
- **`AI_RULES.md`** — Repository authority, strict workflow, and security rules.
- **`PROJECT_CONTEXT.md`** — Technology stack, features, and the Project Map (where to look for code).
- **`ARCHITECTURE.md`** — Technical layers, offline queue, and data flow traces.
- **`DEFINITION_OF_DONE.md`** — Quality gates and completion checklist.

## Core Commands
- Analyze: `flutter analyze`
- Test: `flutter test`
- Format: `dart format .`
- Run: `flutter run --dart-define-from-file=.env`
- Build Release APK: `flutter build apk --release`

## Critical Rules
- Do NOT guess APIs, routes, or database columns.
- Reuse shared widgets in `lib/shared/widgets/` (`BouncyPressable`, `AppCachedImage`, `AppErrorCard`).
- Never expose TMDB API keys; all TMDB queries must pass through `/api/tmdb-proxy` on `Environment.apiBaseUrl`.
- After every non-trivial task, update `PROJECT_CONTEXT.md` and `CHANGELOG.md`.

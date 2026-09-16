# Claude Code — Repository Guidelines

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

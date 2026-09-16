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
- Build Release APK: `flutter build apk --release`

## Critical Rules
- Do NOT guess APIs or routes.
- Re-use shared widgets in `lib/shared/widgets/`.
- Never expose TMDB API keys; all TMDB queries must pass through `/api/tmdb-proxy`.
- After every non-trivial task, update `PROJECT_CONTEXT.md` and `CHANGELOG.md`.

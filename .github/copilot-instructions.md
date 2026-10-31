# GitHub Copilot Instructions — CineTrekker Android


> **Current source of truth:** read `AI_RULES.md`, `PROJECT_CONTEXT.md`, `ARCHITECTURE.md`, and `DEFINITION_OF_DONE.md` before non-trivial work. The last verified published release is v1.1.5; any v1.1.6 material in the working tree is unreleased until CI and release assets are verified. Share/export/deletion implementation boundaries and known limitations are documented in `PROJECT_CONTEXT.md` and `ARCHITECTURE.md`. In particular, current app deletion removes app data and signs out but does not delete the Supabase Auth identity.

When generating or refactoring code in this repository:

1. Follow the canonical guidelines defined in **`AI_RULES.md`**.
2. Consult **`PROJECT_CONTEXT.md`** for current tech stack, 35 Riverpod providers, database schema, routes, and feature map.
3. Observe architectural layers and data flows in **`ARCHITECTURE.md`**.
4. Satisfy the completion checklist in **`DEFINITION_OF_DONE.md`**.

Key Engineering Invariants:
- Framework: Flutter 3.x, Dart 3.10+, Riverpod 2.6 for state management, GoRouter 16.3 for routing.
- Never query TMDB directly from the client; always route through `/api/tmdb-proxy` on `Environment.apiBaseUrl`.
- Supabase access uses Row Level Security (RLS) in PostgreSQL; client-side filters are not authorization.
- Re-use shared widgets in `lib/shared/widgets/` (`BouncyPressable`, `AppCachedImage`, `AppErrorCard`, `AppScaffold`).
- Handle all UI states: Loading (`SkeletonLoader`), Empty, Error (`AppErrorCard`), and Success (`Haptics`).
- Support font size scaling from 0.85× up to 1.30× without UI clipping.
- Verify changes with `flutter analyze` and `flutter test`.

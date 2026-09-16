# GitHub Copilot Instructions — CineTrekker Android

When generating or refactoring code in this repository:

1. Follow the canonical guidelines defined in **`AI_RULES.md`**.
2. Consult **`PROJECT_CONTEXT.md`** for current tech stack, routes, and feature map.
3. Observe architectural layers and flows in **`ARCHITECTURE.md`**.
4. Satisfy the completion checklist in **`DEFINITION_OF_DONE.md`**.

Key Engineering Invariants:
- Framework: Flutter 3.x, Dart 3.9+, Riverpod 2.6 for state management, GoRouter 16.3 for routing.
- Never query TMDB directly from the client; always route through `/api/tmdb-proxy` on `Environment.apiBaseUrl`.
- Supabase access uses Row Level Security (RLS) in PostgreSQL; client-side filters are not authorization.
- Handle all UI states: Loading (shimmer), Empty, Error (`AppErrorCard`), and Success (`Haptics`).
- Support font size scaling from 0.85× up to 1.30× without UI clipping.
- Verify changes with `flutter analyze` and `flutter test`.

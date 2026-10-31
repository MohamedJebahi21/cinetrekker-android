# Gemini / Antigravity — Repository Instructions


> **Current source of truth:** read `AI_RULES.md`, `PROJECT_CONTEXT.md`, `ARCHITECTURE.md`, and `DEFINITION_OF_DONE.md` before non-trivial work. The last verified published release is v1.1.5; any v1.1.6 material in the working tree is unreleased until CI and release assets are verified. Share/export/deletion implementation boundaries and known limitations are documented in `PROJECT_CONTEXT.md` and `ARCHITECTURE.md`. In particular, current app deletion removes app data and signs out but does not delete the Supabase Auth identity.

Welcome to the **CineTrekker Android** codebase.

## Canonical Instructions & Context
Before making code changes, read the canonical repository guidelines:
- **`AI_RULES.md`** — Repository authority, strict 7-step engineering workflow, and security principles.
- **`PROJECT_CONTEXT.md`** — Architectural state, routes, features, 35 Riverpod providers, and the Project Map.
- **`ARCHITECTURE.md`** — Layer architecture, offline mutation flow, and invariants.
- **`DEFINITION_OF_DONE.md`** — Quality gates and completion checklist.

## Operational Workflow
1. Read the foundational documents above.
2. Inspect the relevant files indexed in the Project Map inside `PROJECT_CONTEXT.md`.
3. Plan minimal, focused modifications reusing existing widgets from `lib/shared/widgets/`.
4. Verify with `flutter analyze` and `flutter test`.
5. Keep documentation updated (`PROJECT_CONTEXT.md`, `CHANGELOG.md`).

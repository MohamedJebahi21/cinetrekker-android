# Gemini / Antigravity — Repository Instructions

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

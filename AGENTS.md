# AI Agent Repository Instructions


> **Current source of truth:** read `AI_RULES.md`, `PROJECT_CONTEXT.md`, `ARCHITECTURE.md`, and `DEFINITION_OF_DONE.md` before non-trivial work. The last verified published release is v1.1.5; any v1.1.6 material in the working tree is unreleased until CI and release assets are verified. Share/export/deletion implementation boundaries and known limitations are documented in `PROJECT_CONTEXT.md` and `ARCHITECTURE.md`. In particular, current app deletion removes app data and signs out but does not delete the Supabase Auth identity.

Welcome to the CineTrekker Android codebase.

This repository enforces an agent-independent, persistent engineering operating system.

## Canonical Instructions & Context
Before reading or modifying application code, you **MUST** read the following foundational documents in order:

1. **[AI_RULES.md](AI_RULES.md)** — Core engineering rules, code standards, workflow protocol, and security invariants.
2. **[PROJECT_CONTEXT.md](PROJECT_CONTEXT.md)** — Project overview, tech stack, routes, features, data models, and the Project Map.
3. **[ARCHITECTURE.md](ARCHITECTURE.md)** — Layered architecture, data flows, offline sync, and technical invariants.
4. **[DEFINITION_OF_DONE.md](DEFINITION_OF_DONE.md)** — Verification checklist, quality gates, and completion criteria.

## Engineering Workflow
Always adhere to the mandatory workflow:
```
UNDERSTAND ──> INVESTIGATE ──> PLAN ──> IMPLEMENT ──> TEST ──> VERIFY ──> DOCUMENT
```

## Quick Verification Commands
- Static Analysis: `flutter analyze`
- Test Suite: `flutter test`
- Run App: `flutter run --dart-define-from-file=.env`
- Build Release APK: `flutter build apk --release`

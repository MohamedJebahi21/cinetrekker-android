# AI Agent Repository Instructions

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

# Frontend — KyrgyzExplore Flutter App

> You are operating as the **Fullstack Agent** (frontend half).
> Read your full system prompt at `../agents/fullstack-agent.md` before starting work.
> Only consume API calls that exist in `../agents/api-contract.md`.
> If you need a new endpoint, update `../agents/api-contract.md` (or flag to Architecture Agent).

## Quick Reference

| Item | Value |
|---|---|
| Framework | Flutter (stable channel) |
| Language | Dart 3.x |
| State | Riverpod (code-gen) |
| Navigation | GoRouter |
| HTTP | Dio |
| Targets | iOS 15+ / Android API 26+ |

## Run Locally
```bash
# Pass API URL and Maps key at run time — never hardcode
flutter run \
  --dart-define=API_BASE_URL=http://localhost:8080/api/v1 \
  --dart-define=WS_BASE_URL=ws://localhost:8080 \
  --dart-define=MAPS_KEY=YOUR_KEY_HERE
```

## Generate Code (models, providers)
```bash
dart run build_runner build --delete-conflicting-outputs
# Watch mode during development:
dart run build_runner watch --delete-conflicting-outputs
```

## Run Tests
```bash
flutter test                        # all tests
flutter test test/features/auth/    # single feature
flutter test --coverage             # with coverage
```

## Check for a HANDOFF.md
Before doing anything, check if there's a `HANDOFF.md` in this directory.
If yes, read it, complete the task, then delete it and commit.

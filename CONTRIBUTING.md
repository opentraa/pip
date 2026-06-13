# Contributing

## Setup

```bash
flutter pub get
```

## Checks

```bash
./scripts/check.sh
./scripts/check_spm.sh
./scripts/check_android_deprecated_api.sh
```

Run Android and iOS example builds when changing native code:

```bash
cd example
flutter build apk --debug
flutter build ios --no-codesign
```

## Pull Requests

- Link an issue when possible.
- Add tests for behavior changes.
- Update README or example docs for user-facing changes.
- Do not update versions outside release PRs.

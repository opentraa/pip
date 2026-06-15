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

## Release Automation

This repository uses a two-stage release flow:

1. Trigger the `Release` GitHub Actions workflow with a version such as `0.0.4`.
2. The workflow generates release notes, runs checks, bumps release metadata,
   creates the release commit and tag, and publishes a GitHub Release.
3. The pushed tag automatically triggers the `Publish` workflow, which publishes
   the package to `pub.dev`.

Repository configuration requirements:

- `GITHUB_TOKEN` must be allowed to create releases and push tags.
- The `Release` workflow requires `models: read` so GitHub Models can summarize
  the generated release notes. If GitHub Models is unavailable, the workflow
  falls back to the generated GitHub release notes without the AI summary.
- The `Publish` workflow requires the `pub.dev` environment to be configured
  for Dart automated publishing with GitHub Actions OIDC.

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

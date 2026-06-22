#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
workflow="$repo_root/.github/workflows/publish.yml"

grep -Fq "on:" "$workflow"
grep -Fq "  workflow_dispatch:" "$workflow"
grep -Fq "      tag:" "$workflow"
grep -Fq "        description: Existing release tag to publish, for example v0.0.4" "$workflow"
grep -Fq "  push:" "$workflow"
grep -Fq "      - 'v[0-9]+.[0-9]+.[0-9]+'" "$workflow"

grep -Fq "  dry-run:" "$workflow"
grep -Fq "    if: github.event_name == 'workflow_dispatch'" "$workflow"
grep -Fq "uses: dart-lang/setup-dart@v1" "$workflow"
grep -Fq "run: ./scripts/check.sh" "$workflow"
grep -Fq "run: ./scripts/check_release_ready.sh" "$workflow"
grep -Fq "run: ./scripts/publish.sh dry-run" "$workflow"

grep -Fq "  prepublish:" "$workflow"
grep -Fq "    if: github.event_name == 'push'" "$workflow"
grep -Fq "run: ./scripts/check.sh" "$workflow"
grep -Fq "run: ./scripts/check_release_ready.sh" "$workflow"

grep -Fq "  publish:" "$workflow"
grep -Fq "    if: github.event_name == 'push'" "$workflow"
grep -Fq "    needs: prepublish" "$workflow"
grep -Fq "uses: dart-lang/setup-dart/.github/workflows/publish.yml@v1" "$workflow"
grep -Fq "id-token: write" "$workflow"

if grep -Fq "./scripts/publish.sh publish" "$workflow"; then
  echo "publish workflow should use the Dart reusable publish workflow for real publishing" >&2
  exit 1
fi

echo "publish workflow tests passed"

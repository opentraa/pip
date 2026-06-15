#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
workflow="$repo_root/.github/workflows/publish.yml"

grep -Fq "on:" "$workflow"
grep -Fq "  workflow_dispatch:" "$workflow"
grep -Fq "  push:" "$workflow"
grep -Fq "      - 'v*.*.*'" "$workflow"
grep -Fq "    environment: pub.dev" "$workflow"
grep -Fq "uses: dart-lang/setup-dart@v1" "$workflow"

echo "publish workflow tests passed"

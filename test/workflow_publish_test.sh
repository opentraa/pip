#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
workflow="$repo_root/.github/workflows/publish.yml"

grep -Fq "on:" "$workflow"
grep -Fq "  workflow_dispatch:" "$workflow"
grep -Fq "      tag:" "$workflow"
grep -Fq "        description: Existing release tag to publish, for example v0.0.4" "$workflow"
grep -Fq "  push:" "$workflow"
grep -Fq "      - 'v*.*.*'" "$workflow"
grep -Fq "    environment: pub.dev" "$workflow"
grep -Fq "uses: dart-lang/setup-dart@v1" "$workflow"
grep -Fq "format('refs/tags/{0}', inputs.tag)" "$workflow"
grep -Fq '|| github.ref }}' "$workflow"
grep -Fq 'if [[ "${GITHUB_REF_NAME}" != v*.*.* ]]; then' "$workflow"

echo "publish workflow tests passed"

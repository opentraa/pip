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
grep -Fq 'REQUESTED_TAG: ${{ github.event_name == '\''workflow_dispatch'\'' && inputs.tag || github.ref_name }}' "$workflow"
grep -Fq 'if [[ ! "${REQUESTED_TAG}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then' "$workflow"
grep -Fq 'actual_tag="$(git describe --tags --exact-match HEAD 2>/dev/null || true)"' "$workflow"
grep -Fq 'git rev-parse -q --verify "refs/tags/${REQUESTED_TAG}" >/dev/null' "$workflow"

echo "publish workflow tests passed"

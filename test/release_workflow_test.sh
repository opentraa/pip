#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
workflow="$repo_root/.github/workflows/release.yml"

grep -Fq 'models: read' "$workflow"
grep -Fq 'Generate release notes' "$workflow"
grep -Fq './scripts/generate_release_notes.sh ${{ inputs.version }} ${{ github.repository }} ${{ github.ref_name }} .release-notes.md' "$workflow"

echo "release workflow tests passed"

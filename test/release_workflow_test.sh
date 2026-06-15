#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
workflow="$repo_root/.github/workflows/release.yml"

grep -Fq 'actions: write' "$workflow"
grep -Fq 'Generate release notes' "$workflow"
grep -Fq './scripts/generate_release_notes.sh ${{ inputs.version }} ${{ github.repository }} ${{ github.ref_name }} .release-notes.md' "$workflow"
grep -Fq 'npm run release -- --ci --verbose ${{ inputs.version }}' "$workflow"
grep -Fq 'gh workflow run Publish --ref v${{ inputs.version }}' "$workflow"
if grep -Fq 'GITHUB_MODELS_TOKEN' "$workflow"; then
  echo "release workflow should not set a GitHub Models token" >&2
  exit 1
fi

echo "release workflow tests passed"

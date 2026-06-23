#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readme="$repo_root/README.md"

grep -Fq 'using a `vX.Y.Z` tag.' "$readme"
grep -Fq 'manually create and push a matching' "$readme"
grep -Fq '`X.Y.Z` tag to trigger the `Publish` workflow for `pub.dev`.' "$readme"

if grep -Fq 'The resulting tag automatically triggers the `Publish` workflow for `pub.dev`.' "$readme"; then
  echo "README should not describe GitHub release tags as automatically publishing to pub.dev" >&2
  exit 1
fi

echo "release process docs tests passed"

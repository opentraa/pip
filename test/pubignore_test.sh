#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pubignore="$repo_root/.pubignore"

grep -Fq 'node_modules/' "$pubignore"
grep -Fq 'package.json' "$pubignore"
grep -Fq 'package-lock.json' "$pubignore"
grep -Fq '.release-it.json' "$pubignore"
grep -Fq '.release-notes.md' "$pubignore"

echo ".pubignore tests passed"

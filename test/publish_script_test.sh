#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! grep -Fq 'dart pub publish --force' "$repo_root/scripts/publish.sh"; then
  echo "publish.sh must use non-interactive pub publish --force" >&2
  exit 1
fi

if ! grep -Fq 'dart pub publish --dry-run' "$repo_root/scripts/publish.sh"; then
  echo "publish.sh must keep dry-run mode" >&2
  exit 1
fi

echo "publish.sh tests passed"

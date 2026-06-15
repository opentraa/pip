#!/usr/bin/env bash
set -euo pipefail

mode="${1:-dry-run}"

case "$mode" in
  dry-run)
    dart pub publish --dry-run
    ;;
  publish)
    dart pub publish --force
    ;;
  *)
    echo "Usage: $0 [dry-run|publish]" >&2
    exit 64
    ;;
esac

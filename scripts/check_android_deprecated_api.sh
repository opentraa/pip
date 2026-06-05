#!/usr/bin/env bash
set -euo pipefail

matches="$(git grep -n -E 'PictureInPictureUiState|onPictureInPictureUiStateChanged' -- android/src/main/java || true)"

if [[ -n "$matches" ]]; then
  echo "Deprecated Android PiP API usage found:" >&2
  echo "$matches" >&2
  exit 1
fi

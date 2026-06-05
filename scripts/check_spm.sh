#!/usr/bin/env bash
set -euo pipefail

output="$(mktemp)"
trap 'rm -f "$output"' EXIT

flutter pub get 2>&1 | tee "$output"

if grep -Eq "do not support Swift Package Manager|does not have Swift Package Manager support|missing a dependency on FlutterFramework" "$output"; then
  echo "Swift Package Manager support warning found in flutter pub get output." >&2
  exit 1
fi

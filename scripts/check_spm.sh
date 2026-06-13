#!/usr/bin/env bash
set -euo pipefail

if command -v flutter >/dev/null 2>&1; then
  flutter_bin="$(command -v flutter)"
  flutter_cmd=("$flutter_bin")
elif command -v fvm >/dev/null 2>&1; then
  flutter_cmd=(fvm flutter)
else
  echo "flutter executable not found" >&2
  exit 127
fi

output="$(mktemp)"
trap 'rm -f "$output"' EXIT

"${flutter_cmd[@]}" pub get 2>&1 | tee "$output"

if grep -Eq "do not support Swift Package Manager|does not have Swift Package Manager support|missing a dependency on FlutterFramework" "$output"; then
  echo "Swift Package Manager support warning found in flutter pub get output." >&2
  exit 1
fi

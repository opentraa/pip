#!/usr/bin/env bash
set -euo pipefail

if command -v flutter >/dev/null 2>&1; then
  flutter_bin="$(command -v flutter)"
  flutter_cmd=("$flutter_bin")
elif command -v fvm >/dev/null 2>&1; then
  flutter_cmd=(fvm flutter)
elif [[ -x "/Users/sylar/fvm/versions/stable/bin/flutter" ]]; then
  flutter_cmd=("/Users/sylar/fvm/versions/stable/bin/flutter")
else
  echo "flutter executable not found" >&2
  exit 127
fi

if command -v dart >/dev/null 2>&1; then
  dart_cmd=(dart)
elif [[ -n "${flutter_bin:-}" && -x "$(dirname "$flutter_bin")/dart" ]]; then
  dart_cmd=("$(dirname "$flutter_bin")/dart")
elif [[ "${flutter_cmd[0]}" == "fvm" ]]; then
  dart_cmd=(fvm dart)
elif [[ "${flutter_cmd[0]}" == "/Users/sylar/fvm/versions/stable/bin/flutter" ]]; then
  dart_cmd=("/Users/sylar/fvm/versions/stable/bin/dart")
else
  echo "dart executable not found" >&2
  exit 127
fi

"${flutter_cmd[@]}" pub get
"${dart_cmd[@]}" format --set-exit-if-changed .
"${flutter_cmd[@]}" analyze --fatal-infos --fatal-warnings
"${flutter_cmd[@]}" test --coverage
"${dart_cmd[@]}" pub publish --dry-run

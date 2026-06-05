#!/usr/bin/env bash
set -euo pipefail

# Avoid mutating generated files under example/ before publish validation.
flutter pub get --no-example
flutter analyze
flutter test
dart pub publish --dry-run

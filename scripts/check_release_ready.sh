#!/usr/bin/env bash
set -euo pipefail

pubspec_line="$(grep -E '^version:\s*' pubspec.yaml | head -n 1 || true)"
if [[ -z "$pubspec_line" ]]; then
  echo "pubspec.yaml version not found" >&2
  exit 1
fi
version="${pubspec_line#version:}"
version="${version//[[:space:]]/}"

podspec_line="$(grep -E "s\.version\s*=\s*'[^']+'" ios/pip.podspec | head -n 1 || true)"
if [[ -z "$podspec_line" ]]; then
  echo "ios/pip.podspec version not found" >&2
  exit 1
fi
podspec_version="$(printf '%s\n' "$podspec_line" | sed -E "s/.*'([^']+)'.*/\1/")"

if [[ "$version" != "$podspec_version" ]]; then
  echo "Version mismatch: pubspec.yaml has $version, ios/pip.podspec has $podspec_version" >&2
  exit 1
fi

if ! grep -Eq "^# $version$|^## $version$" CHANGELOG.md; then
  echo "CHANGELOG.md does not contain an entry for $version" >&2
  exit 1
fi

expected_version="${RELEASE_VERSION:-}"
if [[ -z "$expected_version" && "${GITHUB_REF:-}" == refs/tags/* ]]; then
  tag="${GITHUB_REF#refs/tags/}"
  expected_version="${tag#v}"
fi

if [[ -n "$expected_version" && "$expected_version" != "$version" ]]; then
  echo "Release version $expected_version does not match pubspec version $version" >&2
  exit 1
fi

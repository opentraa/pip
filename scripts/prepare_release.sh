#!/usr/bin/env bash
set -euo pipefail

version="${1:-}"

if [[ -z "$version" ]]; then
  echo "Usage: $0 <version>" >&2
  exit 64
fi

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Version must be in x.y.z format" >&2
  exit 64
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

pubspec="$repo_root/pubspec.yaml"
podspec="$repo_root/ios/pip.podspec"
readme="$repo_root/README.md"
changelog="$repo_root/CHANGELOG.md"
release_notes="$repo_root/.release-notes.md"

if [[ ! -f "$pubspec" || ! -f "$podspec" || ! -f "$release_notes" ]]; then
  echo "Expected pubspec.yaml, ios/pip.podspec, and .release-notes.md to exist" >&2
  exit 1
fi

perl -0pi -e "s/pip: \^[0-9]+\.[0-9]+\.[0-9]+/pip: ^$version/" "$readme"

if ! grep -Eq "^# $version$|^## $version$" "$changelog"; then
  tmp_file="$(mktemp)"
  {
    echo "# $version"
    echo
    cat "$release_notes"
    echo
    cat "$changelog"
  } > "$tmp_file"
  mv "$tmp_file" "$changelog"
fi

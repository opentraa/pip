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

if [[ ! -f "$pubspec" || ! -f "$podspec" ]]; then
  echo "Expected pubspec.yaml and ios/pip.podspec to exist" >&2
  exit 1
fi

perl -0pi -e "s/pip: \^[0-9]+\.[0-9]+\.[0-9]+/pip: ^$version/" "$readme"

if ! grep -Eq "^# $version$|^## $version$" "$changelog"; then
  tmp_file="$(mktemp)"
  {
    echo "# $version"
    echo
    echo "- TBD"
    echo
    cat "$changelog"
  } > "$tmp_file"
  mv "$tmp_file" "$changelog"
fi

#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

cp "$repo_root/pubspec.yaml" "$tmp_dir/pubspec.yaml"
mkdir -p "$tmp_dir/ios"
cp "$repo_root/ios/pip.podspec" "$tmp_dir/ios/pip.podspec"
cp "$repo_root/CHANGELOG.md" "$tmp_dir/CHANGELOG.md"
cp "$repo_root/scripts/check_release_ready.sh" "$tmp_dir/check_release_ready.sh"
chmod +x "$tmp_dir/check_release_ready.sh"

(
  cd "$tmp_dir"
  ./check_release_ready.sh
)

if (
  cd "$tmp_dir"
  RELEASE_VERSION="9.9.9" ./check_release_ready.sh >/dev/null 2>&1
); then
  echo "expected RELEASE_VERSION mismatch to fail" >&2
  exit 1
fi

echo "check_release_ready.sh tests passed"

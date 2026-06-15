#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

mkdir -p "$tmp_dir/ios" "$tmp_dir/scripts"
cp "$repo_root/pubspec.yaml" "$tmp_dir/pubspec.yaml"
cp "$repo_root/ios/pip.podspec" "$tmp_dir/ios/pip.podspec"
cp "$repo_root/README.md" "$tmp_dir/README.md"
cp "$repo_root/CHANGELOG.md" "$tmp_dir/CHANGELOG.md"
cp "$repo_root/scripts/prepare_release.sh" "$tmp_dir/scripts/prepare_release.sh"
chmod +x "$tmp_dir/scripts/prepare_release.sh"

(
  cd "$tmp_dir"
  ./scripts/prepare_release.sh 9.9.9
)

grep -q '^version: 0.0.3$' "$tmp_dir/pubspec.yaml"
grep -q "s.version          = '0.0.3'" "$tmp_dir/ios/pip.podspec"
grep -q 'pip: \^9.9.9' "$tmp_dir/README.md"
grep -q '^# 9.9.9$' "$tmp_dir/CHANGELOG.md"
grep -q '^- TBD$' "$tmp_dir/CHANGELOG.md"

before_changelog="$(cat "$tmp_dir/CHANGELOG.md")"
(
  cd "$tmp_dir"
  ./scripts/prepare_release.sh 9.9.9
)
after_changelog="$(cat "$tmp_dir/CHANGELOG.md")"

if [[ "$before_changelog" != "$after_changelog" ]]; then
  echo "prepare_release.sh should not duplicate changelog entries" >&2
  exit 1
fi

if (
  cd "$tmp_dir"
  ./scripts/prepare_release.sh invalid >/dev/null 2>&1
); then
  echo "expected invalid version to fail" >&2
  exit 1
fi

echo "prepare_release.sh tests passed"

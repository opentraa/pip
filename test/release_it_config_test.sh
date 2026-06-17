#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

grep -Fq '"after:bump": "./scripts/prepare_release.sh ${version}"' "$repo_root/.release-it.json"
grep -Fq '"before:git:release": "RELEASE_VERSION=${version} ./scripts/check_release_ready.sh"' "$repo_root/.release-it.json"
grep -Fq '"@release-it/bumper"' "$repo_root/.release-it.json"
grep -Fq '"file": "pubspec.yaml"' "$repo_root/.release-it.json"
grep -Fq '"file": "ios/pip.podspec"' "$repo_root/.release-it.json"
grep -Fq '"npm": false' "$repo_root/.release-it.json"
grep -Fq '"requireUpstream": false' "$repo_root/.release-it.json"
grep -Fq '"release": false' "$repo_root/.release-it.json"
grep -Fq '"releaseNotes": "cat .release-notes.md"' "$repo_root/.release-it.json"

echo "release-it config tests passed"

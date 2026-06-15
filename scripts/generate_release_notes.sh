#!/usr/bin/env bash
set -euo pipefail

version="${1:-}"
repo="${2:-${GITHUB_REPOSITORY:-}}"
target="${3:-${GITHUB_REF_NAME:-main}}"
output_file="${4:-release-notes.md}"

if [[ -z "$version" ]]; then
  echo "Usage: $0 <version> [repo] [target] [output_file]" >&2
  exit 64
fi

if [[ -z "$repo" ]]; then
  echo "GitHub repository is required" >&2
  exit 64
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI is required" >&2
  exit 127
fi

notes="$(
  gh api \
    -X POST \
    -H "Accept: application/vnd.github+json" \
    "/repos/${repo}/releases/generate-notes" \
    -f "tag_name=v${version}" \
    -f "target_commitish=${target}" \
    --jq '.body'
)"

summary=""
if [[ -n "${GITHUB_MODELS_TOKEN:-}" ]]; then
  prompt=$(
    cat <<EOF
Summarize the following GitHub release notes for a Flutter plugin release.
Return markdown only.
Keep it factual and concise.
Write:
- a title line: ## Summary
- 3 to 6 bullet points
- no invented information

Release notes:
${notes}
EOF
  )

  summary="$(
    gh api \
      -X POST \
      -H "Accept: application/vnd.github+json" \
      "/ai/models/openai/gpt-4.1-mini/inference" \
      -f "prompt=${prompt}" \
      --jq '.output[0].content[0].text' 2>/dev/null || true
  )"
fi

{
  if [[ -n "$summary" ]]; then
    printf '%s\n\n' "$summary"
  fi
  printf '%s\n' "$notes"
} > "$output_file"

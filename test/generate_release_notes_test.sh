#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

mkdir -p "$tmp_dir/scripts" "$tmp_dir/bin"
cp "$repo_root/scripts/generate_release_notes.sh" "$tmp_dir/scripts/generate_release_notes.sh"
chmod +x "$tmp_dir/scripts/generate_release_notes.sh"

cat > "$tmp_dir/bin/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "$*" == *"/releases/generate-notes"* ]]; then
  printf '%s' "## What's Changed"$'\n\n'"* Add isActive API by @user in #1"
  exit 0
fi

if [[ "$*" == *"/ai/models/openai/gpt-4.1-mini/inference"* ]]; then
  printf '%s' "## Summary"$'\n'"- Added isActive API"$'\n'"- Improved lifecycle handling"
  exit 0
fi

echo "unexpected gh invocation: $*" >&2
exit 1
EOF
chmod +x "$tmp_dir/bin/gh"

(
  cd "$tmp_dir"
  PATH="$tmp_dir/bin:$PATH" GITHUB_MODELS_TOKEN=dummy ./scripts/generate_release_notes.sh 0.0.4 opentraa/pip main notes.md
)

grep -Fq '## Summary' "$tmp_dir/notes.md"
grep -Fq -- '- Added isActive API' "$tmp_dir/notes.md"
grep -Fq "## What's Changed" "$tmp_dir/notes.md"

cat > "$tmp_dir/bin/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "$*" == *"/releases/generate-notes"* ]]; then
  printf '%s' "## What's Changed"$'\n\n'"* Add isActive API by @user in #1"
  exit 0
fi

echo "unexpected gh invocation: $*" >&2
exit 1
EOF
chmod +x "$tmp_dir/bin/gh"

(
  cd "$tmp_dir"
  PATH="$tmp_dir/bin:$PATH" ./scripts/generate_release_notes.sh 0.0.4 opentraa/pip main notes-fallback.md
)

grep -Fq "## What's Changed" "$tmp_dir/notes-fallback.md"
if grep -Fq '## Summary' "$tmp_dir/notes-fallback.md"; then
  echo "fallback notes should not contain AI summary" >&2
  exit 1
fi

echo "generate_release_notes.sh tests passed"

#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNNER="$ROOT/ops/claude_runner.sh"
PROMPT_FILE="$ROOT/skills/tl_dashboard.md"

DATE="$(date +%F)"
OUT_DIR="$ROOT/outputs/dashboards"
OUT_FILE="$OUT_DIR/TL_Dashboard_${DATE}.md"

mkdir -p "$OUT_DIR" "$ROOT/state"

if [[ ! -x "$RUNNER" ]]; then
  echo "Missing or non-executable runner: $RUNNER"
  echo "Do this:"
  echo "  cp ops/claude_runner.example.sh ops/claude_runner.sh"
  echo "  chmod +x ops/claude_runner.sh"
  echo "  # then edit ops/claude_runner.sh to call your Claude CLI"
  exit 1
fi

# Feed the skill prompt to your runner; capture stdout into the dashboard file.
# IMPORTANT: your runner should allow Claude to read repo files. How you do that depends on your CLI.
cat "$PROMPT_FILE" | "$RUNNER" > "$OUT_FILE"

echo "Wrote: $OUT_FILE"

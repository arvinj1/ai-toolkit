#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${HOME}/.bashrc"

echo "Installing TL-Ops startup hook into: $TARGET"
echo ""
echo "NOTE: This does NOT guess your Claude CLI."
echo "You must create ops/claude_runner.sh first."
echo ""

HOOK='
# TL-Ops Dashboard (manual by default)
# Run weekly dashboard with: ./ops/run_dashboard.sh
'

if ! grep -q "TL-Ops Dashboard" "$TARGET" 2>/dev/null; then
  printf "%s
" "$HOOK" >> "$TARGET"
  echo "Appended a small note to ~/.bashrc."
else
  echo "Hook note already present in ~/.bashrc (no changes)."
fi

echo "Done."

#!/usr/bin/env bash
# ops/serve.sh — TL-Ops dashboard viewer
# Serves the outputs/dashboards/ directory as a local web app.
# Open http://localhost:8765 in any browser.
#
# Usage:
#   ./ops/serve.sh            # default port 8765
#   ./ops/serve.sh --port 9000
#   ./ops/serve.sh --open     # auto-open browser

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VIEWER_DIR="$ROOT/ops/viewer"
OUT_DIR="$ROOT/outputs/dashboards"
PORT=8765
AUTO_OPEN=false

for arg in "$@"; do
  case "$arg" in
    --port)   shift; PORT="${1:-8765}" ;;
    --open)   AUTO_OPEN=true ;;
    --help|-h)
      echo "Usage: $0 [--port PORT] [--open]"
      echo "  --port PORT   Port to listen on (default: 8765)"
      echo "  --open        Auto-open browser"
      exit 0 ;;
  esac
done

# ─── Build a symlink so the viewer can serve dashboard files ──────────────────
mkdir -p "$VIEWER_DIR"
DASH_LINK="$VIEWER_DIR/dashboards"

if [[ ! -e "$DASH_LINK" ]]; then
  ln -s "$OUT_DIR" "$DASH_LINK"
fi

# ─── Ensure outputs/dashboards/ exists ───────────────────────────────────────
mkdir -p "$OUT_DIR"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  TL-Ops Dashboard Viewer"
echo "  http://localhost:${PORT}"
echo "  Ctrl+C to stop"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ─── Auto-open browser ────────────────────────────────────────────────────────
if [[ "$AUTO_OPEN" == "true" ]]; then
  (sleep 1 && {
    if command -v xdg-open >/dev/null 2>&1; then
      xdg-open "http://localhost:${PORT}"
    elif command -v open >/dev/null 2>&1; then
      open "http://localhost:${PORT}"
    fi
  }) &
fi

# ─── Start server ─────────────────────────────────────────────────────────────
# Try Python 3 first, then Python 2, then npx serve as fallback
if command -v python3 >/dev/null 2>&1; then
  cd "$VIEWER_DIR"
  exec python3 -m http.server "${PORT}"
elif command -v python >/dev/null 2>&1; then
  cd "$VIEWER_DIR"
  exec python -m SimpleHTTPServer "${PORT}"
elif command -v npx >/dev/null 2>&1; then
  exec npx --yes serve "$VIEWER_DIR" -l "${PORT}"
else
  echo "ERROR: No suitable server found."
  echo "Install one of: python3, python, node/npx"
  exit 1
fi

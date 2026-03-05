#!/usr/bin/env bash
set -euo pipefail

# Contract:
# - Reads the skill prompt from stdin
# - Prints Markdown to stdout
#
# This runner tries a few common Claude CLI patterns.
# If your local CLI differs, edit the first successful branch accordingly.

PROMPT="$(cat)"

# Optional: set model via env var if your CLI supports it
MODEL="${CLAUDE_MODEL:-}"

run_cmd () {
  # shellcheck disable=SC2086
  eval "$1"
}

# 1) Common: claude -p "<prompt>"
if command -v claude >/dev/null 2>&1; then
  if claude --help 2>/dev/null | grep -qE '(-p|--prompt)\b'; then
    if claude --help 2>/dev/null | grep -qE '\bmodel\b|--model\b'; then
      if [[ -n "$MODEL" ]]; then
        run_cmd "claude -p \"\$PROMPT\" --model \"\$MODEL\""
        exit 0
      fi
    fi
    run_cmd "claude -p \"\$PROMPT\""
    exit 0
  fi
fi

# 2) Common: claude --prompt "<prompt>"
if command -v claude >/dev/null 2>&1; then
  if claude --help 2>/dev/null | grep -qE '--prompt\b'; then
    if claude --help 2>/dev/null | grep -qE '\bmodel\b|--model\b' && [[ -n "$MODEL" ]]; then
      run_cmd "claude --prompt \"\$PROMPT\" --model \"\$MODEL\""
      exit 0
    fi
    run_cmd "claude --prompt \"\$PROMPT\""
    exit 0
  fi
fi

# 3) Stdin mode: echo "$PROMPT" | claude
# (Some CLIs just read stdin and respond to stdout)
if command -v claude >/dev/null 2>&1; then
  # Try a dry run by invoking with stdin. If it errors, we capture the error.
  if echo "$PROMPT" | claude >/dev/null 2>&1; then
    echo "$PROMPT" | claude
    exit 0
  fi
fi

# If we got here, we couldn't find a compatible invocation.
echo "ERROR: Could not determine how to call your 'claude' CLI." >&2
echo "" >&2
echo "Next steps:" >&2
echo "1) Run: claude --help" >&2
echo "2) Identify how to pass a prompt (e.g., -p/--prompt, or stdin)" >&2
echo "3) Edit ops/claude_runner.sh to match." >&2
echo "" >&2
echo "As a quick fix, replace this file with a one-liner that works for you, e.g.:" >&2
echo "  cat | claude" >&2
echo "  # OR" >&2
echo "  xargs -0 -I{} claude -p \"{}\"" >&2
exit 1
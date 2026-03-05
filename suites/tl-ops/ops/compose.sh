#!/usr/bin/env bash
# ops/compose.sh — TL-Team-Composer runner
# Reads inputs/team/*.md and runs the tl-team-composer skill.
# Saves output to outputs/team-composer/TeamComposition_YYYY-MM-DD.md
#
# Usage:
#   ./ops/compose.sh                   # run with default Claude runner
#   ./ops/compose.sh --runner openai   # use ops/runners/openai_runner.sh
#   ./ops/compose.sh --runner gemini   # use ops/runners/gemini_runner.sh
#   ./ops/compose.sh --dry-run         # print prompt, don't call LLM
#
# See ops/RUNNERS.md for setting up alternative LLM runners.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TODAY="$(date +%F)"
SKILL_FILE="$ROOT/skills/tl-team-composer/SKILL.md"
OUTPUT_DIR="$ROOT/outputs/team-composer"
OUTPUT_FILE="$OUTPUT_DIR/TeamComposition_${TODAY}.md"

RUNNER="claude"   # default: use ops/claude_runner.sh
DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    --runner) shift; RUNNER="${1:-claude}" ;;
    --dry-run) DRY_RUN=true ;;
    --help|-h)
      echo "Usage: $0 [--runner claude|openai|gemini|ollama] [--dry-run]"
      echo "See ops/RUNNERS.md for runner setup."
      exit 0 ;;
  esac
done

# ─── Resolve runner script ────────────────────────────────────────────────────
case "$RUNNER" in
  claude)  RUNNER_SCRIPT="$ROOT/ops/claude_runner.sh" ;;
  openai)  RUNNER_SCRIPT="$ROOT/ops/runners/openai_runner.sh" ;;
  gemini)  RUNNER_SCRIPT="$ROOT/ops/runners/gemini_runner.sh" ;;
  ollama)  RUNNER_SCRIPT="$ROOT/ops/runners/ollama_runner.sh" ;;
  *)       RUNNER_SCRIPT="$ROOT/ops/runners/${RUNNER}_runner.sh" ;;
esac

if [[ ! -f "$SKILL_FILE" ]]; then
  echo "ERROR: Skill not found: $SKILL_FILE" >&2
  exit 1
fi

# ─── Build prompt ─────────────────────────────────────────────────────────────
# Concatenate skill + all input files into a single prompt
build_prompt() {
  cat "$SKILL_FILE"
  echo ""
  echo "---"
  echo "## Input files (read before generating output)"
  echo ""

  local input_files=(
    "$ROOT/inputs/team/composition.md"
    "$ROOT/inputs/team/workload_profile.md"
    "$ROOT/inputs/team/agent_inventory.md"
    "$ROOT/inputs/team/hiring_pipeline.md"
    "$ROOT/inputs/team/capacity_constraints.md"
    "$ROOT/inputs/team/token_costs.md"
    "$ROOT/inputs/status_weekly.md"
    "$ROOT/inputs/risks.md"
  )

  for f in "${input_files[@]}"; do
    if [[ -f "$f" ]]; then
      local rel="${f#$ROOT/}"
      echo "### File: $rel"
      echo '```'
      cat "$f"
      echo '```'
      echo ""
    fi
  done

  # Include people profiles
  if ls "$ROOT/inputs/people/"*.md 2>/dev/null | grep -v "_template.md" >/dev/null 2>&1; then
    echo "### Team member profiles (inputs/people/)"
    for pf in "$ROOT/inputs/people/"*.md; do
      [[ "$(basename "$pf")" == "_template.md" ]] && continue
      echo "#### $(basename "$pf")"
      echo '```'
      cat "$pf"
      echo '```'
      echo ""
    done
  fi

  # Include recent prior outputs for delta analysis (latest 2)
  if ls "$ROOT/outputs/team-composer/"*.md 2>/dev/null | head -2 >/dev/null 2>&1; then
    echo "### Prior team composition outputs (for delta analysis)"
    for of in $(ls -t "$ROOT/outputs/team-composer/"*.md 2>/dev/null | head -2); do
      echo "#### $(basename "$of")"
      echo '```'
      cat "$of"
      echo '```'
      echo ""
    done
  fi

  echo "---"
  echo "Today's date: ${TODAY}"
  echo "Generate the Team Composition Review now."
}

# ─── Dry run ──────────────────────────────────────────────────────────────────
if [[ "$DRY_RUN" == "true" ]]; then
  echo "=== DRY RUN — prompt that would be sent to LLM ==="
  build_prompt
  echo "=== END DRY RUN ==="
  exit 0
fi

# ─── Check runner ─────────────────────────────────────────────────────────────
if [[ ! -f "$RUNNER_SCRIPT" ]]; then
  echo "ERROR: Runner not found: $RUNNER_SCRIPT" >&2
  echo "For Claude: cp ops/claude_runner.example.sh ops/claude_runner.sh" >&2
  echo "For other LLMs: see ops/RUNNERS.md" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

# ─── Run ──────────────────────────────────────────────────────────────────────
echo "Running tl-team-composer with runner: ${RUNNER}"
echo "Output → ${OUTPUT_FILE}"
echo ""

build_prompt | bash "$RUNNER_SCRIPT" > "$OUTPUT_FILE"

# Strip the <!-- save to --> comment from the file if the LLM included it
if [[ -f "$OUTPUT_FILE" ]]; then
  # macOS + Linux compatible sed
  sed -i.bak '/^<!-- save to:.*-->$/d' "$OUTPUT_FILE" 2>/dev/null && rm -f "${OUTPUT_FILE}.bak" || true
fi

echo "Done. Open with:"
echo "  ./ops/serve.sh --open"
echo "  # then navigate to team-composer outputs in the viewer"

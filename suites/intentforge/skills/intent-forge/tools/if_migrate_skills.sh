#!/usr/bin/env bash
set -euo pipefail

# -------------------------------------------------------------------
# IntentForge Skill Migrator + Verifier
# - Converts artifact paths to repo-local: .intent-forge/artifacts/...
# - Optionally ensures user-invocable header exists
# - Verifies YAML frontmatter + expected structure
#
# Usage:
#   ./if_migrate_skills.sh --root "$HOME/.claude/skills" --apply
#   ./if_migrate_skills.sh --root "$HOME/.claude/skills" --apply --ensure-user-invocable
#   ./if_migrate_skills.sh --root "$HOME/.claude/skills" --check
#
# -------------------------------------------------------------------

ROOT=""
MODE="check"  # check|apply
ENSURE_USER_INVOCABLE="false"

log()  { printf "▶ %s\n" "$*"; }
warn() { printf "⚠ %s\n" "$*" >&2; }
err()  { printf "✖ %s\n" "$*" >&2; exit 1; }

usage() {
  cat <<EOF
IntentForge Skill Migrator + Verifier

Flags:
  --root <path>               Root folder containing skills (e.g. ~/.claude/skills)
  --apply                     Apply changes (default is --check)
  --check                     Only verify, no changes
  --ensure-user-invocable     If missing, add 'user-invocable: true' to frontmatter
  -h|--help                   Show help

Examples:
  ./if_migrate_skills.sh --root "\$HOME/.claude/skills" --check
  ./if_migrate_skills.sh --root "\$HOME/.claude/skills" --apply --ensure-user-invocable
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root) ROOT="${2:-}"; shift 2 ;;
    --apply) MODE="apply"; shift ;;
    --check) MODE="check"; shift ;;
    --ensure-user-invocable) ENSURE_USER_INVOCABLE="true"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) err "Unknown arg: $1" ;;
  esac
done

[[ -n "$ROOT" ]] || err "Missing --root <path>"
[[ -d "$ROOT" ]] || err "Root not found: $ROOT"

# Skills we manage
SKILLS=(
  "intent-forge/SKILL.md"
  "intent-forge-planner/SKILL.md"
  "intent-forge-jira/SKILL.md"
  "intent-forge-implementer/SKILL.md"
  "intent-forge-tester/SKILL.md"
)

# Convert artifacts paths from:
#   artifacts/010_planning/foo
# to:
#   .intent-forge/artifacts/010_planning/foo
#
# We do NOT touch:
#   ~/.claude/skills/intent-forge/artifacts/... (you should not keep those long-term)
#
rewrite_paths() {
  local f="$1"
  # Only rewrite paths that look like stage artifacts references.
  # We keep it conservative to avoid surprising edits.
  perl -0777 -pe '
    s{(?<![.\w/-])artifacts/(000_intake|010_planning|020_jira|030_implementation|040_testing|900_state)/}{.intent-forge/artifacts/$1/}g;
  ' "$f" > "${f}.tmp"
  mv "${f}.tmp" "$f"
}

# Ensure YAML frontmatter has user-invocable: true
ensure_user_invocable() {
  local f="$1"
  # If no frontmatter, fail (skills require it)
  head -n 1 "$f" | grep -q '^---$' || err "No YAML frontmatter start '---' in $f"

  # Extract the first frontmatter block and check if it already has user-invocable
  local fm
  fm="$(awk 'NR==1{in=1} in{print} /^---$/ && NR>1{exit}' "$f")"
  if echo "$fm" | grep -q '^user-invocable:'; then
    return 0
  fi

  # Insert user-invocable: true after description: line if present, else after name:
  awk '
    BEGIN{done=0; in=0}
    NR==1 && $0=="---" {in=1; print; next}
    in==1 && done==0 && $0 ~ /^description:/ {
      print
      print "user-invocable: true"
      done=1
      next
    }
    in==1 && done==0 && $0 ~ /^name:/ {
      print
      next
    }
    in==1 && done==0 && $0 ~ /^---$/ {
      # If we reach end of frontmatter without inserting, insert before closing ---
      print "user-invocable: true"
      done=1
      print
      in=0
      next
    }
    {print}
  ' "$f" > "${f}.tmp"
  mv "${f}.tmp" "$f"
}

# Verify: exactly one top-level YAML frontmatter block
verify_frontmatter() {
  local f="$1"

  # Must start with ---
  head -n 1 "$f" | grep -q '^---$' || { warn "$f: missing frontmatter start"; return 1; }

  # Count '---' lines at start:
  # We require: first block closed by second --- line, before any other text.
  local count
  count="$(awk 'NR<=80 && $0=="---"{c++} END{print c+0}' "$f")"
  [[ "$count" -ge 2 ]] || { warn "$f: frontmatter not closed"; return 1; }

  # Ensure no second frontmatter starts later (common copy/paste mistake)
  # heuristic: look for "\n---\nname:" after first ~200 lines
  if perl -0777 -ne 'exit( (s/\A---.*?---//s, $_= $_, /(^|\n)---\nname:/m) ? 1 : 0 )' "$f"; then
    warn "$f: looks like a second frontmatter block exists later"
    return 1
  fi

  return 0
}

# Verify: artifact path references are repo-local
verify_paths() {
  local f="$1"

  # Disallow raw "artifacts/010_planning" etc (should be .intent-forge/artifacts/...)
  if grep -Eqs '(^|[^.\w/-])artifacts/(000_intake|010_planning|020_jira|030_implementation|040_testing|900_state)/' "$f"; then
    warn "$f: found non-portable artifact path 'artifacts/...'"
    return 1
  fi

  # Encourage presence of .intent-forge/artifacts paths (not mandatory in the orchestrator skill)
  # We keep it soft: only warn.
  if ! grep -qs '\.intent-forge/artifacts/' "$f"; then
    warn "$f: no .intent-forge/artifacts references found (might be ok for orchestrator)"
  fi

  return 0
}

# Verify: has name + description keys in frontmatter
verify_required_keys() {
  local f="$1"
  local fm
  fm="$(awk 'NR==1{in=1} in{print} /^---$/ && NR>1{exit}' "$f")"
  echo "$fm" | grep -q '^name:' || { warn "$f: frontmatter missing name:"; return 1; }
  echo "$fm" | grep -q '^description:' || { warn "$f: frontmatter missing description:"; return 1; }
  return 0
}

# Main
fail=0
changed=0

log "Root: $ROOT"
log "Mode: $MODE"
log "Ensure user-invocable: $ENSURE_USER_INVOCABLE"
echo

for rel in "${SKILLS[@]}"; do
  f="$ROOT/$rel"
  [[ -f "$f" ]] || { warn "Missing: $f"; fail=1; continue; }

  log "Skill: $rel"

  if [[ "$MODE" == "apply" ]]; then
    # Rewrite paths first
    before_hash="$(shasum -a 256 "$f" | awk "{print \$1}")"
    rewrite_paths "$f"
    if [[ "$ENSURE_USER_INVOCABLE" == "true" ]]; then
      ensure_user_invocable "$f"
    fi
    after_hash="$(shasum -a 256 "$f" | awk "{print \$1}")"
    if [[ "$before_hash" != "$after_hash" ]]; then
      changed=$((changed+1))
      log "  ✅ updated: $rel"
    else
      log "  (no change)"
    fi
  fi

  # Verify always
  verify_frontmatter "$f" || fail=1
  verify_required_keys "$f" || fail=1
  verify_paths "$f" || fail=1

  echo
done

if [[ "$MODE" == "apply" ]]; then
  log "Changed files: $changed"
fi

if [[ "$fail" -ne 0 ]]; then
  err "Verification FAILED. Fix warnings above (or paste them here and I’ll tell you exactly what to change)."
else
  log "Verification OK ✅"
fi
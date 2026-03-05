#!/usr/bin/env bash
# ops/collect.sh — TL-Ops input collector
# Pulls signal from Jira, GitHub, Linear, PagerDuty, OpsGenie, Slack, and Calendar
# and writes it into the inputs/ Markdown files ready for the dashboard.
#
# Usage:
#   ./ops/collect.sh --all
#   ./ops/collect.sh --jira --github
#   ./ops/collect.sh --calendar --slack
#   ./ops/collect.sh --help
#
# Prerequisites: jq (required), gh CLI (GitHub), gcalcli (Calendar/gcalcli method)
# Config:   ops/collect.config (copy from ops/collect.config and fill in)

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="$ROOT/ops/collect.config"
INPUTS="$ROOT/inputs"
TODAY="$(date +%F)"
NOW_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# ─── Colour helpers ───────────────────────────────────────────────────────────
RED='\033[0;31m'; YELLOW='\033[0;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()  { echo -e "${CYAN}[collect]${RESET} $*"; }
ok()    { echo -e "${GREEN}[collect]${RESET} ✓ $*"; }
warn()  { echo -e "${YELLOW}[collect]${RESET} ⚠ $*"; }
err()   { echo -e "${RED}[collect]${RESET} ✗ $*" >&2; }
header(){ echo -e "\n${BOLD}${CYAN}── $* ──${RESET}"; }

# ─── Argument parsing ─────────────────────────────────────────────────────────
DO_JIRA=false
DO_GITHUB=false
DO_LINEAR=false
DO_PAGERDUTY=false
DO_OPSGENIE=false
DO_SLACK=false
DO_CALENDAR=false
DRY_RUN=false

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 [--all] [--jira] [--github] [--linear] [--pagerduty] [--opsgenie] [--slack] [--calendar] [--dry-run]"
  echo "       $0 --help"
  exit 1
fi

for arg in "$@"; do
  case "$arg" in
    --all)        DO_JIRA=true; DO_GITHUB=true; DO_LINEAR=true
                  DO_PAGERDUTY=true; DO_OPSGENIE=true; DO_SLACK=true; DO_CALENDAR=true ;;
    --jira)       DO_JIRA=true ;;
    --github)     DO_GITHUB=true ;;
    --linear)     DO_LINEAR=true ;;
    --pagerduty)  DO_PAGERDUTY=true ;;
    --opsgenie)   DO_OPSGENIE=true ;;
    --slack)      DO_SLACK=true ;;
    --calendar)   DO_CALENDAR=true ;;
    --dry-run)    DRY_RUN=true ;;
    --help|-h)
      cat <<'EOF'
ops/collect.sh — TL-Ops input collector

Flags:
  --all          Run all enabled collectors (anything configured in collect.config)
  --jira         Pull active sprint from Jira → inputs/jira_snapshot.md
  --github       Pull issues/PRs from GitHub → inputs/status_weekly.md, inputs/todo.md
  --linear       Pull active cycle from Linear → inputs/jira_snapshot.md
  --pagerduty    Pull recent incidents from PagerDuty → inputs/signals/incidents.md
  --opsgenie     Pull open alerts from OpsGenie → inputs/signals/incidents.md
  --slack        Scan channels for signals → inputs/signals/incidents.md + others
  --calendar     Pull today's meetings → inputs/todo.md
  --dry-run      Print what would be written; do not modify any files
  --help         Show this help

Config: ops/collect.config (fill in credentials before first run)

Typical workflow:
  ./ops/collect.sh --all && ./ops/run_dashboard.sh
EOF
      exit 0 ;;
    *) err "Unknown argument: $arg"; exit 1 ;;
  esac
done

# ─── Load config ─────────────────────────────────────────────────────────────
if [[ ! -f "$CONFIG_FILE" ]]; then
  err "Config not found: $CONFIG_FILE"
  err "Create it first: cp ops/collect.config ops/collect.config  (already exists — just fill in values)"
  exit 1
fi
# shellcheck source=/dev/null
source "$CONFIG_FILE"

# ─── Dependency check ─────────────────────────────────────────────────────────
require() {
  if ! command -v "$1" >/dev/null 2>&1; then
    warn "Missing dependency: $1 ($2). Skipping related collector."
    return 1
  fi
  return 0
}

# ─── Write helpers ────────────────────────────────────────────────────────────
write_file() {
  local file="$1" content="$2"
  if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${YELLOW}[dry-run] Would write to: ${file}${RESET}"
    echo "$content"
    echo "---"
  else
    mkdir -p "$(dirname "$file")"
    printf '%s\n' "$content" > "$file"
  fi
}

append_file() {
  local file="$1" content="$2"
  if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${YELLOW}[dry-run] Would append to: ${file}${RESET}"
    echo "$content"
    echo "---"
  else
    mkdir -p "$(dirname "$file")"
    printf '%s\n' "$content" >> "$file"
  fi
}

# Ensure a section header exists in a file; if not, append it
ensure_section() {
  local file="$1" heading="$2"
  if [[ "$DRY_RUN" == "true" ]]; then return; fi
  if [[ ! -f "$file" ]] || ! grep -qF "$heading" "$file" 2>/dev/null; then
    printf '\n%s\n' "$heading" >> "$file"
  fi
}

# ─── Deduplication helper ─────────────────────────────────────────────────────
# Append a line only if it doesn't already exist in the file
append_unique() {
  local file="$1" line="$2"
  if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${YELLOW}[dry-run] append-unique to ${file}:${RESET} $line"
    return
  fi
  if [[ ! -f "$file" ]] || ! grep -qF "$line" "$file" 2>/dev/null; then
    echo "$line" >> "$file"
  fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# JIRA
# ═══════════════════════════════════════════════════════════════════════════════
collect_jira() {
  header "Jira"

  if [[ -z "${JIRA_DOMAIN:-}" || -z "${JIRA_TOKEN:-}" || -z "${JIRA_EMAIL:-}" || -z "${JIRA_PROJECT:-}" ]]; then
    warn "Jira not configured (JIRA_DOMAIN, JIRA_TOKEN, JIRA_EMAIL, JIRA_PROJECT). Skipping."
    return
  fi
  if ! require jq "https://stedolan.github.io/jq/download/"; then return; fi

  local base_url="https://${JIRA_DOMAIN}/rest/api/3"
  local auth
  auth="$(echo -n "${JIRA_EMAIL}:${JIRA_TOKEN}" | base64)"

  info "Fetching active sprint for project: ${JIRA_PROJECT}"

  # Get active sprint
  local boards_resp
  boards_resp="$(curl -sf \
    -H "Authorization: Basic ${auth}" \
    -H "Accept: application/json" \
    "${base_url}/board?projectKeyOrId=${JIRA_PROJECT}&type=scrum" 2>/dev/null || echo '{}')"

  local board_id
  board_id="$(echo "$boards_resp" | jq -r '.values[0].id // empty')"

  local sprint_name="Unknown Sprint"
  local sprint_start="" sprint_end=""

  if [[ -n "$board_id" ]]; then
    local sprint_resp
    sprint_resp="$(curl -sf \
      -H "Authorization: Basic ${auth}" \
      -H "Accept: application/json" \
      "https://${JIRA_DOMAIN}/rest/agile/1.0/board/${board_id}/sprint?state=active" 2>/dev/null || echo '{}')"
    sprint_name="$(echo "$sprint_resp" | jq -r '.values[0].name // "Unknown Sprint"')"
    sprint_start="$(echo "$sprint_resp" | jq -r '.values[0].startDate // "" | .[:10]')"
    sprint_end="$(echo "$sprint_resp" | jq -r '.values[0].endDate // "" | .[:10]')"
  fi

  # Get issues in active sprint
  local issues_resp
  issues_resp="$(curl -sf \
    -H "Authorization: Basic ${auth}" \
    -H "Accept: application/json" \
    "${base_url}/search?jql=project=${JIRA_PROJECT}+AND+sprint+in+openSprints()&fields=summary,status,assignee,story_points,priority,labels&maxResults=50" \
    2>/dev/null || echo '{"issues":[]}')"

  local total done_count
  total="$(echo "$issues_resp" | jq '.issues | length')"
  done_count="$(echo "$issues_resp" | jq '[.issues[] | select(.fields.status.name == "Done")] | length')"

  # Build snapshot markdown
  local out
  out="# Jira snapshot (${TODAY})

## Sprint: ${sprint_name} (${sprint_start} – ${sprint_end})
- Total issues: ${total}
- Completed: ${done_count}
- Remaining: $((total - done_count))

## Done this sprint"
  out+="$(echo "$issues_resp" | jq -r '
    .issues[]
    | select(.fields.status.name == "Done")
    | "- \(.key): \(.fields.summary) — Done — \(.fields.assignee.displayName // "Unassigned")"
  ' 2>/dev/null || true)"

  out+="

## In Progress"
  out+="$(echo "$issues_resp" | jq -r '
    .issues[]
    | select(.fields.status.name | test("In Progress|In Review|Review"; "i"))
    | "- \(.key): \(.fields.summary) — \(.fields.status.name) — \(.fields.assignee.displayName // "Unassigned")"
  ' 2>/dev/null || true)"

  out+="

## Blocked / To Do"
  out+="$(echo "$issues_resp" | jq -r '
    .issues[]
    | select(.fields.status.name | test("Blocked|To Do|Backlog"; "i"))
    | "- \(.key): \(.fields.summary) — \(.fields.status.name) — \(.fields.assignee.displayName // "Unassigned")"
  ' 2>/dev/null || true)"

  if [[ "${JIRA_OVERWRITE:-true}" == "true" ]]; then
    write_file "${INPUTS}/jira_snapshot.md" "$out"
  else
    append_file "${INPUTS}/jira_snapshot.md" "$out"
  fi

  ok "Jira snapshot written to inputs/jira_snapshot.md (${done_count}/${total} done)"
}

# ═══════════════════════════════════════════════════════════════════════════════
# GITHUB
# ═══════════════════════════════════════════════════════════════════════════════
collect_github() {
  header "GitHub"

  if [[ -z "${GITHUB_REPO:-}" ]]; then
    warn "GITHUB_REPO not configured. Skipping."
    return
  fi
  if ! require gh "https://cli.github.com"; then return; fi
  if ! require jq "https://stedolan.github.io/jq/download/"; then return; fi

  local lookback="${GITHUB_LOOKBACK_DAYS:-7}"
  local since
  since="$(date -d "${lookback} days ago" +%Y-%m-%d 2>/dev/null \
    || date -v-"${lookback}"d +%Y-%m-%d 2>/dev/null \
    || echo "$(date +%Y-%m-%d)")"

  info "GitHub repo: ${GITHUB_REPO} | lookback: ${lookback} days (since ${since})"

  # ── Outcomes: closed issues this week ──
  local closed_issues
  closed_issues="$(gh issue list \
    --repo "${GITHUB_REPO}" \
    --state closed \
    --json number,title,closedAt,labels \
    --limit 50 2>/dev/null \
    | jq -r --arg since "${since}" '
        .[]
        | select(.closedAt[:10] >= $since)
        | "- #\(.number) \(.title)"
      ' || true)"

  # ── Outcomes: merged PRs this week ──
  local merged_prs
  merged_prs="$(gh pr list \
    --repo "${GITHUB_REPO}" \
    --state merged \
    --json number,title,mergedAt,author \
    --limit 50 2>/dev/null \
    | jq -r --arg since "${since}" '
        .[]
        | select(.mergedAt[:10] >= $since)
        | "- PR #\(.number) \(.title) — @\(.author.login)"
      ' || true)"

  # ── In progress: open PRs ──
  local open_prs
  open_prs="$(gh pr list \
    --repo "${GITHUB_REPO}" \
    --state open \
    --json number,title,createdAt,author,reviewRequests \
    --limit 30 2>/dev/null \
    | jq -r '
        .[]
        | "- PR #\(.number) \(.title) — @\(.author.login) (open since \(.createdAt[:10]))"
      ' || true)"

  # ── Risks: stale PRs (open > 5 days) ──
  local stale_cutoff
  stale_cutoff="$(date -d "5 days ago" +%Y-%m-%d 2>/dev/null \
    || date -v-5d +%Y-%m-%d 2>/dev/null \
    || echo "$since")"

  local stale_prs
  stale_prs="$(gh pr list \
    --repo "${GITHUB_REPO}" \
    --state open \
    --json number,title,createdAt,author \
    --limit 30 2>/dev/null \
    | jq -r --arg cutoff "${stale_cutoff}" '
        .[]
        | select(.createdAt[:10] <= $cutoff)
        | "- PR #\(.number) \(.title) — open since \(.createdAt[:10]) — STALE"
      ' || true)"

  # ── PRs needing review (for today's todo) ──
  local review_requests
  review_requests="$(gh pr list \
    --repo "${GITHUB_REPO}" \
    --state open \
    --json number,title,createdAt \
    --search "review-requested:@me" \
    --limit 10 2>/dev/null \
    | jq -r '
        .[]
        | "- Review PR #\(.number): \(.title)"
      ' || true)"

  # ── Write to status_weekly.md ──
  local weekly_file="${INPUTS}/status_weekly.md"
  ensure_section "$weekly_file" "## Outcomes shipped (value/outcomes, not effort)"

  if [[ -n "$closed_issues" || -n "$merged_prs" ]]; then
    local outcomes_block="
<!-- GitHub: closed issues + merged PRs since ${since} -->
${closed_issues}
${merged_prs}"
    append_file "$weekly_file" "$outcomes_block"
    ok "Appended GitHub outcomes to inputs/status_weekly.md"
  else
    info "No closed issues or merged PRs since ${since}"
  fi

  if [[ -n "$open_prs" ]]; then
    ensure_section "$weekly_file" "## In progress (with ETA)"
    append_file "$weekly_file" "
<!-- GitHub: open PRs -->
${open_prs}"
    ok "Appended open PRs to inputs/status_weekly.md"
  fi

  if [[ -n "$stale_prs" ]]; then
    ensure_section "$weekly_file" "## Risks / issues (include owner + mitigation if known)"
    append_file "$weekly_file" "
<!-- GitHub: stale PRs >5 days -->
${stale_prs}"
    ok "Appended stale PRs to inputs/status_weekly.md"
  fi

  # ── Write review requests to todo.md ──
  if [[ -n "$review_requests" ]]; then
    local todo_file="${INPUTS}/todo.md"
    if [[ ! -f "$todo_file" ]]; then
      write_file "$todo_file" "# Today (${TODAY})

## Outcomes (what \"done\" looks like)
-

## Tasks (optional)
-

## Meetings / time constraints
-

## Constraints / blockers
-"
    fi
    ensure_section "$todo_file" "## Tasks (optional)"
    append_file "$todo_file" "
<!-- GitHub: PRs needing your review -->
${review_requests}"
    ok "Appended review requests to inputs/todo.md"
  fi

  # ── Incidents: issues tagged incident or production-bug ──
  local incident_issues
  incident_issues="$(gh issue list \
    --repo "${GITHUB_REPO}" \
    --state open \
    --label "incident,production-bug" \
    --json number,title,createdAt,labels \
    --limit 20 2>/dev/null \
    | jq -r '
        .[]
        | "- What happened: #\(.number) \(.title)\n  Status: Open\n  Owner: (see issue)\n  Follow-up: \(.createdAt[:10])\n"
      ' || true)"

  if [[ -n "$incident_issues" ]]; then
    local inc_file="${INPUTS}/signals/incidents.md"
    if [[ ! -f "$inc_file" ]]; then
      write_file "$inc_file" "# Incidents / operational signals (append-only)"
    fi
    append_unique "$inc_file" "
${TODAY}
<!-- GitHub: open incident/production-bug issues -->
${incident_issues}"
    ok "Appended GitHub incident issues to inputs/signals/incidents.md"
  fi

  # ── GitHub Projects (optional) ──
  if [[ -n "${GITHUB_PROJECT_NUMBER:-}" && -n "${GITHUB_PROJECT_OWNER:-}" ]]; then
    info "Fetching GitHub Project #${GITHUB_PROJECT_NUMBER}"
    local project_items
    project_items="$(gh project item-list "${GITHUB_PROJECT_NUMBER}" \
      --owner "${GITHUB_PROJECT_OWNER}" \
      --format json \
      --limit 50 2>/dev/null \
      | jq -r '.items[] | "- \(.title) — \(.status // "No status")"' || true)"

    if [[ -n "$project_items" ]]; then
      local snap_file="${INPUTS}/jira_snapshot.md"
      append_file "$snap_file" "
## GitHub Project #${GITHUB_PROJECT_NUMBER} (${TODAY})
${project_items}"
      ok "Appended GitHub Project items to inputs/jira_snapshot.md"
    fi
  fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# LINEAR
# ═══════════════════════════════════════════════════════════════════════════════
collect_linear() {
  header "Linear"

  if [[ -z "${LINEAR_API_KEY:-}" || -z "${LINEAR_TEAM_ID:-}" ]]; then
    warn "Linear not configured (LINEAR_API_KEY, LINEAR_TEAM_ID). Skipping."
    return
  fi
  if ! require jq "https://stedolan.github.io/jq/download/"; then return; fi
  if ! require curl "system package manager"; then return; fi

  info "Fetching active cycle for team: ${LINEAR_TEAM_ID}"

  local resp
  resp="$(curl -sf \
    -H "Authorization: ${LINEAR_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "{\"query\": \"{ issues(filter: { team: { id: { eq: \\\"${LINEAR_TEAM_ID}\\\" } }, cycle: { isActive: { eq: true } } }) { nodes { title state { name } assignee { name } estimate priority } } }\"}" \
    https://api.linear.app/graphql 2>/dev/null || echo '{}')"

  local issues_md
  issues_md="$(echo "$resp" | jq -r '
    .data.issues.nodes[]?
    | "- \(.title) — \(.state.name) — \(.assignee.name // "Unassigned")"
  ' || true)"

  if [[ -z "$issues_md" ]]; then
    warn "No Linear issues returned (check LINEAR_TEAM_ID and API key)."
    return
  fi

  local done_items in_progress_items other_items
  done_items="$(echo "$resp" | jq -r '
    .data.issues.nodes[]?
    | select(.state.name == "Done" or .state.name == "Completed")
    | "- \(.title) — \(.assignee.name // "Unassigned")"
  ' || true)"

  in_progress_items="$(echo "$resp" | jq -r '
    .data.issues.nodes[]?
    | select(.state.name | test("In Progress|In Review"; "i"))
    | "- \(.title) — \(.state.name) — \(.assignee.name // "Unassigned")"
  ' || true)"

  other_items="$(echo "$resp" | jq -r '
    .data.issues.nodes[]?
    | select(.state.name | test("Done|Completed|In Progress|In Review"; "i") | not)
    | "- \(.title) — \(.state.name) — \(.assignee.name // "Unassigned")"
  ' || true)"

  local linear_snap="
## Linear active cycle snapshot (${TODAY})

### Done / Completed
${done_items:-  (none)}

### In Progress / In Review
${in_progress_items:-  (none)}

### Todo / Backlog / Other
${other_items:-  (none)}"

  local snap_file="${INPUTS}/jira_snapshot.md"
  if [[ ! -f "$snap_file" ]]; then
    write_file "$snap_file" "# Sprint / Cycle snapshot (${TODAY})${linear_snap}"
  else
    append_file "$snap_file" "$linear_snap"
  fi

  ok "Linear cycle snapshot written to inputs/jira_snapshot.md"
}

# ═══════════════════════════════════════════════════════════════════════════════
# PAGERDUTY
# ═══════════════════════════════════════════════════════════════════════════════
collect_pagerduty() {
  header "PagerDuty"

  if [[ -z "${PAGERDUTY_TOKEN:-}" ]]; then
    warn "PAGERDUTY_TOKEN not configured. Skipping."
    return
  fi
  if ! require jq "https://stedolan.github.io/jq/download/"; then return; fi
  if ! require curl "system package manager"; then return; fi

  local days="${PAGERDUTY_LOOKBACK_DAYS:-7}"
  local since
  since="$(date -d "${days} days ago" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
    || date -v-"${days}"d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
    || echo "${NOW_UTC}")"

  info "Fetching PagerDuty incidents (last ${days} days)"

  local resp
  resp="$(curl -sf \
    -H "Authorization: Token token=${PAGERDUTY_TOKEN}" \
    -H "Accept: application/vnd.pagerduty+json;version=2" \
    "https://api.pagerduty.com/incidents?statuses[]=triggered&statuses[]=acknowledged&statuses[]=resolved&since=${since}&limit=25" \
    2>/dev/null || echo '{"incidents":[]}')"

  local count
  count="$(echo "$resp" | jq '.incidents | length')"

  if [[ "$count" -eq 0 ]]; then
    ok "No PagerDuty incidents in the last ${days} days."
    return
  fi

  local inc_file="${INPUTS}/signals/incidents.md"
  if [[ ! -f "$inc_file" ]]; then
    write_file "$inc_file" "# Incidents / operational signals (append-only)"
  fi

  local entries
  entries="$(echo "$resp" | jq -r '
    .incidents[]
    | "## \(.created_at[:10]) — \(.title)\n- Status: \(.status)\n- Urgency: \(.urgency)\n- Service: \(.service.summary // "unknown")\n- Owner: \(.assignments[0].assignee.summary // "Unassigned")\n- Follow-up: TBD\n"
  ' || true)"

  append_file "$inc_file" "
<!-- PagerDuty pull: ${TODAY} -->
${entries}"

  ok "PagerDuty: ${count} incident(s) written to inputs/signals/incidents.md"
}

# ═══════════════════════════════════════════════════════════════════════════════
# OPSGENIE
# ═══════════════════════════════════════════════════════════════════════════════
collect_opsgenie() {
  header "OpsGenie"

  if [[ -z "${OPSGENIE_API_KEY:-}" ]]; then
    warn "OPSGENIE_API_KEY not configured. Skipping."
    return
  fi
  if ! require jq "https://stedolan.github.io/jq/download/"; then return; fi
  if ! require curl "system package manager"; then return; fi

  info "Fetching open OpsGenie alerts"

  local resp
  resp="$(curl -sf \
    -H "Authorization: GenieKey ${OPSGENIE_API_KEY}" \
    "https://api.opsgenie.com/v2/alerts?limit=25&query=status:open" \
    2>/dev/null || echo '{"data":[]}')"

  local count
  count="$(echo "$resp" | jq '.data | length')"

  if [[ "$count" -eq 0 ]]; then
    ok "No open OpsGenie alerts."
    return
  fi

  local inc_file="${INPUTS}/signals/incidents.md"
  if [[ ! -f "$inc_file" ]]; then
    write_file "$inc_file" "# Incidents / operational signals (append-only)"
  fi

  local entries
  entries="$(echo "$resp" | jq -r '
    .data[]
    | "## \(.createdAt[:10]) — \(.message)\n- Status: \(.status)\n- Priority: \(.priority)\n- Owner: \(.owner // "Unassigned")\n- Follow-up: TBD\n"
  ' || true)"

  append_file "$inc_file" "
<!-- OpsGenie pull: ${TODAY} -->
${entries}"

  ok "OpsGenie: ${count} alert(s) written to inputs/signals/incidents.md"
}

# ═══════════════════════════════════════════════════════════════════════════════
# SLACK
# ═══════════════════════════════════════════════════════════════════════════════
collect_slack() {
  header "Slack"

  if [[ -z "${SLACK_BOT_TOKEN:-}" || -z "${SLACK_CHANNELS:-}" ]]; then
    warn "Slack not configured (SLACK_BOT_TOKEN, SLACK_CHANNELS). Skipping."
    return
  fi
  if ! require jq "https://stedolan.github.io/jq/download/"; then return; fi
  if ! require curl "system package manager"; then return; fi

  local pattern="${SLACK_SIGNAL_PATTERN:-blocked|incident|outage|risk|escalat}"
  local inc_file="${INPUTS}/signals/incidents.md"

  if [[ ! -f "$inc_file" ]]; then
    write_file "$inc_file" "# Incidents / operational signals (append-only)"
  fi

  IFS=',' read -ra CHANNELS <<< "${SLACK_CHANNELS}"
  local total_signals=0

  for channel in "${CHANNELS[@]}"; do
    channel="$(echo "$channel" | tr -d '[:space:]')"
    info "Scanning Slack channel: ${channel}"

    local resp
    resp="$(curl -sf \
      -H "Authorization: Bearer ${SLACK_BOT_TOKEN}" \
      "https://slack.com/api/conversations.history?channel=${channel}&limit=100" \
      2>/dev/null || echo '{"messages":[]}')"

    local ok_flag
    ok_flag="$(echo "$resp" | jq -r '.ok // "false"')"
    if [[ "$ok_flag" != "true" ]]; then
      local slack_err
      slack_err="$(echo "$resp" | jq -r '.error // "unknown error"')"
      warn "Slack channel ${channel}: ${slack_err}"
      continue
    fi

    local signals
    signals="$(echo "$resp" | jq -r \
      --arg pat "$pattern" \
      '.messages[]
       | select(.text | test($pat; "i"))
       | select(.subtype == null)
       | "- \(.text[:200])"' 2>/dev/null || true)"

    if [[ -n "$signals" ]]; then
      local sig_count
      sig_count="$(echo "$signals" | wc -l | tr -d ' ')"
      append_file "$inc_file" "
<!-- Slack #${channel} signals: ${TODAY} -->
${signals}"
      total_signals=$((total_signals + sig_count))
    fi
  done

  if [[ "$total_signals" -gt 0 ]]; then
    ok "Slack: ${total_signals} signal(s) written to inputs/signals/incidents.md"
  else
    ok "Slack: no matching signals found."
  fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# CALENDAR
# ═══════════════════════════════════════════════════════════════════════════════
collect_calendar() {
  header "Calendar"

  local todo_file="${INPUTS}/todo.md"

  # Bootstrap today's todo.md if it doesn't exist or is empty / dated yesterday
  if [[ ! -f "$todo_file" ]]; then
    write_file "$todo_file" "# Today (${TODAY})

## Outcomes (what \"done\" looks like)
-

## Tasks (optional)
-

## Meetings / time constraints
-

## Constraints / blockers
-"
  fi

  # Replace the date header if it's stale
  if [[ "$DRY_RUN" == "false" ]] && grep -q "^# Today (" "$todo_file" 2>/dev/null; then
    local file_date
    file_date="$(grep "^# Today (" "$todo_file" | sed 's/# Today (//;s/)//' | head -1)"
    if [[ "$file_date" != "$TODAY" ]]; then
      info "todo.md is from ${file_date} — rotating to today (${TODAY})"
      sed -i "s/^# Today (${file_date})/# Today (${TODAY})/" "$todo_file" 2>/dev/null \
        || sed -i '' "s/^# Today (${file_date})/# Today (${TODAY})/" "$todo_file" 2>/dev/null \
        || warn "Could not auto-rotate date in todo.md — please update manually."
    fi
  fi

  local method="${GCAL_METHOD:-}"

  if [[ -z "$method" ]]; then
    warn "GCAL_METHOD not set in collect.config. Skipping calendar."
    return
  fi

  # Remove any previous calendar block for today
  if [[ "$DRY_RUN" == "false" && -f "$todo_file" ]]; then
    # Delete lines between <!-- gcal --> markers if present
    sed -i '/<!-- gcal-start -->/,/<!-- gcal-end -->/d' "$todo_file" 2>/dev/null \
      || sed -i '' '/<!-- gcal-start -->/,/<!-- gcal-end -->/d' "$todo_file" 2>/dev/null \
      || true
  fi

  local meetings=""

  case "$method" in
    gcalcli)
      if ! require gcalcli "pip install gcalcli"; then return; fi
      local tomorrow
      tomorrow="$(date -d tomorrow +%Y-%m-%d 2>/dev/null || date -v+1d +%Y-%m-%d 2>/dev/null || echo "$TODAY")"
      meetings="$(gcalcli agenda "${TODAY}" "${tomorrow}" --nocolor --tsv 2>/dev/null \
        | awk -F'\t' 'NF>=6 {printf "- %s %s\n", $3, $6}' || true)"
      ;;
    ical)
      if [[ -z "${GCAL_ICAL_URL:-}" ]]; then
        warn "GCAL_METHOD=ical but GCAL_ICAL_URL is not set. Skipping."
        return
      fi
      if ! require curl "system package manager"; then return; fi
      # Very lightweight iCal parser — extracts SUMMARY and DTSTART for today
      local ical_data
      ical_data="$(curl -sf "${GCAL_ICAL_URL}" 2>/dev/null || true)"
      if [[ -z "$ical_data" ]]; then
        warn "Could not fetch iCal URL. Skipping."; return
      fi
      # Parse events: find DTSTART:YYYYMMDDTHHMMSS lines for today and their SUMMARY
      meetings="$(echo "$ical_data" | awk -v today="${TODAY//-/}" '
        /^BEGIN:VEVENT/ { in_event=1; dtstart=""; summary="" }
        /^END:VEVENT/ {
          if (in_event && dtstart != "" && summary != "") {
            printf "- %s:00 %s\n", substr(dtstart,9,2) ":" substr(dtstart,11,2), summary
          }
          in_event=0
        }
        in_event && /^DTSTART/ {
          split($0, a, ":"); dtstart=a[2]
          gsub(/[^0-9]/, "", dtstart)
          if (substr(dtstart,1,8) != today) dtstart=""
        }
        in_event && /^SUMMARY:/ { sub(/^SUMMARY:/, ""); summary=$0 }
      ' | sort || true)"
      ;;
    *)
      warn "Unknown GCAL_METHOD: ${method}. Use 'gcalcli' or 'ical'."
      return
      ;;
  esac

  if [[ -z "$meetings" ]]; then
    info "No calendar events found for today."
    meetings="- (no events found)"
  fi

  local cal_block="<!-- gcal-start -->
## Meetings / time constraints
${meetings}
<!-- gcal-end -->"

  append_file "$todo_file" "
${cal_block}"
  ok "Calendar meetings written to inputs/todo.md"
}

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════════
echo -e "${BOLD}TL-Ops Collector — ${TODAY}${RESET}"
[[ "$DRY_RUN" == "true" ]] && echo -e "${YELLOW}DRY RUN — no files will be modified${RESET}"

[[ "$DO_JIRA"       == "true" ]] && collect_jira
[[ "$DO_GITHUB"     == "true" ]] && collect_github
[[ "$DO_LINEAR"     == "true" ]] && collect_linear
[[ "$DO_PAGERDUTY"  == "true" ]] && collect_pagerduty
[[ "$DO_OPSGENIE"   == "true" ]] && collect_opsgenie
[[ "$DO_SLACK"      == "true" ]] && collect_slack
[[ "$DO_CALENDAR"   == "true" ]] && collect_calendar

echo -e "\n${GREEN}${BOLD}Collection complete.${RESET}"
echo -e "Next: ${CYAN}./ops/run_dashboard.sh${RESET}"

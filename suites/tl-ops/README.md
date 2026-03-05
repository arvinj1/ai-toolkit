# TL-Ops: Team Lead Leadership Operating System

A suite of **LLM skills** that give Engineering Team Leads a structured weekly operating rhythm and a strategic team composition framework — without sending data to any third-party SaaS.

Works with **Claude, GPT-4o, Gemini, Llama (local), AWS Bedrock, Azure OpenAI** — see [LLM runners](#llm-runners).

---

## Skills

| Skill | When to run | What it produces |
|---|---|---|
| **tl-dashboard** | Weekly (Monday) | Full ops dashboard: RAG status, outcomes, risks, decisions, people health, next week plan |
| **tl-team-composer** | Quarterly or at hiring decision points | Team composition analysis: humans vs agents, workload profile, hire vs agent recommendations, 90-day target |

---

## Table of contents

1. [Quick start](#quick-start)
2. [Skills](#skills-1)
   - [tl-dashboard](#tl-dashboard) — weekly ops
   - [tl-team-composer](#tl-team-composer) — strategic team composition
3. [How it works](#how-it-works)
4. [Tools](#tools)
   - [ops/collect.sh](#opscollectsh) — pull data from Jira, GitHub, Linear, PagerDuty, Slack, Calendar
   - [ops/compose.sh](#opscomposesh) — run the team composer
   - [ops/serve.sh + viewer](#opsservesh--viewer) — browse and print outputs in a web UI
   - [LLM runners](#llm-runners) — Claude, GPT-4o, Gemini, Ollama, Bedrock, Azure
5. [Input files — what they are and how to fill them](#input-files)
   - [inputs/todo.md](#inputstodomd) — today
   - [inputs/status_weekly.md](#inputsstatus_weeklymd) — the week
   - [inputs/decisions.md](#inputsdecisionsmd) — decision log
   - [inputs/risks.md](#inputsrisksmd) — active risks
   - [inputs/stakeholders.md](#inputsstakeholdersmd) — who cares and why
   - [inputs/signals/incidents.md](#inputssignalsincidentsmd) — operational signals
   - [inputs/people/*.md](#inputspeoplemd) — team members
   - [inputs/jira_snapshot.md](#inputsjira_snapshotmd) — optional Jira pull
   - [inputs/client_requests.md](#inputsclient_requestsmd) — optional client input
   - [inputs/team/*.md](#inputsteammd) — team composition inputs (for tl-team-composer)
6. [Populating from external tools](#populating-from-external-tools)
   - [Jira](#jira)
   - [GitHub Issues / Projects](#github-issues--projects)
   - [Linear](#linear)
   - [Slack](#slack)
   - [PagerDuty / OpsGenie](#pagerduty--opsgenie)
   - [Google Calendar](#google-calendar)
   - [Any other tool](#any-other-tool)
7. [Tone / audience mode](#tone--audience-mode)
8. [Running the dashboard](#running-the-dashboard)
9. [Outputs](#outputs)
10. [Suggested cadence](#suggested-cadence)
11. [Repo philosophy](#repo-philosophy)

---

## Quick start

```bash
# 1. Set up your Claude CLI runner
cp ops/claude_runner.example.sh ops/claude_runner.sh
chmod +x ops/claude_runner.sh
# Edit ops/claude_runner.sh to call your actual Claude CLI

# 2. Configure data sources (Jira, GitHub, etc.)
#    Edit ops/collect.config with your credentials

# 3. Pull data from your tools
./ops/collect.sh --all

# 4. Generate the dashboard
./ops/run_dashboard.sh
# Output → outputs/dashboards/TL_Dashboard_YYYY-MM-DD.md

# 5. Open the dashboard viewer
./ops/serve.sh --open
# Browser → http://localhost:8765
```

Or all in one line once set up:

```bash
./ops/collect.sh --all && ./ops/run_dashboard.sh
```

---

## Skills

### tl-dashboard

**Cadence:** Weekly (Monday morning)
**Run:** `./ops/run_dashboard.sh`
**Output:** `outputs/dashboards/TL_Dashboard_YYYY-MM-DD.md`

Reads all `inputs/` files and produces your full weekly TL Dashboard. Covers RAG status, outcomes, risks, decisions, stakeholder comms, technical culture, people health, org leverage, and next week's plan.

Invoke in Claude by saying: *"run TL dashboard"* / *"weekly ops review"*

---

### tl-team-composer

**Cadence:** Quarterly, or whenever a hiring decision is on the table
**Run:** `./ops/compose.sh`
**Output:** `outputs/team-composer/TeamComposition_YYYY-MM-DD.md`

Reads `inputs/team/*.md` and produces a strategic team composition review. Analyses your current team as a portfolio of humans + AI agents, assesses which work types are substitutable, evaluates open hiring decisions (hire vs agent vs hybrid), identifies hidden gaps, and gives a 90-day composition target.

Invoke in Claude by saying: *"run team composer"* / *"should I hire or use an agent"* / *"quarterly team review"*

**This skill works with any LLM** — Claude, GPT-4o, Gemini, Llama, Bedrock, Azure OpenAI. See [LLM runners](#llm-runners).

---

## How it works

```
inputs/                   ← you edit these (lightweight Markdown summaries)
  todo.md                 ← today only
  status_weekly.md
  decisions.md
  risks.md
  stakeholders.md
  signals/incidents.md
  people/*.md
  jira_snapshot.md        (optional)
  client_requests.md      (optional)
  team/                   ← for tl-team-composer
    composition.md
    workload_profile.md
    agent_inventory.md
    hiring_pipeline.md
    capacity_constraints.md
    token_costs.md         (optional)
          ↓
  LLM reads everything (Claude / GPT-4o / Gemini / Llama / Bedrock)
          ↓
outputs/dashboards/TL_Dashboard_YYYY-MM-DD.md
outputs/team-composer/TeamComposition_YYYY-MM-DD.md
```

The inputs are **human-edited summaries**, not a mirror of Jira. The goal is 5–10 minutes of your time, not 45 minutes of copy-paste.

---

## Tools

### `ops/collect.sh`

Pulls signal from your connected tools and writes directly into the `inputs/` Markdown files.
Run it before `run_dashboard.sh` to populate inputs automatically.

```bash
# Pull from all configured tools
./ops/collect.sh --all

# Pull selectively
./ops/collect.sh --jira --github
./ops/collect.sh --calendar --slack

# See what would be written without touching any files
./ops/collect.sh --all --dry-run

# Full help
./ops/collect.sh --help
```

**What it pulls:**

| Flag | Source | Writes to |
|---|---|---|
| `--jira` | Jira active sprint | `inputs/jira_snapshot.md` |
| `--github` | GitHub issues, PRs, Projects | `inputs/status_weekly.md`, `inputs/todo.md`, `inputs/signals/incidents.md` |
| `--linear` | Linear active cycle | `inputs/jira_snapshot.md` |
| `--pagerduty` | PagerDuty incidents (last 7 days) | `inputs/signals/incidents.md` |
| `--opsgenie` | OpsGenie open alerts | `inputs/signals/incidents.md` |
| `--slack` | Channel messages matching signal keywords | `inputs/signals/incidents.md` |
| `--calendar` | Today's meetings via gcalcli or iCal URL | `inputs/todo.md` |

**First-time setup:**

```bash
# ops/collect.config is already in .gitignore — safe to put credentials in it
# Fill in only the tools you use; leave others blank to skip them
nano ops/collect.config
```

**Dependencies** (install only what you use):
- `jq` — required for all API collectors (`brew install jq` / `apt install jq`)
- `gh` — required for GitHub (`brew install gh` / https://cli.github.com)
- `gcalcli` — required for Calendar gcalcli method (`pip install gcalcli`)

---

### `ops/compose.sh`

Runs the `tl-team-composer` skill. Reads all `inputs/team/*.md` files, concatenates them with the skill prompt, sends to your configured LLM, and saves output to `outputs/team-composer/`.

```bash
# Run with default Claude runner
./ops/compose.sh

# Run with a different LLM
./ops/compose.sh --runner openai
./ops/compose.sh --runner gemini
./ops/compose.sh --runner ollama    # fully local, air-gapped

# Preview the full prompt without calling the LLM
./ops/compose.sh --dry-run
```

---

### LLM runners

Both `run_dashboard.sh` and `compose.sh` support any LLM via interchangeable runner scripts. The skills themselves are plain Markdown prompts — no Claude-specific syntax.

| Runner | LLM | Enterprise use case |
|---|---|---|
| `ops/claude_runner.sh` | Anthropic Claude | Claude API / self-hosted |
| `ops/runners/openai_runner.sh` | GPT-4o, o1 | Azure OpenAI (common in enterprise) |
| `ops/runners/gemini_runner.sh` | Gemini 1.5 Pro/Flash | Google Workspace orgs |
| `ops/runners/ollama_runner.sh` | Llama 3.1, Mistral, etc. | **Fully air-gapped / on-prem** |
| `ops/runners/bedrock_runner.sh` | Claude/Llama via AWS | AWS-native orgs |
| `ops/runners/azure_ai_runner.sh` | Any Azure AI Studio model | Azure-first enterprises |

**To use a non-Claude LLM:**
```bash
# 1. Create the runner (examples in ops/RUNNERS.md)
cp ops/runners/openai_runner.example.sh ops/runners/openai_runner.sh
# 2. Set your API key
export OPENAI_API_KEY="..."
# 3. Run
./ops/run_dashboard.sh --runner openai
./ops/compose.sh --runner openai
```

Full setup instructions, example runner scripts, and model recommendations: **`ops/RUNNERS.md`**

---

### `ops/serve.sh` + viewer

A local web app that renders your `outputs/dashboards/` Markdown files as a polished, searchable dashboard browser.
No installation. Zero dependencies beyond Python (already on your machine).

```bash
# Start the viewer
./ops/serve.sh

# Auto-open browser
./ops/serve.sh --open

# Custom port
./ops/serve.sh --port 9000
```

Then open **http://localhost:8765** in any browser.

**Viewer features:**
- Lists all dashboards newest-first with a date label and "Latest" badge
- Live search / filter by date
- Renders Markdown tables, RAG status, code blocks with full styling
- RAG pill bar at the top of each dashboard (🟢/🟡/🔴 at a glance)
- Keyboard navigation: `j`/`k` or `↓`/`↑` to move between dashboards, `/` to focus search
- Print / Save as PDF button (browser print dialog, clean layout)
- Raw Markdown download button
- Works completely offline — no external requests except the `marked.js` CDN on first load

**Sharing dashboards:**

The viewer is a single `index.html` file. To share with your manager or director:
- **Option A:** Send the raw `.md` file from `outputs/dashboards/`
- **Option B:** Print to PDF from the viewer (`⌘P` / `Ctrl+P`)
- **Option C:** Host `ops/viewer/` on any internal static file server or GitHub Pages

---

## Input files

### `inputs/todo.md` — today

**What it is:** a single day's snapshot. Claude treats this as *today only* — it is never used as a weekly summary.

**What to put in it:**

```markdown
# Today (2025-01-27)

## Outcomes (what "done" looks like)
- Ship auth service PR to staging
- Unblock backend on the API schema question
- Run 1:1 with Jordan

## Tasks (optional)
- Review 3 PRs in the queue

## Meetings / time constraints
- 09:00 Standup (30 min)
- 14:00 Stakeholder review with Product (90 min)
- 16:00 Skip-level with Director

## Constraints / blockers
- Auth service depends on infra ticket INF-204 (not started)
```

**Tips:**
- Update it every morning — takes 3 minutes.
- Write Outcomes as what *done* looks like, not a task list.
- The Meetings section tells Claude whether you have a light or heavy day — it uses this to make the Next Week Plan calendar-aware.
- Leave sections empty (just a `-`) if nothing to report; don't delete them.

---

### `inputs/status_weekly.md` — the week

**What it is:** the week's outcomes, in-progress work, risks, and stakeholder notes. This is the primary source for the dashboard's "This Week's Outcomes" section.

**What to put in it:**

```markdown
# Week of 2025-01-27

## Outcomes shipped (value/outcomes, not effort)
- Shipped auth service v2 to prod — unblocks client onboarding flow
- Resolved P2 incident within SLA — root cause documented
- Hired final SRE candidate — start date confirmed

## In progress (with ETA)
- API rate-limiting — 80% done, shipping Friday
- Q1 roadmap sign-off — waiting on PM, ETA Thursday

## Risks / issues (include owner + mitigation if known)
- INF-204 blocked on vendor — owner: Alex, escalating to VP Infra by Wed

## Stakeholder notes (who needs to know what)
- Product: auth delay now resolved, no impact on launch date
- Director: SRE hire complete, team at full capacity from Feb 3
```

**Tips:**
- Fill it in Friday afternoon or Monday morning — don't let it span two weeks without updating.
- "Outcomes shipped" = delivered value to users or the business, not "worked on X". If it didn't ship, it's In progress.
- Risks here are week-scoped; long-lived risks belong in `risks.md`.

---

### `inputs/decisions.md` — decision log

**What it is:** an append-only log of significant technical, product, or people decisions. Never edit past entries — only add new ones at the top.

**What to put in it:**

```markdown
# Decision log (append-only)

## 2025-01-27 — Adopt Postgres over MongoDB for new services
**Context:** Evaluated both after scaling issues with document store.
**Decision:** Postgres for all new services from Q1 2025.
**Options considered:** MongoDB (current), Postgres, CockroachDB
**Tradeoffs:** Less flexible schema but far better query performance + team familiarity.
**Short-term win:** Removes a whole class of consistency bugs we've been fighting.
**Long-term risk:** Migration of legacy MongoDB services could take 6–12 months.
**Owner:** Sam (Backend Lead)
**Follow-ups + dates:** Draft migration plan — Sam — 2025-02-10
```

**Tips:**
- `Short-term win` is a required field — Claude surfaces it explicitly in the dashboard.
- If Owner or Follow-up date is blank, Claude will flag it as a visible action item in the dashboard.
- Even bad or reversed decisions belong here — the log is for learning, not vanity.
- Always add new entries at the top; never edit past ones.

---

### `inputs/risks.md` — active risks

**What it is:** the live risk register for your team. Risks stay here until resolved or accepted. Use `Next check` to force yourself to revisit them.

**What to put in it:**

```markdown
# Risks (active)

- Risk: Sole owner of payments service — bus factor = 1
  Impact: High — outage with no coverage if Sam leaves or is out
  Likelihood: Medium
  Owner: TL
  Mitigation: Pair Jordan with Sam for next 2 sprints; document runbook
  Next check: 2025-02-03

- Risk: Client X contract renewal not signed
  Impact: High — 30% of Q1 revenue
  Likelihood: Low
  Owner: Account Manager (Jane)
  Mitigation: Follow up with legal this week; TL to join call if needed
  Next check: 2025-01-31
```

**Tips:**
- Keep this list to ≤ 10 items. More than that means some "risks" are actually tasks.
- Always set `Next check`. Claude will ⚠️ flag any risk whose check date is in the past.
- When a risk resolves, move it to a `# Resolved` section at the bottom with the date — don't delete it.

---

### `inputs/stakeholders.md` — who cares and why

**What it is:** a stable register of people or teams you need to keep aligned. Update it when stakeholders change, not every week.

**What to put in it:**

```markdown
# Stakeholders (who cares and why)

- Director of Engineering: Cares about delivery predictability and headcount use. Needs a weekly pulse. Prefers brief Slack summary over docs.
- Product Manager (Riya): Cares about feature velocity and client commitments. Needs to know about any slip > 3 days immediately.
- Client X (via Account Manager): Cares about SLA compliance and roadmap visibility. Needs a monthly written update.
- Platform Team: Cares about API contract stability. Needs 2-week notice before breaking changes.
- Finance (Ops): Cares about headcount cost and contractor renewals. Needs input by the 15th each month.
```

**Tips:**
- One line per stakeholder is enough — Claude synthesises the comms plan from this.
- Include preferred communication channel if you know it (Slack, email, doc, call).
- Add internal teams as well as external clients.

---

### `inputs/signals/incidents.md` — operational signals

**What it is:** an append-only log of incidents, outages, and any operational signal worth tracking. Feeds the RAG status for Technology Excellence.

**What to put in it:**

```markdown
# Incidents / operational signals (append-only)

2025-01-26
- What happened: Auth service returned 503s for 18 min (09:14–09:32 UTC)
- Impact: ~400 users affected; no data loss
- Status: Resolved
- Owner: Jordan
- Follow-up: Post-mortem published 2025-01-27; runbook updated

2025-01-20
- What happened: Deploy pipeline stuck for 3 hours due to flaky test
- Impact: Delayed release by half a day
- Status: Resolved
- Owner: Sam
- Follow-up: Flaky test quarantined; ticket open to fix root cause (BE-892)
```

**Tips:**
- Log everything, even minor incidents — patterns over time are valuable.
- For open incidents, set `Status: Open` — Claude will surface them in the Risk table automatically.
- Resolved incidents stay in the log; don't remove them.

---

### `inputs/people/*.md` — team members

**What it is:** one file per direct report or key person you lead. The top fields update when something meaningful changes. 1:1 notes at the bottom are append-only.

**File name:** use the person's first name or handle — e.g. `inputs/people/jordan.md`.

**What to put in it:**

```markdown
# Jordan

Role: Senior Engineer
Strengths: Deep systems thinking, strong communicator, reliable under pressure
Growth edge: Delegation — tends to over-own rather than distribute work
Current focus: Leading the auth service migration
Recent wins: Resolved the Jan 26 incident solo; well-regarded by PM team
Recent friction: Frustrated by slow infra ticket response time (INF-204)
Motivators: Ownership of complex problems, visible impact, learning opportunities
Next opportunity: Tech lead role on the Q2 platform project

1:1 notes (append-only):
- 2025-01-20: Raised frustration with INF-204 delays. Agreed to escalate together. Wants more visibility into roadmap decisions.
- 2025-01-13: Strong positive feedback from Riya on API design. Discussed Q2 tech lead opportunity — excited.
```

**Tips:**
- `Recent friction` is the most important field for retention watch — keep it honest.
- `Motivators` and `Next opportunity` feed the coaching actions in the dashboard.
- `Growth edge` feeds the 1:1 coaching suggestion.
- Never delete 1:1 notes — they're your institutional memory.
- `_template.md` is the blank template — the skill ignores it by name; don't rename it.

---

### `inputs/jira_snapshot.md` — optional Jira pull

**What it is:** a paste or export of the current sprint state. Optional, but gives Claude velocity and ticket-level context.

**What to put in it:**

```markdown
# Jira snapshot (2025-01-27)

## Sprint: Q1-S3 (Jan 20 – Feb 2)
- Committed: 34 points
- Completed: 22 points (65%)
- Remaining: 12 points across 5 tickets

## Overdue / blocked
- BE-892: Fix flaky deploy test — Blocked (infra dependency) — 5 pts — Jordan
- FE-210: Dark mode toggle — In Review — 3 pts — Sam

## Completed this sprint
- BE-880: Auth service v2 — Done — 8 pts
- BE-875: Rate limiting — Done — 5 pts

## Spillover from last sprint
- BE-851: Legacy API deprecation — 4 pts (moved to next sprint)
```

See [Populating from Jira](#jira) for how to generate this automatically.

---

### `inputs/client_requests.md` — optional client input

**What it is:** a running log of asks, commitments, and feedback from external clients or internal customers.

**What to put in it:**

```markdown
# Client requests (active)

- Client X — Requesting SSO integration by end of Q1. Agreed in writing. Owner: TL + PM.
- Client Y — Flagged slow dashboard load times (>4s). Not committed yet. Owner: FE team to investigate.
- Internal (Finance team) — Need CSV export from reports module. Low priority; agreed for Q2.
```

---

### `inputs/team/*.md` — team composition inputs (for tl-team-composer)

Six files, all in `inputs/team/`. Pre-populated templates are included — fill them in before your first quarterly review.

| File | What to put in it | Update cadence |
|---|---|---|
| `composition.md` | Current humans: name, role, seniority, primary work type, substitutability risk | When team changes |
| `workload_profile.md` | % of team time by work type (Routine-Defined, Judgment-Heavy, Relational, Creative-Novel, Oversight) | Quarterly |
| `agent_inventory.md` | AI tools in active use: what they handle, estimated cost, oversight required | When tools change |
| `hiring_pipeline.md` | Open roles with Human / Agent / Hybrid evaluation for each gap | When pipeline changes |
| `capacity_constraints.md` | What the team structurally can't keep up with right now | Monthly or as needed |
| `token_costs.md` | Optional: actual agent costs + human fully-loaded costs for cost model output | Quarterly |

**Tips:**
- `workload_profile.md` is the hardest to fill honestly — most teams underestimate Routine-Defined work. Review a real sprint before estimating.
- `agent_inventory.md` near-misses section is important — if an agent failed, log it. The composer uses it to calibrate substitutability confidence.
- `token_costs.md` is optional. Without it, the skill still produces all sections except the cost model table.

---

## Populating from external tools

The philosophy: **don't sync everything — extract the signal**. These inputs are summaries, not mirrors. The goal is 5–10 minutes per day / 15 minutes per week, not automated pipelines (though you can build those too).

**General routing guide:**

| If you're copying from… | Distil it into… |
|---|---|
| Sprint board (Jira, Linear, GitHub Projects) | `jira_snapshot.md` + `status_weekly.md` |
| Issue tracker (GitHub Issues, Jira backlog) | `status_weekly.md` In progress + Risks |
| Monitoring / alerting (PagerDuty, OpsGenie, Datadog) | `signals/incidents.md` |
| Chat (Slack, Teams) | Any file depending on content (see Slack section) |
| Calendar | `todo.md` Meetings |
| CRM / client system | `client_requests.md` |
| HR / performance system | `people/*.md` |
| Your own notes / journal | `decisions.md` or `people/*.md` 1:1 notes |

---

### Jira

**Option 1 — Manual (recommended to start)**

At the end of each sprint or weekly:
1. Open your board's sprint view.
2. Copy: completed tickets, blocked tickets, and spillover.
3. Paste into `inputs/jira_snapshot.md` in the format shown above.
4. Add the shipped items to `inputs/status_weekly.md` Outcomes.

**Option 2 — Jira CLI**

```bash
# Install: https://github.com/ankitpokhrel/jira-cli
jira issue list \
  --project MYPROJ \
  --sprint active \
  --plain \
  --columns KEY,SUMMARY,STATUS,ASSIGNEE,STORY_POINTS \
  > inputs/jira_snapshot.md
```

**Option 3 — Jira REST API**

```bash
# Replace YOUR_DOMAIN, PROJECT, and TOKEN
curl -s \
  -H "Authorization: Bearer YOUR_TOKEN" \
  "https://YOUR_DOMAIN.atlassian.net/rest/api/3/search\
?jql=project=PROJECT+AND+sprint+in+openSprints()\
&fields=summary,status,assignee,story_points" \
  | jq -r '.issues[] |
      "- \(.fields.summary) — \(.fields.status.name) — \(.fields.assignee.displayName // "Unassigned")"' \
  >> inputs/jira_snapshot.md
```

**What to pull per input file:**

| Input file | What to pull from Jira |
|---|---|
| `status_weekly.md` Outcomes | Tickets moved to Done this week |
| `status_weekly.md` In progress | Tickets In Progress with ETA |
| `status_weekly.md` Risks | Blocked tickets, spillover |
| `jira_snapshot.md` | Full sprint view (completed, blocked, remaining) |
| `risks.md` | Long-running blocked epics or cross-team dependencies |

---

### GitHub Issues / Projects

**Option 1 — Manual**

Weekly, filter `is:open is:issue assignee:@me` or your team label, and summarise into `status_weekly.md`.

**Option 2 — GitHub CLI (`gh`)**

```bash
# Open issues assigned to you
gh issue list \
  --repo your-org/your-repo \
  --assignee "@me" \
  --state open \
  --json number,title,labels,assignees,milestone \
  | jq -r '.[] |
      "- #\(.number) \(.title) [\(.labels | map(.name) | join(", "))]"' \
  >> inputs/status_weekly.md

# PRs awaiting your review (good for today's blockers)
gh pr list \
  --repo your-org/your-repo \
  --state open \
  --json number,title,createdAt \
  | jq -r '.[] |
      "- PR #\(.number): \(.title) — open since \(.createdAt[:10])"' \
  >> inputs/todo.md

# Closed issues this week (outcomes)
gh issue list \
  --repo your-org/your-repo \
  --state closed \
  --json number,title,closedAt \
  | jq -r --arg since "$(date -d '7 days ago' +%Y-%m-%d)" '
      .[] | select(.closedAt[:10] >= $since) |
      "- #\(.number) \(.title)"' \
  >> inputs/status_weekly.md
```

**Option 3 — GitHub Projects (v2)**

```bash
gh project item-list PROJECT_NUMBER \
  --owner your-org \
  --format json \
  | jq -r '.items[] | "- \(.title) — \(.status)"' \
  >> inputs/jira_snapshot.md
```

**What to pull per input file:**

| Input file | What to pull from GitHub |
|---|---|
| `status_weekly.md` Outcomes | Closed issues / merged PRs this week |
| `status_weekly.md` In progress | Open PRs in review, issues in progress |
| `todo.md` Tasks | PRs needing your review today |
| `risks.md` | Stale PRs (open > 5 days), issues with `blocked` label |
| `signals/incidents.md` | Issues tagged `incident` or `production-bug` |

---

### Linear

**Option 1 — Manual**

Use Linear's "My issues" view filtered to the current cycle. Copy completed and in-progress items into `status_weekly.md`.

**Option 2 — Linear API**

```bash
# Replace YOUR_API_KEY and TEAM_ID
curl -s \
  -H "Authorization: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "{ issues(filter: {
        team: { id: { eq: \"TEAM_ID\" } },
        cycle: { isActive: { eq: true } }
      }) { nodes { title state { name } assignee { name } estimate } } }"
  }' \
  https://api.linear.app/graphql \
  | jq -r '.data.issues.nodes[] |
      "- \(.title) — \(.state.name) — \(.assignee.name // "Unassigned")"' \
  >> inputs/jira_snapshot.md
```

**Option 3 — Linear CSV export**

Linear → Team → Cycles → Export as CSV → filter completed/blocked in a spreadsheet → paste summary into `status_weekly.md`.

---

### Slack

Slack is a signal source, not a structured input. The pattern: **read Slack, write a one-liner into the right file**.

| Slack source | Where it goes |
|---|---|
| Blocked message in your team channel | `todo.md` Constraints / blockers |
| Client complaint in a shared channel | `client_requests.md` |
| Incident in #alerts or #incidents | `signals/incidents.md` |
| Team member expressing frustration | `people/<name>.md` Recent friction + 1:1 notes |
| Decision made in a thread | `decisions.md` |
| Stakeholder flagging a concern | `stakeholders.md` or `status_weekly.md` Stakeholder notes |

**Slack API (advanced):**

```bash
# Requires a Slack app with channels:history scope
# Pull recent messages from a channel and filter for signals
curl -s \
  -H "Authorization: Bearer YOUR_BOT_TOKEN" \
  "https://slack.com/api/conversations.history\
?channel=C12345678&limit=50" \
  | jq -r '.messages[] |
      select(.text | test("blocked|incident|risk|outage"; "i")) |
      "- \(.text[:120])"' \
  >> inputs/signals/incidents.md
```

In practice: a 2-minute manual scan of key channels each morning is faster and more accurate than automation here.

---

### PagerDuty / OpsGenie

**Option 1 — Manual**

Weekly: open your service overview, filter by last 7 days, copy triggered alerts into `inputs/signals/incidents.md`.

**Option 2 — PagerDuty REST API**

```bash
# Incidents from the last 7 days
curl -s \
  -H "Authorization: Token token=YOUR_PD_TOKEN" \
  -H "Accept: application/vnd.pagerduty+json;version=2" \
  "https://api.pagerduty.com/incidents\
?statuses[]=triggered&statuses[]=acknowledged\
&since=$(date -d '7 days ago' +%Y-%m-%dT%H:%M:%SZ)" \
  | jq -r '.incidents[] |
      "\(.created_at[:10])\n\
- What happened: \(.title)\n\
- Impact: \(.urgency)\n\
- Status: \(.status)\n\
- Owner: \(.assignments[0].assignee.summary // "Unassigned")\n\
- Follow-up: TBD\n"' \
  >> inputs/signals/incidents.md
```

**Option 3 — OpsGenie REST API**

```bash
curl -s \
  -H "Authorization: GenieKey YOUR_API_KEY" \
  "https://api.opsgenie.com/v2/alerts?limit=10&query=status:open" \
  | jq -r '.data[] |
      "- \(.message) — \(.status) — \(.owner // "Unassigned")"' \
  >> inputs/signals/incidents.md
```

---

### Google Calendar

**What to extract:** today's meetings → `inputs/todo.md` Meetings / time constraints.

**Option 1 — Manual (recommended)**

Each morning, type your 2–4 key meetings into `todo.md`. Takes 30 seconds.

**Option 2 — `gcalcli`**

```bash
# Install: pip install gcalcli
gcalcli agenda "$(date +%Y-%m-%d)" "$(date -d tomorrow +%Y-%m-%d)" \
  --nocolor --tsv \
  | awk -F'\t' '{print "- " $3 " " $6}' \
  >> inputs/todo.md
```

**Option 3 — Google Calendar API (Python)**

```python
# Requires: pip install google-auth google-api-python-client
from googleapiclient.discovery import build
from datetime import datetime, timezone

service = build('calendar', 'v3', credentials=creds)
now = datetime.now(timezone.utc).isoformat()

events = service.events().list(
    calendarId='primary',
    timeMin=now,
    maxResults=10,
    singleEvents=True,
    orderBy='startTime'
).execute()

with open('inputs/todo.md', 'a') as f:
    f.write('\n## Meetings / time constraints\n')
    for e in events.get('items', []):
        start = e['start'].get('dateTime', e['start'].get('date'))
        f.write(f"- {start[11:16]} {e['summary']}\n")
```

---

### Any other tool

The pattern is always the same:

1. **Export or query** the tool (CLI, API, CSV, or manual copy).
2. **Filter for signal** — completed work → Outcomes; blocked/open → Risks or In progress; operational events → `incidents.md`.
3. **Write a human-readable summary** into the right input file. One line per item is enough.
4. **Don't mirror everything.** If you're pasting > 20 lines from a tool, you're doing too much — summarise instead.

---

## Tone / audience mode

Add one of these comments to any input file (e.g. top of `status_weekly.md`) to control dashboard output:

```markdown
<!-- mode: private -->   ← default: full candour, all coaching notes, retention risks named
<!-- mode: team -->      ← removes individual coaching/retention details
<!-- mode: exec -->      ← RAG + Outcomes + Hiring only; ~50% length; no people detail
```

No comment = `private` mode (default).

---

## Running the dashboard

```bash
./ops/run_dashboard.sh
```

Output: `outputs/dashboards/TL_Dashboard_YYYY-MM-DD.md`

For auto-run on Mondays, see `ops/run_on_startup.md`.
For scheduling guidance, see `ops/schedules.md`.

---

## Outputs

```
outputs/
  dashboards/   ← weekly TL Dashboard (primary output)
  weekly/       ← optional: curated weekly summaries
  daily/        ← optional: daily snapshots
  monthly/      ← optional: monthly rollups built from dashboards
```

Outputs are append-only and timestamped — never edit them. They feed the Delta / trend analysis in future dashboards.

---

## Suggested cadence

| When | What | Time |
|---|---|---|
| Every morning | `./ops/collect.sh --calendar` (auto-fills meetings) | 30 sec |
| Every morning | Glance at `inputs/todo.md`, add outcomes + blockers | 2 min |
| As they happen | Append to `decisions.md`, `incidents.md` | 2 min each |
| Friday or Monday | `./ops/collect.sh --jira --github --linear` (auto-fills sprint data) | 30 sec |
| Friday or Monday | Review + tidy `inputs/status_weekly.md` | 5 min |
| Monday | `./ops/run_dashboard.sh` → `./ops/serve.sh --open` | 1 min |
| Monthly | Create summary in `outputs/monthly/` from last 4 dashboards | 15 min |
| Quarterly | Update `inputs/team/*.md` files | 20 min |
| Quarterly (or at hiring decision) | `./ops/compose.sh` → review in viewer | 1 min |

---

## Repo philosophy

- `inputs/` are **human-edited summaries** — not a duplicate of Jira or any tool.
- `outputs/` are **generated artifacts** — append-only, timestamped, never manually edited.
- `state/` is machine state (e.g. last run date) — ignore it.
- Less is more. A half-filled `status_weekly.md` produces a better dashboard than 200 lines of raw Jira export.

---
name: intent-forge-closeout
description: Generate a final closeout report with time, token/cost estimate, and human baseline comparison
user-invocable: true
disable-model-invocation: true
---

# IntentForge Closeout

## Role
Produce a deterministic closeout report for the current repository’s IntentForge run.
The report quantifies:
- Wall-clock time (start/end/duration)
- AI token usage and estimated dollar cost (from user-provided `/cost` or `ccusage` output)
- Human baseline cost comparison (default 8h @ $150/hr; overridable per repo)
- Final outcome summary and artifacts index

This skill is read-only with respect to source code: it MUST NOT modify application code.

## Always read (suite-local rules)
- .claude/skills/intent-forge/shared/IF_GLOBAL_RULES.md
- .claude/skills/intent-forge/shared/IF_ARTIFACT_SCHEMA.md

## Assumed artifacts root
All project artifacts MUST live under:
- .intent-forge/artifacts/

If this directory does not exist, STOP and ask the user to initialize the repo.

## Required inputs (files)
Required:
- .intent-forge/artifacts/900_state/run_state.json

Optional if present:
- .intent-forge/artifacts/900_state/approvals.yaml
- .intent-forge/artifacts/040_testing/test_report.yaml
- .intent-forge/artifacts/030_implementation/change_summary.md
- .intent-forge/artifacts/020_jira/jira_payload.yaml
- .intent-forge/artifacts/010_planning/exec_plan.md
- .intent-forge/artifacts/000_intake/intent.yaml

## Human baseline (default)
If no override file exists, use:
- human_estimated_hours: 8
- human_hourly_rate_usd: 150
- human_estimated_cost_usd: 1200

### Optional override
If this file exists, you MUST use it:
- .intent-forge/artifacts/900_state/human_baseline.yaml

Schema:
```yaml
human_baseline:
  human_estimated_hours: 8
  human_hourly_rate_usd: 150
  notes: "optional"
```

## AI cost input (user-provided)
Claude Code may or may not support `/cost` in the user’s environment.

This skill supports best-effort parsing from pasted text.

Supported sources:
- `/cost` output pasted into chat
- `npx ccusage` summary pasted into chat

If no cost data is provided:
- Token and dollar fields MUST be set to null
- The report MUST still be generated
- Instructions for collecting cost MUST be included in the markdown report

Raw pasted text MUST be saved verbatim to:
- .intent-forge/artifacts/900_state/ai_usage_raw.txt

If no pasted text is provided, you MUST still write `ai_usage_raw.txt` with a short note stating that no cost text was provided.

## Wall-clock time calculation
Determine timing in this priority order:
1. If `run_state.json` contains timestamps (e.g., start/end), use them
2. Else:
   - start = earliest file modification time (mtime) under `.intent-forge/artifacts/**` excluding directories
   - end = latest file modification time (mtime) under `.intent-forge/artifacts/**` excluding directories
   - prefer end = mtime of `.intent-forge/artifacts/040_testing/test_report.yaml` if it exists
3. If unreliable or cannot be determined, set timing fields to unknown/null and set method to "unknown"

`duration_seconds` MUST be computed if both start and end are known.

## Outputs (files to write)
You MUST write all of the following files:
- .intent-forge/artifacts/900_state/cost_report.yaml
- .intent-forge/artifacts/900_state/cost_report.md
- .intent-forge/artifacts/900_state/ai_usage_raw.txt

You MUST NOT modify any other files.

## Required YAML structure (cost_report.yaml)
The YAML file MUST follow this schema exactly (unknown values must be null or empty string as appropriate):

```yaml
closeout:
  project:
    repo: ""
    run_id: ""
  wall_clock:
    start: ""
    end: ""
    duration_seconds: null
    duration_human: ""
    method: "timestamps|file_mtime|unknown"
  ai_usage:
    model: ""
    input_tokens: null
    output_tokens: null
    total_tokens: null
    estimated_usd: null
    source: "cost_command|ccusage|unknown"
  human_baseline:
    human_estimated_hours: 8
    human_hourly_rate_usd: 150
    human_estimated_cost_usd: 1200
    notes: ""
  comparison:
    delta_usd: null
    time_saved_hours: null
  outcome:
    feature_title: ""
    release_recommendation: ""
    confidence_score: null
    tests:
      passed: null
      failed: null
      total: null
  artifacts_index:
    - path: ""
      purpose: ""
```

## Markdown report (cost_report.md)
The markdown report MUST be concise and executive-friendly and include:
1. Title: "IntentForge Closeout"
2. Project/feature summary (feature title + one paragraph)
3. Outcome (recommendation + confidence + tests summary if available)
4. Wall-clock time (start/end/duration/method)
5. AI usage & cost (tokens + dollars if available; otherwise include instructions)
6. Human baseline (hours, rate, estimated cost)
7. Comparison (delta_usd and time_saved_hours if computable)
8. Artifact index (bullet list with paths)

If AI cost data is missing, include exact instructions:
- Try `/cost` in Claude Code; if unavailable, run `npx ccusage` in the repo and paste output, then re-run `/intent-forge-closeout`.

## Chat output (MANDATORY)
Output ONLY this YAML and nothing else:

```yaml
closeout:
  status: "ok|needs_input|error"
  wrote:
    - ".intent-forge/artifacts/900_state/cost_report.yaml"
    - ".intent-forge/artifacts/900_state/cost_report.md"
    - ".intent-forge/artifacts/900_state/ai_usage_raw.txt"
  missing_inputs: []
  next_step: ""
  notes: []
```

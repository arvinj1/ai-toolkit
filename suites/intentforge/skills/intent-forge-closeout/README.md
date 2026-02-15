# IntentForge Closeout

## Overview
The IntentForge Closeout skill generates a final closeout report that quantifies the efficiency and cost-effectiveness of an IntentForge run.

## Description
Generate a final closeout report with time, token/cost estimate, and human baseline comparison.

## Role
Produce a deterministic closeout report for the current repository's IntentForge run. The report quantifies:
- **Wall-clock time**: Start/end timestamps and total duration
- **AI token usage**: Estimated token count and dollar cost
- **Human baseline comparison**: Default 8h @ $150/hr (configurable per repo)
- **Final outcome summary**: Index of all artifacts produced

## Key Features
- Read-only with respect to source code (no modifications)
- Supports multiple AI cost input formats (`/cost`, `npx ccusage`)
- Calculates wall-clock time from file timestamps or explicit timestamps
- Generates both YAML and Markdown reports
- Compares AI efficiency vs. human baseline estimates

## Inputs
**Required:**
- `.intent-forge/artifacts/900_state/run_state.json`

**Optional:**
- `.intent-forge/artifacts/900_state/approvals.yaml`
- `.intent-forge/artifacts/040_testing/test_report.yaml`
- `.intent-forge/artifacts/030_implementation/change_summary.md`
- Other artifact files from the workflow

**User-Provided:**
- AI usage/cost data (pasted from `/cost` or `ccusage` output)

## Outputs
- `.intent-forge/artifacts/900_state/cost_report.yaml` - Structured cost analysis
- `.intent-forge/artifacts/900_state/cost_report.md` - Human-readable report
- `.intent-forge/artifacts/900_state/ai_usage_raw.txt` - Raw cost data

## Usage
Invoke this skill after completing the IntentForge workflow to generate comprehensive closeout documentation.

## Configuration
Default human baseline:
- `human_estimated_hours: 8`
- `human_hourly_rate_usd: 150`
- `human_estimated_cost_usd: 1200`

Override by creating `.intent-forge/artifacts/900_state/human_baseline.yaml`

## Always Reads
- `.claude/skills/intent-forge/shared/IF_GLOBAL_RULES.md`
- `.claude/skills/intent-forge/shared/IF_ARTIFACT_SCHEMA.md`

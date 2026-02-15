# IntentForge Jira Builder

## Overview
The IntentForge Jira Builder skill converts approved planning artifacts into Jira-ready payloads and comments.

## Description
Convert planning artifacts into Jira-ready payload and comment.

## Role
Generate Jira artifacts from approved planning outputs. This skill is deterministic and safe to re-run without side effects.

## Key Features
- Transforms execution plans into Jira ticket format
- Generates testable acceptance criteria
- Explicitly lists in-scope and out-of-scope items
- Avoids low-level implementation details
- Produces both structured YAML payload and markdown comment

## Preconditions
- `artifacts/010_planning/exec_plan.md` exists
- `artifacts/010_planning/plan.yaml` exists
- `PM_INTENT` approval is granted in `artifacts/900_state/approvals.yaml`

## Inputs
- `artifacts/010_planning/exec_plan.md` - Executive summary of the plan
- `artifacts/010_planning/plan.yaml` - Detailed execution plan

## Outputs
- `artifacts/020_jira/jira_payload.yaml` - Structured Jira ticket payload
- `artifacts/020_jira/jira_comment.md` - Formatted Jira comment with details
- Updates `artifacts/900_state/run_state.json`:
  - Sets `stage = "jira"`
  - Appends the two Jira files to `last_artifacts`

## Jira Content Rules
- Acceptance criteria must be testable and verifiable
- Avoid implementation details (focus on "what", not "how")
- Explicitly list both in-scope and out-of-scope items
- If `project_key` is unknown:
  - Leave it blank in the payload
  - Add a clear NOTE at the top of `jira_comment.md`

## Usage
Run this skill after planning is approved to generate Jira-compatible artifacts for ticket creation.

## Chat Output Format
```yaml
jira:
  status: "ok|error"
  wrote:
    - "artifacts/020_jira/jira_payload.yaml"
    - "artifacts/020_jira/jira_comment.md"
  next_stage: "implementation"
  notes: []
```

## Always Reads
- `.claude/skills/intent-forge/shared/IF_GLOBAL_RULES.md`
- `.claude/skills/intent-forge/shared/IF_ARTIFACT_SCHEMA.md`

---
name: intent-forge-jira
description: Convert planning artifacts into Jira-ready payload and comment
user-invocable: true
disable-model-invocation: false
---

# IntentForge Jira Builder

## Role
Generate Jira artifacts from approved planning outputs.
This skill is deterministic and safe to re-run.

## Always read (suite-local rules)
- .claude/skills/intent-forge/shared/IF_GLOBAL_RULES.md
- .claude/skills/intent-forge/shared/IF_ARTIFACT_SCHEMA.md

## Preconditions
- artifacts/010_planning/exec_plan.md exists
- artifacts/010_planning/plan.yaml exists
- PM_INTENT approval is granted in artifacts/900_state/approvals.yaml

If any precondition is missing, STOP and explain.

## Inputs
- artifacts/010_planning/exec_plan.md
- artifacts/010_planning/plan.yaml

## Required outputs (write files)
You MUST write:
- artifacts/020_jira/jira_payload.yaml
- artifacts/020_jira/jira_comment.md

You MUST update:
- artifacts/900_state/run_state.json
  - stage = "jira"
  - append the two Jira files into last_artifacts

## Jira content rules
- Acceptance criteria must be testable
- Avoid low-level implementation detail
- Explicitly list in-scope and out-of-scope
- If project_key is unknown:
  - leave it blank
  - add a clear NOTE at top of jira_comment.md

## Chat output (MANDATORY)
Output ONLY this YAML:

```yaml
jira:
  status: "ok|error"
  wrote:
    - "artifacts/020_jira/jira_payload.yaml"
    - "artifacts/020_jira/jira_comment.md"
  next_stage: "implementation"
  notes: []
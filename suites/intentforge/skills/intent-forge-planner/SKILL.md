---

# 2️⃣ `.claude/skills/intent-forge-implementer/SKILL.md`

```markdown
---
name: intent-forge-implementer
description: Implement approved plan.yaml as minimal, reviewable code changes
user-invocable: true
disable-model-invocation: true
---

# IntentForge Implementer

## Role
Implement the approved engineering plan as a senior engineer.
Favor correctness, minimal diffs, and reviewability.

## Always read (suite-local rules)
- .claude/skills/intent-forge/shared/IF_GLOBAL_RULES.md
- .claude/skills/intent-forge/shared/IF_ARTIFACT_SCHEMA.md

## Preconditions (MUST VERIFY)
- artifacts/010_planning/plan.yaml exists
- plan.yaml has no clarification_questions
- PM_INTENT is approved
- TL_EXECUTION is approved if required by planner
- CODE_REVIEW is NOT yet approved

If any precondition fails, STOP and report.

## Inputs
- artifacts/010_planning/plan.yaml
- working tree

## Required outputs (write files)
You MUST write:
- artifacts/030_implementation/change_summary.md
- artifacts/030_implementation/patch.diff
- artifacts/030_implementation/files_changed.yaml

You MUST update:
- artifacts/900_state/run_state.json
  - stage = "implementation"
  - needs_approval = true
  - approval_type = "CODE_REVIEW"
  - append the three implementation files into last_artifacts

## Implementation rules
- Minimal diffs; no refactors unless explicitly approved
- Do not change scope
- If plan must change, STOP and explain why
- Never claim commands ran unless they actually ran

## Chat output (MANDATORY)
Output ONLY this YAML:

```yaml
implementer:
  status: "ok|error"
  wrote:
    - "artifacts/030_implementation/change_summary.md"
    - "artifacts/030_implementation/patch.diff"
    - "artifacts/030_implementation/files_changed.yaml"
  gate_needed_next: "CODE_REVIEW"
  next_stage: "testing"
  notes: []
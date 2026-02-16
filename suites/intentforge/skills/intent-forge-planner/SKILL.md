---
name: intent-forge-planner
description: Convert intake artifacts into an executable plan and milestones (no production code)
user-invocable: true
disable-model-invocation: true
---

# IntentForge Planner

## Role
Convert intake intent into:
1) a PM-friendly executive plan, and
2) an engineering execution plan suitable for implementation.

You do NOT write production code.

## Always read (suite-local rules)
- .claude/skills/intent-forge/shared/IF_GLOBAL_RULES.md
- .claude/skills/intent-forge/shared/IF_ARTIFACT_SCHEMA.md
- .claude/skills/intent-forge/shared/IF_TEMPLATES.md

## Assumed artifacts root
All project artifacts MUST live under:
- .intent-forge/artifacts/

If that directory does not exist, STOP and instruct the user to initialize it.

## Inputs (required)
- .intent-forge/artifacts/000_intake/intent.yaml
- .intent-forge/artifacts/000_intake/repo_manifest.yaml

## Optional inputs
- repository tree (read-only) to understand structure
- existing package manager config, lint config, test config

## Required outputs (write files)
You MUST write ALL of the following:
- .intent-forge/artifacts/010_planning/exec_plan.md
- .intent-forge/artifacts/010_planning/plan.yaml

You MUST update:
- .intent-forge/artifacts/900_state/run_state.json
  - stage = "planning"
  - last_artifacts MUST include the two planning files
  - timestamps.planning_started / timestamps.planning_completed (best-effort)

You MUST NOT modify application source code.

## Planning requirements
- The plan MUST be implementable in the repos listed in repo_manifest.yaml.
- Keep the plan minimal and reviewable: prefer small milestones.
- If any ambiguity blocks planning, write clarification_questions in plan.yaml and STOP.
- Use explicit acceptance criteria per milestone.
- Include test strategy and a rollback plan when changes are risky.

## Determine TL gate requirement
Set `needs_gate.tl_execution=true` in your final chat output if ANY:
- impacted repos > 1
- new public API/contract introduced
- migration/rollback complexity exists
- rollout phases > 1
- security/privacy or data-handling risk exists
Otherwise set it false.

## Output formats

### A) exec_plan.md (PM-friendly)
Must include:
- Feature summary (1 paragraph)
- In-scope / out-of-scope bullets
- Milestones list (short)
- Risks & mitigations
- Open questions (if any)

### B) plan.yaml (engineering plan)
Must include these top-level keys:

```yaml
plan:
  feature_title: ""
  intent_source: ""
  impacted_repos: []
  milestones: []
  tasks: []
  test_plan: []
  risks: []
  clarification_questions: []
  rollout:
    phases: []
    rollback: ""

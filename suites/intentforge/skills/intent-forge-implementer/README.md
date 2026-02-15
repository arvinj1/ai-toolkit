# IntentForge Implementer

## Overview
The IntentForge Implementer skill transforms approved engineering plans into minimal, reviewable code changes.

## Description
Implement approved plan.yaml as minimal diffs + patch.diff.

## Role
Implement the approved plan as a senior engineer with minimal, reviewable diffs. Favors correctness, minimal changes, and easy code review.

## Key Features
- Generates minimal diffs with no unnecessary refactoring
- Produces patch files for easy review and application
- Strictly adheres to approved plan scope
- Stops and reports if plan deviations are needed
- Never claims tests ran unless actually executed

## Preconditions (Verified Before Execution)
- `artifacts/010_planning/plan.yaml` exists
- Plan has no `clarification_questions`
- `PM_INTENT` gate is approved
- `TL_EXECUTION` gate is approved (if required by planner)
- `CODE_REVIEW` gate is NOT yet approved

## Inputs
- `artifacts/010_planning/plan.yaml` - Approved execution plan
- Working tree - Current codebase state

## Outputs
- `artifacts/030_implementation/change_summary.md` - Summary of changes made
- `artifacts/030_implementation/patch.diff` - Git diff of all changes
- `artifacts/030_implementation/files_changed.yaml` - List of modified files
- Updates `artifacts/900_state/run_state.json`:
  - Sets `stage = "implementation"`
  - Sets `needs_approval = true`
  - Sets `approval_type = "CODE_REVIEW"`
  - Appends implementation files to `last_artifacts`

## Implementation Rules
- **Minimal diffs only**: No refactoring unless explicitly approved in plan
- **No scope changes**: Strictly implement what's in the approved plan
- **Stop if plan must change**: Don't improvise; explain what needs approval
- **Honest execution**: Never claim commands ran without actually running them

## Usage
Run this skill after obtaining approval on the execution plan to implement the planned changes.

## Chat Output Format
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
```

## Always Reads
- `../intent-forge/shared/IF_GLOBAL_RULES.md`
- `../intent-forge/shared/IF_ARTIFACT_SCHEMA.md`

# IntentForge Planner

## Overview
The IntentForge Planner skill transforms intake requirements into detailed, executable engineering plans.

## Description
Analyze requirements and generate a comprehensive execution plan with architecture, file-level changes, and risk assessment.

## Role
Act as a senior technical lead to create detailed, executable plans from user requirements. The planner performs requirements analysis, identifies architectural implications, and produces actionable implementation plans.

## Key Features
- Analyzes requirements and identifies ambiguities
- Generates architecture diagrams and design decisions
- Creates file-level implementation plans
- Assesses risks and identifies dependencies
- Determines required approval gates (PM, Tech Lead)
- Produces both executive summaries and detailed plans

## Inputs
- `artifacts/000_intake/intent.yaml` - User requirements and constraints
- `artifacts/000_intake/repo_manifest.yaml` - Repository structure and context
- Working tree - Current codebase state

## Outputs
- `artifacts/010_planning/exec_plan.md` - Executive summary for stakeholders
- `artifacts/010_planning/plan.yaml` - Detailed execution plan
- `artifacts/010_planning/architecture.yaml` - Architecture decisions and diagrams
- Updates `artifacts/900_state/run_state.json`:
  - Sets `stage = "planning"`
  - Sets required approval gates
  - Appends planning files to `last_artifacts`

## Planning Rules
- Ask clarification questions if requirements are ambiguous
- Consider architectural implications and technical debt
- Identify all affected files and required changes
- Assess implementation risk and complexity
- Recommend appropriate approval gates based on scope
- Be conservative: if in doubt, require Tech Lead review

## Approval Gates
The planner determines which gates are required:
- **PM_INTENT**: Always required (validates business requirements)
- **TL_EXECUTION**: Required for significant architectural changes, high-risk changes, or when plan complexity warrants technical review

## Usage
Run this skill after intake to create a comprehensive execution plan that guides implementation.

## Chat Output Format
```yaml
planner:
  status: "ok|error"
  wrote:
    - "artifacts/010_planning/exec_plan.md"
    - "artifacts/010_planning/plan.yaml"
    - "artifacts/010_planning/architecture.yaml"
  has_clarification_questions: true|false
  gate_needed_next: "PM_INTENT"
  next_stage: "jira"
  notes: []
```

## Always Reads
- `.claude/skills/intent-forge/shared/IF_GLOBAL_RULES.md`
- `.claude/skills/intent-forge/shared/IF_ARTIFACT_SCHEMA.md`
- `.claude/skills/intent-forge/shared/IF_TEMPLATES.md`

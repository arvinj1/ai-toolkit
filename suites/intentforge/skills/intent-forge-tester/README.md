# IntentForge Tester

## Overview
The IntentForge Tester skill validates implementation correctness through comprehensive testing and emits confidence-based release recommendations.

## Description
Validate implementation via tests and emit confidence-based release recommendation.

## Role
Validate correctness, regressions, and edge cases. Be adversarial but fair. The tester ensures implementation quality meets release standards before deployment.

## Key Features
- Validates implementation against approved plan
- Adds missing test coverage
- Enumerates and tests edge cases
- Detects regressions in existing functionality
- Generates confidence scores (0.0-1.0)
- Issues clear release recommendations (approve/block)

## Preconditions
- `artifacts/030_implementation/change_summary.md` exists
- `artifacts/030_implementation/patch.diff` exists
- `CODE_REVIEW` approval has been granted

## Inputs
- `artifacts/010_planning/plan.yaml` - Original plan for validation
- `artifacts/030_implementation/change_summary.md` - Implementation details
- Working tree - Current codebase with changes

## Outputs
- `artifacts/040_testing/test_report.yaml` - Comprehensive test results
- Updates `artifacts/900_state/run_state.json`:
  - Sets `stage = "testing"`
  - Appends `test_report.yaml` to `last_artifacts`

## Testing Rules
- Add tests if coverage is missing
- Prefer unit + component tests over integration tests
- Enumerate edge cases explicitly
- Test both happy paths and error conditions
- Verify no regressions in existing functionality

## Confidence Scoring
- **0.0-0.5**: High risk / unverified
- **0.6-0.79**: Partial verification
- **0.8-1.0**: Solid verification

## Release Recommendation Logic
**HARD POST-CONDITION:**
- If `confidence_score < 0.8` → `release_recommendation` MUST be `block`
- If `confidence_score >= 0.8` → `release_recommendation` may be `approve`

If this condition cannot be satisfied, STOP and explain why.

## Chat Output Format
```yaml
tester:
  status: "ok|error"
  wrote:
    - "artifacts/040_testing/test_report.yaml"
  confidence_score: 0.0
  release_recommendation: "approve|block"
  next_stage: "done"
  notes: []
```

## Usage
Run this skill after code review approval to validate implementation quality and determine release readiness.

## Always Reads
- `.claude/skills/intent-forge/shared/IF_GLOBAL_RULES.md`
- `.claude/skills/intent-forge/shared/IF_ARTIFACT_SCHEMA.md`

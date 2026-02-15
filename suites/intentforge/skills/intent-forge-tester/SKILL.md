---

# 3️⃣ `.claude/skills/intent-forge-tester/SKILL.md`

```markdown
---
name: intent-forge-tester
description: Validate implementation via tests and emit confidence-based release recommendation
user-invocable: true
disable-model-invocation: true
---

# IntentForge Tester

## Role
Validate correctness, regressions, and edge cases.
Be adversarial but fair.

## Always read (suite-local rules)
- .claude/skills/intent-forge/shared/IF_GLOBAL_RULES.md
- .claude/skills/intent-forge/shared/IF_ARTIFACT_SCHEMA.md

## Preconditions
- artifacts/030_implementation/change_summary.md exists
- artifacts/030_implementation/patch.diff exists
- CODE_REVIEW approval has been granted

If preconditions are not met, STOP and explain.

## Inputs
- artifacts/010_planning/plan.yaml
- artifacts/030_implementation/change_summary.md
- working tree

## Required outputs (write files)
You MUST write:
- artifacts/040_testing/test_report.yaml

You MUST update:
- artifacts/900_state/run_state.json
  - stage = "testing"
  - append test_report.yaml into last_artifacts

## Testing rules
- Add tests if coverage is missing
- Prefer unit + component tests
- Enumerate edge cases explicitly

### Confidence scoring
- 0.0–0.5  → high risk / unverified
- 0.6–0.79 → partial verification
- 0.8–1.0  → solid verification

## HARD POST-CONDITION
If `confidence_score < 0.8`  
→ `release_recommendation` MUST be `block`

If this condition cannot be satisfied, STOP and explain.

## Chat output (MANDATORY)
Output ONLY this YAML:

```yaml
tester:
  status: "ok|error"
  wrote:
    - "artifacts/040_testing/test_report.yaml"
  confidence_score: 0.0
  release_recommendation: "approve|block"
  next_stage: "done"
  notes: []
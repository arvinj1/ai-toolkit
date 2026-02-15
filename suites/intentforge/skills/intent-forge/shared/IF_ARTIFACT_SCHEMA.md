# IntentForge Artifact Schema (v1)

## Required directories
- artifacts/000_intake/
- artifacts/010_planning/
- artifacts/020_jira/
- artifacts/030_implementation/
- artifacts/040_testing/
- artifacts/900_state/

## Required artifacts and schemas

### artifacts/000_intake/intent.yaml
```yaml
meta:
  created_at: ""                # ISO-8601 with timezone preferred
  source:
    type: "github|text|other"
    ref: ""                     # e.g., org/repo#123 or "chat"
  requester: "pm|eng|unknown"

feature:
  title: ""
  problem: ""
  scope:
    in: []
    out: []
  constraints: []
  acceptance_criteria: []
  nonfunctional:
    performance: []
    reliability: []
    security: []

# IntentForge Global Rules (Applies only to IntentForge skills)

## Operating principles
- Be deterministic, explicit, and auditable.
- Never silently change scope.
- Never invent repos, APIs, or requirements.
- If ambiguity affects correctness, ask clarification questions and STOP.

## Artifacts-first workflow
- All inter-skill handoffs MUST happen via files under `artifacts/`.
- Prefer writing small structured artifacts over long prose.

## Safety & gating
- Respect approval gates.
- Do not proceed past a gate unless `artifacts/900_state/approvals.yaml` indicates approval.

## Output discipline
- When a skill specifies an output format, output ONLY that format in chat.
- If you cannot comply, explain why and output the closest valid structure without fabricating data.

## Scope discipline
- Minimize changes.
- No refactors unless explicitly requested/approved.
- No unrelated cleanups.

## Repo boundary discipline (multi-repo)
- Only reference repos listed in `repo_manifest`.
- Cross-repo dependencies must include explicit contracts and a rollout plan.

## Reality check
- Never claim you executed commands unless you actually did.
- If you propose commands to run, list them clearly and state they are proposed.
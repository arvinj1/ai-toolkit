# Walkthrough: a passing stack and a blocked stack

This walkthrough uses fictional PR numbers, check names, and review comments. Its local simulator prints the same two example paths without contacting GitHub or creating branches, checks, or pull requests:

```bash
python3 suites/pr-stack-review/examples/run_stack_demo.py pass
python3 suites/pr-stack-review/examples/run_stack_demo.py blocked
```

The simulator demonstrates the documented decision flow; it does not run the skill, call GitHub, execute CI, or validate a real PR stack.

## Stack plan

| Order | PR | Branch | Base | Scope |
|---|---|---|---|---|
| 1 | `#41 audit schema` | `feature/audit-schema` | `main` | Add the audit event type and validation |
| 2 | `#42 audit API` | `feature/audit-api` | `feature/audit-schema` | Persist and retrieve audit events |
| 3 | `#43 audit CLI` | `feature/audit-cli` | `feature/audit-api` | Add a CLI command that uses the API |

The stack is a linear dependency chain. Each PR is created only after its parent passes the CI and review gates. Each child diff is checked against its immediate parent so it contains only that layer's changes.

## Passing run

The active Claude Code session starts monitoring PR #41 after it is pushed. GitHub Actions runs the repository's checks; the skill uses `gh pr checks` to observe them and `gh pr view` to inspect the review decision.

```text
#41 audit schema
  CI: unit-tests=pass, lint=pass
  Reviewer: asks "How do we reject an event with an unsupported version?"
  Skill: answers with the schema validator path and the test covering version=99
  Reviewer: APPROVED
  Gate: PASS — create #42

#42 audit API
  CI: unit-tests=pass, integration-tests=pass, lint=pass
  Reviewer: APPROVED
  Gate: PASS — create #43

#43 audit CLI
  CI: unit-tests=pass, lint=pass
  Reviewer: APPROVED
  Gate: PASS — stack complete
```

The reviewer quizzes the change. The skill answers from the implementation and test evidence; it does not ask the reviewer to justify approval. If the answer is uncertain, the skill says so and leaves the human decision with the reviewer.

## Failing run

Here PR #41 has passed, so PR #42 exists. PR #42's integration test then fails. PR #43 has **not** been created.

```text
#42 audit API
  CI: unit-tests=pass, integration-tests=fail, lint=pass
  Blocking check: integration-tests
  Gate: BLOCKED — do not create #43
  Action: keep #42 open; inspect the failure, fix #42, push an update, rerun checks
```

After the repair, the session checks the same PR again. If the reviewer requested changes, it also replies to the review and waits for a new approval.

```text
#42 audit API (same PR and branch)
  CI after repair: unit-tests=pass, integration-tests=pass, lint=pass
  Reviewer after repair: APPROVED
  Gate: PASS — create #43
```

Do not discard the stack or recreate PR #42 just because its pipeline failed. Keeping the same PR preserves its review discussion and check history. If a parent needs a code change, update descendants in dependency order, verify each diff, and rerun affected checks before advancing.

## Monitoring and recovery

- **While the session is active:** Claude Code runs the workflow and polls GitHub through the GitHub CLI. GitHub Actions (or the repository's configured CI provider) executes the checks and reports their results to GitHub.
- **If the session stops:** this skill has no background worker. Monitoring pauses. On resume, inspect the current PR's latest checks, review decision, comments, and base/head before acting. Do not assume the gate passed while the session was away.
- **If GitHub cannot be queried:** treat the state as unknown and stop. Do not create a downstream PR based on stale output.
- **If CI fails or changes are requested:** repair the existing PR, rerun checks, address reviewer feedback, and wait for approval. Keep later PRs uncreated until the gate passes.
- **If a downstream PR already exists because the workflow was interrupted or manually bypassed:** leave it intact, but do not advance the stack. Reconcile its base and diff after the parent changes, then rerun its gates.

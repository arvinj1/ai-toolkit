# IntentForge (Suite)

IntentForge is a gated, auditable workflow that turns plain-English product intent into:
- an execution plan,
- Jira-ready work items,
- implemented code + tests,
- a release plan + PR body linking artifacts,
- a closeout report estimating time + AI cost vs a human baseline.

**Design principle:** IntentForge prepares the work deterministically and leaves final authority to humans via gates.

---

## Workflow at a glance

1) **Intake** → capture intent + repo manifest  
2) **Planning** → architecture/milestones/tasks  
3) **Jira** → epic/stories/subtasks payload  
4) **Implementation** → code changes + build  
5) **Testing** → report + confidence  
6) **Closeout** → time/cost comparison  
7) **Release** → preview/prod deploy plan + PR template

---

## Human gates

- `PM_INTENT` — approve scope and acceptance criteria
- `TL_EXECUTION` — approve execution plan (risk/cross-repo/rollout)
- `CODE_REVIEW` — approve implementation before completion

(Optionally, you may add `RELEASE_APPROVAL` if you later automate PR/deploy steps.)

---

## Artifact workspace (per target project repo)

All runtime artifacts are written into the target project at:

`.intent-forge/artifacts/`

Stage folders:
- `000_intake/`
- `010_planning/`
- `020_jira/`
- `030_implementation/`
- `040_testing/`
- `050_release/`
- `900_state/`

These artifacts are intentionally **not committed** by default.

---

## Installation

From the ai-toolkit repo root:

### Install to user (global)
```bash
./install/install.sh intentforge --target user
```

---

## Available Skills

Each skill in the IntentForge suite has its own dedicated README with detailed documentation:

### Core Workflow Skills

1. **[IntentForge (Controller)](./SKILL.md)** - Main workflow controller
   - Automates task building and workflow control from Intake to Testing
   - Commands: `intake`, `status`, `approve`, `reject`, `continue`

2. **[IntentForge Planner](../intent-forge-planner/README.md)** - Planning phase
   - Analyzes requirements and generates execution plans
   - Outputs: `exec_plan.md`, `plan.yaml`, `architecture.yaml`

3. **[IntentForge Jira Builder](../intent-forge-jira/README.md)** - Jira integration
   - Converts planning artifacts into Jira-ready payloads
   - Outputs: `jira_payload.yaml`, `jira_comment.md`

4. **[IntentForge Implementer](../intent-forge-implementer/README.md)** - Implementation
   - Implements approved plans with minimal diffs
   - Outputs: `change_summary.md`, `patch.diff`, `files_changed.yaml`

5. **[IntentForge Tester](../intent-forge-tester/README.md)** - Testing & validation
   - Validates implementation and recommends release readiness
   - Outputs: `test_report.yaml`

### Post-Workflow Skills

6. **[IntentForge Closeout](../intent-forge-closeout/README.md)** - Cost analysis
   - Generates closeout reports with time/cost estimates
   - Outputs: `cost_report.yaml`, `cost_report.md`

7. **[IntentForge Release (Vercel)](../intent-forge-release/README.md)** - Deployment
   - Prepares Vercel deployment plans and PR templates
   - Outputs: `deploy_plan.md`, `deploy_manifest.yaml`, `pr_body.md`

---

For detailed information about each skill, including inputs, outputs, and usage instructions, please refer to the individual README files linked above.

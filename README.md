# ai-toolkit

A collection of Claude skill suites.

## Suites

| Suite | Description |
|-------|-------------|
| [intentforge](suites/intentforge/skills/intent-forge/README.md) | Gated, auditable engineering workflow: Intake → Planning → Jira → Implement → Test → Release |
| [storytelling](suites/storytelling/skills/storytelling-framework/README.md) | Apply a 7-step storytelling framework to presentations and Jira artifacts |
| [tl-ops](suites/tl-ops/README.md) | Team Lead leadership operating system: weekly TL Dashboard covering Technology Excellence, Execution & Client Focus, and Team & Community Influence |

## Installation

Install a suite's skills into your user profile (global) or into a specific project.

### User (global)

```bash
./install/install.sh intentforge --target user
./install/install.sh storytelling --target user
./install/install.sh tl-ops --target user
```

### Project

```bash
./install/install.sh intentforge --target project --project-root /path/to/repo
./install/install.sh storytelling --target project --project-root /path/to/repo
./install/install.sh tl-ops --target project --project-root /path/to/repo
```

After installing, run Claude Code from the target repo so it discovers the skills under `.claude/skills/`.

<h1 align="center">ai-toolkit</h1>

<p align="center">
  A curated toolkit of AI coding-agent <strong>skill suites</strong> and <strong>repository skills</strong><br/>
  for delivery workflows, review quality, and team operations.
</p>

<p align="center">
  <a href="suites/intentforge/skills/intent-forge/README.md"><img alt="IntentForge suite" src="https://img.shields.io/badge/suite-intentforge-6C63FF?style=for-the-badge"></a>
  <a href="suites/storytelling/skills/storytelling-framework/README.md"><img alt="Storytelling suite" src="https://img.shields.io/badge/suite-storytelling-2EA043?style=for-the-badge"></a>
  <a href="suites/tl-ops/README.md"><img alt="TL Ops suite" src="https://img.shields.io/badge/suite-tl--ops-F59E0B?style=for-the-badge"></a>
  <a href="suites/pr-stack-review/README.md"><img alt="PR Stack Review suite" src="https://img.shields.io/badge/suite-pr--stack--review-DB2777?style=for-the-badge"></a>
</p>

## ✨ Interactive suite cards

<table>
  <tr>
    <td width="50%" valign="top">
      <h3>🧭 intentforge</h3>
      <p>End-to-end delivery workflow with auditable quality gates.</p>
      <details>
        <summary><strong>View highlights</strong></summary>
        <ul>
          <li>Intake → Planning → Jira → Implement → Test → Release</li>
          <li>Structured artifacts and gated transitions</li>
          <li>Traceable engineering workflow for teams</li>
        </ul>
      </details>
      <p><a href="suites/intentforge/skills/intent-forge/README.md"><img alt="Open intentforge" src="https://img.shields.io/badge/Open%20Suite-IntentForge-6C63FF?style=for-the-badge"></a></p>
    </td>
    <td width="50%" valign="top">
      <h3>🧩 storytelling</h3>
      <p>Narrative framework for clearer communication and planning artifacts.</p>
      <details>
        <summary><strong>View highlights</strong></summary>
        <ul>
          <li>7-step storytelling framework</li>
          <li>Applied to presentations and Jira artifacts</li>
          <li>Improves clarity, context, and stakeholder alignment</li>
        </ul>
      </details>
      <p><a href="suites/storytelling/skills/storytelling-framework/README.md"><img alt="Open storytelling" src="https://img.shields.io/badge/Open%20Suite-Storytelling-2EA043?style=for-the-badge"></a></p>
    </td>
  </tr>
  <tr>
    <td width="50%" valign="top">
      <h3>📈 tl-ops</h3>
      <p>Team-lead operating cadence and weekly dashboard workflow.</p>
      <details>
        <summary><strong>View highlights</strong></summary>
        <ul>
          <li>Weekly TL Dashboard generation</li>
          <li>Technology Excellence, Execution & Client Focus, Team & Community</li>
          <li>Operational visibility across signals, risks, and capacity</li>
        </ul>
      </details>
      <p><a href="suites/tl-ops/README.md"><img alt="Open tl-ops" src="https://img.shields.io/badge/Open%20Suite-TL--Ops-F59E0B?style=for-the-badge"></a></p>
    </td>
    <td width="50%" valign="top">
      <h3>🛡️ pr-stack-review</h3>
      <p>Governance for stacked pull requests and reviewer/CI enforcement.</p>
      <details>
        <summary><strong>View highlights</strong></summary>
        <ul>
          <li>Reviewer rotation for PR stacks</li>
          <li>Stops on failed CI or requested changes</li>
          <li>Prevents downstream publication when gates fail</li>
        </ul>
      </details>
      <p><a href="suites/pr-stack-review/README.md"><img alt="Open pr-stack-review" src="https://img.shields.io/badge/Open%20Suite-PR%20Stack%20Review-DB2777?style=for-the-badge"></a></p>
    </td>
  </tr>
</table>

## 🚀 Quick start

Install any suite either globally (user) or into a specific project.

### User (global)

```bash
./install/install.sh intentforge --target user
./install/install.sh storytelling --target user
./install/install.sh tl-ops --target user
./install/install.sh pr-stack-review --target user
```

### Project

```bash
./install/install.sh intentforge --target project --project-root /path/to/repo
./install/install.sh storytelling --target project --project-root /path/to/repo
./install/install.sh tl-ops --target project --project-root /path/to/repo
./install/install.sh pr-stack-review --target project --project-root /path/to/repo
```

After installing, run Claude Code from the target repository so it discovers skills under `.claude/skills/`.

## 🧠 Repository skill (Copilot + Codex)

| Skill | Purpose |
|---|---|
| [**Senior systems code review**](.agents/skills/code-review/SKILL.md) | Reviews design, correctness, and validation for RTC, C++, networking, media, concurrency, and distributed systems. Mirrored for Copilot at [`.github/skills/code-review`](.github/skills/code-review/SKILL.md). |

> Keep the Codex and Copilot copies synchronized. GitHub Copilot code review reads repository skills from the PR head branch, so the skill must exist on that branch to guide review behavior.

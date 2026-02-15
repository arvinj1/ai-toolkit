# IntentForge Release (Vercel)

## Overview
The IntentForge Release skill prepares Vercel deployment plans and generates PR-ready documentation linking all IntentForge artifacts.

## Description
Prepare Vercel deployment plan, generate deploy artifacts, and produce PR body/template links for an IntentForge run.

## Role
Produce deterministic release artifacts to deploy a Vite/React project to Vercel and generate a PR-ready summary that links IntentForge artifacts. This skill MUST NOT change application source code—it only writes release artifacts.

## Key Features
- Generates step-by-step Vercel deployment plans
- Creates structured deployment manifests
- Produces PR body templates with artifact links
- Captures Vercel preview and production URLs
- Includes production readiness checklist
- Supports best-effort parsing of CLI output

## Inputs
**Required:**
- `.intent-forge/artifacts/900_state/run_state.json`

**Optional (if present):**
- `.intent-forge/artifacts/000_intake/requirements.yaml`
- `.intent-forge/artifacts/010_planning/architecture.yaml`
- `.intent-forge/artifacts/030_implementation/implementation_log.yaml`
- `.intent-forge/artifacts/040_testing/test_report.yaml`
- `.intent-forge/artifacts/900_state/cost_report.md`
- `.intent-forge/artifacts/900_state/cost_report.yaml`

**User-Provided (pasted text):**
- `vercel` CLI output (for Preview URL and deployment ID)
- `git remote -v` output (for repo origin URL)
- `gh pr create` output (optional, for PR URL)

## Outputs
- `.intent-forge/artifacts/050_release/deploy_plan.md` - Step-by-step deployment guide
- `.intent-forge/artifacts/050_release/deploy_manifest.yaml` - Structured deployment data
- `.intent-forge/artifacts/050_release/pr_body.md` - PR description template
- `.intent-forge/artifacts/050_release/release_raw.txt` - Raw CLI output

## Release Scope
This skill produces:
- Step-by-step Vercel deployment plans (preview + prod)
- Structured deploy manifest with build configuration
- PR body template auto-linking IntentForge artifacts
- Production readiness checklist

It does **NOT**:
- Push git branches automatically
- Create PRs automatically
- Configure DNS
- Deploy on behalf of the user

## Deploy Manifest Structure
```yaml
release:
  project:
    name: ""
    repo_name: ""
    repo_remote_url: ""
    branch: ""
  vercel:
    framework: "vite-react"
    build_command: "npm run build"
    output_dir: "dist"
    preview_url: null
    production_url: null
    deployment_id: null
  readiness:
    tests_present: false
    tests_passed: null
    build_passed: null
    confidence_score: null
    release_recommendation: ""
    checklist: [...]
```

## Usage
Run this skill after testing is complete to generate deployment documentation and PR templates.

## Always Reads
- `.claude/skills/intent-forge/shared/IF_GLOBAL_RULES.md`
- `.claude/skills/intent-forge/shared/IF_ARTIFACT_SCHEMA.md`

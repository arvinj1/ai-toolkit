---
name: intent-forge-release
description: Prepare Vercel deployment plan, generate deploy artifacts, and produce PR body/template links for an IntentForge run
user-invocable: true
disable-model-invocation: true
---

# IntentForge Release (Vercel)

## Role
Produce deterministic release artifacts to deploy a Vite/React project to Vercel and generate a PR-ready summary that links IntentForge artifacts.
This skill MUST NOT change application source code. It may write release artifacts only.

## Always read (suite-local rules)
- .claude/skills/intent-forge/shared/IF_GLOBAL_RULES.md
- .claude/skills/intent-forge/shared/IF_ARTIFACT_SCHEMA.md

## Assumed artifacts root
All run artifacts MUST live under:
- .intent-forge/artifacts/

If this directory does not exist, STOP and ask the user to initialize the repo.

## Inputs (files)
Required:
- .intent-forge/artifacts/900_state/run_state.json

Optional if present:
- .intent-forge/artifacts/000_intake/requirements.yaml
- .intent-forge/artifacts/010_planning/architecture.yaml
- .intent-forge/artifacts/030_implementation/implementation_log.yaml
- .intent-forge/artifacts/040_testing/test_report.yaml
- .intent-forge/artifacts/900_state/cost_report.md
- .intent-forge/artifacts/900_state/cost_report.yaml

## User-provided inputs (pasted text)
This skill supports best-effort parsing from pasted text for:
- `vercel` CLI output (to capture Preview URL and deployment id)
- `git remote -v` output (to capture repo origin URL)
- `gh pr create` output (optional) to capture PR URL

If no CLI output is provided, URL fields MUST be null and instructions MUST be included.

Raw pasted text MUST be saved verbatim to:
- .intent-forge/artifacts/050_release/release_raw.txt

## Outputs (files to write)
You MUST write all of the following files:
- .intent-forge/artifacts/050_release/deploy_plan.md
- .intent-forge/artifacts/050_release/deploy_manifest.yaml
- .intent-forge/artifacts/050_release/pr_body.md
- .intent-forge/artifacts/050_release/release_raw.txt

You MUST NOT modify any other files.

## Release scope
This skill produces:
- A step-by-step Vercel deploy plan (preview + prod)
- A structured deploy manifest capturing:
  - project name
  - framework
  - build commands
  - preview url (if available)
  - prod readiness checklist
- A PR body template that auto-links IntentForge artifacts and (if available) Vercel preview URL

It does NOT:
- push git branches
- create PRs automatically
- configure DNS
- deploy on behalf of the user

## Required YAML structure (deploy_manifest.yaml)
The YAML MUST follow this schema exactly (unknown values must be null or empty string):

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
    org_scope: null
  readiness:
    tests_present: false
    tests_passed: null
    build_passed: null
    confidence_score: null
    release_recommendation: ""
    checklist:
      - item: "App runs locally (npm run dev)"
        status: "unknown|pass|fail"
      - item: "Build passes (npm run build)"
        status: "unknown|pass|fail"
      - item: "Screen share permission granted in browser"
        status: "unknown|pass|fail"
      - item: "OCR produces text on at least one sample screen"
        status: "unknown|pass|fail"
      - item: "Summary generated on stop"
        status: "unknown|pass|fail"
  intentforge_links:
    artifacts_root: ".intent-forge/artifacts"
    key_artifacts:
      - path: ".intent-forge/artifacts/000_intake/requirements.yaml"
        purpose: "Requirements captured from intent"
      - path: ".intent-forge/artifacts/010_planning/architecture.yaml"
        purpose: "Architecture + decisions"
      - path: ".intent-forge/artifacts/020_jira/jira_payload.json"
        purpose: "Jira import payload"
      - path: ".intent-forge/artifacts/030_implementation/implementation_log.yaml"
        purpose: "Implementation log"
      - path: ".intent-forge/artifacts/900_state/cost_report.md"
        purpose: "Closeout cost/time report"

## How to populate fields
- repo_name: best-effort from git top-level folder name
- repo_remote_url: best-effort from pasted `git remote -v` text; else empty string
- branch: best-effort from `git rev-parse --abbrev-ref HEAD` if available in pasted output; else empty string
- build_passed: infer from implementation_log.yaml if it includes build status; else null
- tests_present/tests_passed/confidence_score/release_recommendation: from test_report.yaml if present; else null/false
- vercel.preview_url and deployment_id: best-effort parse from pasted `vercel` output; else null

## deploy_plan.md requirements
deploy_plan.md MUST be concise and include:
1) Quick start: `npm i -g vercel` + `vercel login`
2) Preview deploy steps (vercel)
3) Production deploy steps (vercel --prod)
4) How to set output dir and build command if Vercel prompts
5) How to add custom domain (dashboard steps)
6) How to rollback (redeploy previous deployment or revert commit)
7) Where to paste CLI outputs so this skill can capture URLs next run

## pr_body.md requirements
pr_body.md MUST include:
- Summary of feature
- Test/build status (best-effort)
- Links section:
  - Vercel Preview URL (if present)
  - IntentForge artifacts list (relative paths)
  - Closeout report path
- “Demo steps” section (start sharing, OCR, summary)
- “Known issues / follow-ups” section (if any)

## Chat output (MANDATORY)
Output ONLY this YAML and nothing else:

release:
  status: "ok|needs_input|error"
  wrote:
    - ".intent-forge/artifacts/050_release/deploy_plan.md"
    - ".intent-forge/artifacts/050_release/deploy_manifest.yaml"
    - ".intent-forge/artifacts/050_release/pr_body.md"
    - ".intent-forge/artifacts/050_release/release_raw.txt"
  missing_inputs: []
  next_step: ""
  notes: []

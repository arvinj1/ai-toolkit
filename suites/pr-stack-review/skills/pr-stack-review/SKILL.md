---
name: pr-stack-review
description: Use when splitting a larger change into stacked GitHub pull requests, assigning reviewers in round-robin order from a configured group, and gating progress on successful pipeline checks and reviewer approval.
---

# PR Stack Review

## Overview

Build a dependency-ordered stack of small, reviewable GitHub pull requests. Assign one reviewer per PR from a configured roster in round-robin order. Advance to the next PR only after every pipeline check succeeds and the assigned reviewer approves the current PR. See the [suite flow](../../README.md).

## When to Use

Use this skill when the user asks to split a change into dependent PRs, rotate reviewers from a team roster, or automate sequential PR creation with a stop-on-failure CI gate.

## Process

### 1. Establish repository and permissions

1. Read repository guidance and inspect the worktree, current branch, remotes, default branch, and GitHub CLI authentication.
2. Preserve unrelated working-tree changes. Do not overwrite or reset user work.
3. Read `.claude/pr-stack-reviewers.json`. It must contain the requested reviewer group as an ordered list of GitHub usernames. Use `references/config.example.json` as the schema and replace all sample names. If the configuration or group is missing, ask for the roster. Never infer people or request the whole team as a substitute.
4. Explain the planned stack and reviewer order before publishing. Get explicit user authorization before pushing branches, opening PRs, or requesting reviewers.

### 2. Decompose the work

1. Split the change by coherent behavior and dependency, not arbitrary file count. Keep each PR independently understandable and testable.
2. Record each PR's purpose, branch, immediate base, files or behavior in scope, checks, and parent PR.
3. Use a linear parent-child chain unless separate branches are genuinely independent. Make each child's base the parent branch and keep its diff scoped to its own changes.
4. Create draft PRs by default. Do not merge, enable auto-merge, or mark a PR ready unless the user asks.

### 3. Create, assign, and gate each PR in order

Process one PR at a time, starting with the PR closest to the target base:

1. Create the local branch from its approved parent. Implement only that slice, run its local checks, and inspect the diff.
2. After user authorization, push the branch and open a draft PR with the parent branch as its base. Include the PR's scope, parent and child links, tests, and risks.
3. Assign exactly one reviewer using:

   ```bash
   python3 "${CLAUDE_SKILL_DIR}/scripts/assign_next_reviewer.py" <PR-URL> --group <group-name>
   ```

   The helper serializes assignments on this machine, excludes the PR author and reviewers already requested on that PR, and advances the rotation cursor only after GitHub confirms the assignment. Stop if configuration is invalid, the selected account cannot be requested, or no configured reviewer is eligible. Do not silently widen the roster.

4. Wait for all PR checks and record the command's exit code:

   ```bash
   gh pr checks <PR-URL> --watch --fail-fast
   gh pr checks <PR-URL> --json bucket,name,link
   ```

   After watch exits, run the JSON query even if watch reported failure so the blocking check can be identified. Proceed only if the watch command succeeded, at least one check is present, and every check bucket is `pass`. Treat failure, cancellation, skipping, pending checks after watch exits, no reported checks, timeout, and authentication or API errors as a stop.
5. After CI passes, inspect the review decision:

   ```bash
   gh pr view <PR-URL> --json reviewDecision,latestReviews
   ```

   Find the assigned reviewer's latest decisive review. Proceed only when it is `APPROVED`. If it is `CHANGES_REQUESTED`, stop and report the review. If approval is pending, keep the current PR at the gate and do not create or publish the next PR. Comments do not count as approval.
6. On any stop, report the blocked PR and CI or review evidence. Leave existing branches and PRs intact. Do not create, push, open, or assign the next PR.
7. After CI and review both pass, move to the next PR. If a parent changes later, update descendants in order, rerun affected checks, and verify each PR still contains only its intended diff.

If CI fails or review requests changes, repair that PR and rerun its checks before requesting re-review. Preserve the existing stack and PR discussion. Never skip, waive, or reinterpret a failed gate as success.

## Common Rationalizations

| Rationalization | Response |
|---|---|
| "The next PR is independent enough; I can publish it while this pipeline is red." | Stop at the failed PR. The requested workflow gates downstream publication on success. |
| "The team is configured, so requesting the whole team is equivalent." | Use the configured ordered usernames and request one reviewer only. |
| "Skipped checks are probably harmless." | Treat skipped or missing results as unknown; stop and report them. |
| "CI passed, so the next PR can start while review is pending." | Wait for the assigned reviewer's approval. CI and review are separate gates. |
| "The local cursor is good enough for everyone." | The cursor is machine-local. Do not claim global round-robin fairness across machines or operators. |

## Red Flags

- Reviewer usernames are guessed, stale, duplicated, or outside the configured roster.
- A child PR is based on the default branch instead of its parent PR branch.
- A PR diff includes changes already present in its parent.
- Any downstream branch is pushed or PR opened before the previous PR's checks pass.
- The workflow treats no checks, skipped checks, or API errors as success.
- The workflow advances without checking the assigned reviewer's latest decisive review.
- A reviewer rotation is described as shared across people or machines when only local state is configured.

## Verification

Before reporting completion, verify the ordered PR URLs and bases, one reviewer request per PR, the current rotation result, successful check buckets, and assigned-reviewer approval for every published PR. Report exact checks and review states. If stopped, state which PR blocked progress and confirm that no later PR was created or published.

The rotation cursor is stored under the user's local state directory, outside the repository, and is shared only by sessions on that machine. Cross-machine or multi-operator round robin requires a shared ledger or coordinator; until one is configured, do not claim team-wide fairness.

# Execution checklists

Use the smallest checklist that covers the current mode and flow. Checklists make the routine parts of development reliable; they do not replace feature-specific engineering judgment.

## Universal preflight

- [ ] Read `AGENTS.md`, [agent modes](/dev/agent-workflows/modes), roles, batches, and flows.
- [ ] State mode, flow, scope, non-goals, acceptance, batches, validation, and requested remote actions.
- [ ] Run `git status --short --branch` and preserve unrelated work.
- [ ] Run `git fetch --all --prune --tags`.
- [ ] Update `main` with `git pull --ff-only origin main` before creating a new branch.
- [ ] Read the relevant architecture, platform, test, documentation, and release contracts.

## Plan or Inspect

- [ ] Separate facts from assumptions and questions.
- [ ] Identify sources of truth and compatibility boundaries.
- [ ] State what the requested result does not include.
- [ ] For a plan, define acceptance, validation, rollback, and batch outcomes.
- [ ] Stop for owner input when a decision changes scope, user behavior, security, cost, or delivery authority.

## Diagnose or Review

- [ ] State expected and actual behavior.
- [ ] Reproduce or explain why safe reproduction is unavailable.
- [ ] Link findings to a narrow location and causal evidence.
- [ ] Assess user impact, regression risk, and missing checks.
- [ ] Do not edit while the task remains diagnosis or review only.

## Implement one batch

- [ ] Work only on the declared batch outcome.
- [ ] Keep direct tests with the behavior they protect.
- [ ] Run focused validation before committing.
- [ ] Review `git diff` for scope, generated output, local paths, credentials, and unrelated changes.
- [ ] Run `git diff --check`.
- [ ] Create exactly one local commit for the completed batch.
- [ ] Update the batch ledger with commit and evidence.

## Verify and deliver

- [ ] Run the broader gate required before merge, or record why it is unavailable.
- [ ] Confirm the requested remote action is explicitly authorized.
- [ ] Confirm branch, commit, and target before a push, PR, merge, release, or deploy.
- [ ] Report only actions that completed successfully; include URLs, commit IDs, and check state when available.
- [ ] After PR closure or merge, prune remote refs and safely remove stale local branches.

## Before calling work complete

- [ ] Acceptance criteria have evidence.
- [ ] Every declared batch has one local commit.
- [ ] No unapproved remote action occurred.
- [ ] Passing, failing, skipped, and blocked checks are clearly separated.
- [ ] The worktree contains only expected changes, or unrelated changes are explicitly preserved.

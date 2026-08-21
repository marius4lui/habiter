# Agent instructions

This file is the mandatory entry point for every AI agent working in this repository. It is intentionally short; the detailed, versioned rules live in the developer documentation.

## Non-negotiable preflight

Before starting any task, an agent must:

1. Read this file and the relevant pages in the rule map below.
2. Inspect the worktree with `git status --short --branch` and preserve unrelated changes.
3. Synchronize repository knowledge: run `git fetch --all --prune --tags`, then update `main` with `git pull --ff-only origin main` before creating a new task branch. Do not merge or rebase an existing task branch without an explicit instruction or the approved pull-request policy.
4. Select and state a flow, scope, acceptance criteria, batch count, and validation before editing.
5. Create or use one purpose-named branch before editing. A branch is required for every coherent change.

## Rule map

Every changing agent must read [agent modes](/dev/agent-workflows/modes), [agent roles](/dev/agent-workflows/roles), [batch rules](/dev/agent-workflows/batches), and [delivery flows](/dev/agent-workflows/flows). Read the additional page that matches the task:

| Task | Required page |
| --- | --- |
| Medium, risky, or multi-batch work | [Planning](/dev/agent-workflows/planning) |
| Repeated task type or handoff | [Playbooks](/dev/agent-workflows/playbooks) and [handoffs](/dev/agent-workflows/handoffs) |
| Branch creation, synchronization, or cleanup | [Branch workflow](/dev/branches) |
| Tests and quality evidence | [Testing and quality](/dev/testing) |
| Published documentation | [Documentation development](/dev/documentation) |
| Release or production operation | [Release operations](/release-operations) |

## Hard boundaries

- `main` may be changed only by a direct push with the owner's exact confirmation, or by merging a pull request. No third path exists.
- Every batch ends in one local, reviewable commit. Pushing, opening a pull request, merging, releasing, deploying, deleting data, or changing secrets requires explicit authorization; a local commit does not grant it.
- After a remote branch is deleted, prune and remove its matching local branch when it is no longer needed. Never force-delete the current branch or a branch checked out by another worktree.
- Do not claim a check, review, deployment, or physical-device result that was not performed. Report blocked or unavailable gates plainly.

If rules conflict, explicit owner instructions win, then this file, then the more specific linked page. Do not weaken a safety or authorization boundary by inference.

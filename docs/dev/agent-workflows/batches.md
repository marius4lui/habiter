# Batches and commits

A batch is one coherent, independently understandable outcome. It must be testable, reviewable, and safe to revert without depending on unrelated work.

## Default size limits

These are reviewability guardrails, not a reason to split one atomic change into artificial fragments. Generated files, lockfiles, and approved snapshots are reported separately from hand-authored work.

| Change class | Typical batches | Per-batch guide | Plan requirement |
| --- | --- | --- | --- |
| Tiny documentation or isolated correction | 1 | Up to 3 hand-authored files and about 100 changed lines | Short declaration |
| Focused fix or small feature | 1–3 | Up to 5 hand-authored files and about 300 changed lines | Checklist |
| Cross-layer feature | 4–8 | Up to 8 hand-authored files and about 400 changed lines | Written plan |
| Migration, security, release, or broad redesign | 9 or more | Same per-batch guide | Written plan and ledger |

Exceeding a guide is allowed only when splitting would make the result less safe or less reviewable. State the reason in the plan and pull request.

## What belongs together

- A behavior change and its direct unit, integration, widget, or regression tests.
- A contract change and the compatible adapter or migration necessary to keep existing data safe.
- The documentation needed to explain a public behavior changed in the same batch.

## What must be separated

- Unrelated cleanup, formatting, dependency updates, and refactors.
- Product behavior and an unrelated platform, deployment, or release change.
- Data migration preparation, migration execution, and destructive cleanup when each can be reviewed or rolled back separately.
- Generated output or localization regeneration from unrelated manual edits, unless the generator requires both in one atomic result.

## Commit and push rule

Every completed batch ends with exactly one local commit. Before committing, run the selected focused validation and `git diff --check`; the commit message must describe the batch outcome.

A commit does not authorize a push. Do not push any branch, create a pull request, merge, release, deploy, or delete a remote branch unless the owner explicitly authorized that exact action. When push is authorized for a multi-batch task, push each completed batch so the remote history matches the batch ledger.

If the owner requires exactly *N* batches, preserve exactly *N* completed batches and exactly *N* local commits. Do not add “small extra” commits outside the ledger.

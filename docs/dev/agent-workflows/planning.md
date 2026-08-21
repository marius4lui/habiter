# Planning work

Planning turns a request into independently reviewable outcomes before implementation starts. It prevents an agent from widening the task while it works.

## Choose the planning level

| Work size or risk | Required planning |
| --- | --- |
| Trivial, one-concern change | A short task declaration with scope, validation, and one batch. |
| Focused bug fix or small feature | A 1–3 batch checklist with acceptance criteria and focused tests. |
| Cross-layer, migration, security, release, or more than three batches | A written plan with risks, dependencies, rollback, validation, and a batch ledger. |
| Owner-specified batch count | A written ledger with exactly that many numbered batches and one commit per batch. |

Plans are durable decision records, not agent transcripts. Keep ephemeral reasoning, execution ledgers, and handoffs in the task or pull request; published `docs/` must not contain them. Commit a repository-visible technical decision only in an approved non-published planning location.

## Plan template

```md
# <Change title>

## Goal

## Scope and non-goals

## Constraints and risks

## Acceptance criteria

## Validation and rollback

## Batches

1. <independently testable outcome> — <focused evidence>
2. <independently testable outcome> — <focused evidence>
```

## Plan discipline

- Plan outcomes, not folders or implementation guesses.
- Name the source of truth for data, APIs, platform contracts, and release behavior before adding a parallel model.
- Put a behavior change and its direct tests in the same batch.
- Replan before crossing an agreed non-goal, changing a public contract, adding a migration, or exceeding the batch budget.
- Record a failed or unavailable gate as unverified; do not silently replace it with a smaller check.

## Batch ledger

For work with a fixed count, maintain one entry per batch with status, commit, evidence, and any approved exception. A batch is complete only after its local commit exists. Push is tracked separately because it needs explicit authorization.

| Batch | Outcome | Local commit | Evidence | Push authorized? |
| --- | --- | --- | --- | --- |
| 1 | Example outcome | pending | pending | no |

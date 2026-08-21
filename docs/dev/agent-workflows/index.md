# Agent workflows

This section defines how human contributors and AI agents plan, implement, review, and deliver changes in Habiter. It is the detailed source of truth for agent behavior; [`AGENTS.md`](https://github.com/marius4lui/habiter/blob/main/AGENTS.md) is the mandatory, compact entry point.

## Rule hierarchy

1. Explicit owner instructions for the current task.
2. `AGENTS.md`.
3. The most specific page in this section and the applicable engineering contract.
4. General repository documentation.

An agent must stop and request direction when two applicable rules cannot both be followed. It must not silently choose the less safe interpretation.

## Required task declaration

Before changing files, state the following in the task record, implementation plan, or pull request:

```text
Flow: Standard | Yeet | Hotfix | Release
Scope: what is included and explicitly excluded
Acceptance: observable completion criteria
Batches: number and intended outcome of each batch
Validation: focused checks and the broader merge gate
Remote actions: none | push | pull request | merge | release | deploy
```

`Remote actions` is an authorization record. Listing an action does not authorize it; the owner must explicitly authorize each remote action in the task request or an approved handoff.

## Read in this order

1. [Roles and authority](/dev/agent-workflows/roles)
2. [Planning](/dev/agent-workflows/planning) when the work is not trivial
3. [Batches and commits](/dev/agent-workflows/batches)
4. [Delivery flows](/dev/agent-workflows/flows)
5. The relevant branch, test, documentation, platform, and release contracts

The branch naming and cleanup mechanics are maintained in the [branch workflow](/dev/branches). Quality evidence is maintained in [testing and quality](/dev/testing).

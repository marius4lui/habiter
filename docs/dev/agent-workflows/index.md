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
Mode: Plan | Inspect | Diagnose | Review | Implement | Verify | Deliver | Monitor
Flow: Standard | Yeet | Hotfix | Release
Scope: what is included and explicitly excluded
Acceptance: observable completion criteria
Batches: number and intended outcome of each batch
Validation: focused checks and the broader merge gate
Remote actions: none | push | pull request | merge | release | deploy
```

`Remote actions` is an authorization record. Listing an action does not authorize it; the owner must explicitly authorize each remote action in the task request or an approved handoff.

## Read in this order

1. [Agent modes](/dev/agent-workflows/modes)
2. [Roles and authority](/dev/agent-workflows/roles)
3. [Planning](/dev/agent-workflows/planning) when the work is not trivial
4. [Batches and commits](/dev/agent-workflows/batches)
5. [Delivery flows](/dev/agent-workflows/flows)
6. The relevant [playbook](/dev/agent-workflows/playbooks), handoff pattern, and engineering contract

The branch naming and cleanup mechanics are maintained in the [branch workflow](/dev/branches). Quality evidence is maintained in [testing and quality](/dev/testing).

## Working pages

| Need | Page |
| --- | --- |
| Decide what an agent is allowed to do now | [Agent modes](/dev/agent-workflows/modes) |
| Decide who owns a decision or approval | [Roles and authority](/dev/agent-workflows/roles) |
| Design a multi-step change | [Planning](/dev/agent-workflows/planning) |
| Split work and create commits | [Batches and commits](/dev/agent-workflows/batches) |
| Choose Standard, Yeet, Hotfix, or Release | [Delivery flows](/dev/agent-workflows/flows) |
| Start a common type of development task | [Change playbooks](/dev/agent-workflows/playbooks) |
| Transfer work without losing evidence | [Handoffs](/dev/agent-workflows/handoffs) |
| Execute a task reliably | [Checklists](/dev/agent-workflows/checklists) |

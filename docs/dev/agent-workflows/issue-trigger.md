# Issue trigger

`!issue` is a strict AI-agent command for starting work from one GitHub issue. It is a runtime policy, not a Git alias: an agent that receives the command must follow this page before changing files.

The command starts local work through verification and local batch commits. It does not silently push, create a pull request, merge, release, deploy, close an issue, or delete a remote branch.

## Command grammar

```text
!issue <number>
  [--workspace=auto|worktree|repo]
  [--goal=auto|on|off]
  [--mode=implement|plan]
  [--deliver=none|push|pr]
```

`#<number>` is accepted in place of `<number>`. Options may appear in any order, but each option may occur only once. Unknown, duplicate, malformed, or contradictory options are a hard stop: the agent reports the valid grammar and waits for a corrected command.

## Defaults

```text
!issue 123
```

is exactly equivalent to:

```text
!issue 123 --workspace=auto --goal=auto --mode=implement --deliver=none
```

The default intentionally performs no remote action. `--deliver=push` authorizes only a push of the resolved task branch. `--deliver=pr` authorizes that push and creation of one pull request for the same resolved branch; it does not authorize merge, release, deployment, or closing the issue.

## Required issue resolution

1. Run the universal Git preflight from [execution checklists](/dev/agent-workflows/checklists).
2. Use `gh issue view <number>` for the current repository to obtain the issue state, title, body, labels, assignees, and URL.
3. Stop if the issue cannot be resolved, is closed, belongs to a different repository, has no actionable scope, or conflicts with an explicit owner instruction.
4. Extract acceptance criteria, non-goals, risk markers, dependencies, and any explicit batch count. Missing acceptance criteria require Plan mode or owner clarification before implementation.

Use only `git` and `gh` for GitHub repository operations. Do not substitute an issue comment, status change, assignment, or label update for owner authorization.

## Workspace resolution

The workspace option decides where local implementation happens. It does not change the branch, batch, or delivery rules.

| Option | Required behavior |
| --- | --- |
| `worktree` | Create or resume an isolated Git worktree for the resolved task branch. This is preferred for concurrent work and for a dirty source checkout. |
| `repo` | Work in the normal codebase only when its worktree is clean, its branch can be safely created or resumed, and no other worktree has that branch checked out. |
| `auto` | Prefer `worktree`. Fall back to `repo` only when a worktree cannot be used and every `repo` safety condition passes. Record the fallback reason. |

Before creating a worktree, inspect `git worktree list` and existing local branches. Reuse a matching open issue branch only after confirming that its scope and uncommitted state belong to the same issue. Otherwise create a new branch from the updated `main`.

The branch name derives from the issue's verified type and title, for example `fix/123-reminder-timezone` or `docs/123-agent-guidance`. Use `hotfix/` only for a verified production incident. If no type can be inferred safely, use `feat/` only after the issue clearly requests a new user-facing capability; otherwise stop for owner direction.

## Goal resolution

Goal tracking and implementation are separate. Both modes use the same plan, batch, test, commit, and authorization rules.

| Option | Required behavior |
| --- | --- |
| `on` | Create and maintain a Goal for this issue. If the Goal facility cannot be used, stop; do not fall back. |
| `off` | Do not create or update a Goal. Maintain the issue execution record and batch ledger instead. |
| `auto` | Try Goal tracking first. Use Non-Goal mode only when Goal tracking is unavailable, unsupported, disallowed, or occupied by an incompatible active Goal. Record the reason. Unexpected Goal errors stop the workflow. |

In Goal mode, the Goal objective is a concise issue-level outcome. Keep batch detail in the plan or ledger rather than expanding the Goal beyond the Goal facility's limit. In Non-Goal mode, the exact same information is stored in the issue execution record and handoff.

## Flow and mode resolution

`--mode=plan` resolves the issue, workspace, Goal state, acceptance criteria, and a decision-ready implementation plan. It creates no implementation commit.

`--mode=implement` completes Plan, then runs Implement and Verify for every declared batch. Each completed batch gets exactly one local commit. An agent stops for re-planning when the issue grows beyond its accepted scope, a risk boundary changes, or evidence contradicts the issue assumptions.

Flow is selected after issue inspection:

| Evidence | Flow |
| --- | --- |
| Verified production incident | Hotfix |
| Owner explicitly requests Yeet and every Yeet condition passes | Yeet |
| Release request with explicit release authority | Release |
| All other actionable issues | Standard |

Yeet is never selected solely from a label, urgency, or issue title.

## Issue execution record

Before editing, print and maintain this record in the task plan or handoff:

```text
Issue: #123 — <title> — <URL>
Mode: Plan | Implement
Flow: Standard | Yeet | Hotfix | Release
Workspace: worktree | repo (with auto fallback reason when applicable)
Branch: <type>/<number>-<slug>
Goal: active <identifier> | non-goal <reason>
Scope: <included work>
Non-goals: <excluded work>
Acceptance: <observable criteria>
Batches: <number and outcome>
Validation: <focused and broader gates>
Delivery: none | push | pull request
```

The record is a progress and evidence ledger. It is not permission to perform an action not authorized by the parsed command or the owner.

## Completion and delivery

After the final local batch, run the broader validation required by the selected flow and report all unavailable gates. Then:

- `deliver=none`: hand off the branch, commits, evidence, and remaining authorized actions; do not contact GitHub.
- `deliver=push`: push only the resolved branch and report the confirmed remote ref.
- `deliver=pr`: push the resolved branch, create one PR, include `Fixes #<number>` only when the implemented acceptance criteria are met, and report the PR URL and checks.

Issue closure occurs only through the approved merge path or an explicitly authorized issue operation. After a PR is merged or closed, follow [remote branch cleanup](/dev/agent-workflows/flows#remote-branch-cleanup) to prune and safely delete its local branch.

## Fail-closed conditions

Stop and request direction instead of guessing when any of the following occurs:

- the issue state, repository, scope, or ownership cannot be verified;
- an option is invalid or conflicts with another option;
- `workspace=repo` is dirty or the target branch is active in another worktree;
- `workspace=auto` cannot use either safe workspace;
- Goal mode fails for a reason other than an allowed `auto` fallback;
- the issue lacks testable acceptance criteria and implementation would choose product behavior;
- delivery authorization, target branch, commit, or environment is ambiguous.

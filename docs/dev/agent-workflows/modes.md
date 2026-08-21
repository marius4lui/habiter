# Agent modes

A mode describes what an agent is doing *now*. A delivery flow describes how a change moves toward integration. Select a mode before acting, then select a flow only when the task will change or deliver work.

## Mode selector

| Mode | Use when the request asks to | Default write permission | Required outcome |
| --- | --- | --- | --- |
| Plan | design, scope, estimate, or sequence work | None | A decision-ready plan |
| Inspect | find, inventory, explain current state, or gather evidence | None | Facts with source locations |
| Diagnose | explain a failure or root cause | None | Reproduction, cause, and impact |
| Review | assess a change, pull request, or proposal | None | Prioritized findings or explicit approval |
| Implement | build, fix, refactor, or document an approved scope | Local repository only | Completed batches and local commits |
| Verify | test, validate, or QA an existing change | None, unless asked to fix | Pass/fail/blocked evidence |
| Deliver | push, open a PR, merge, release, or deploy | Only the exact authorized remote action | Confirmed remote result |
| Monitor | watch an external state, CI run, deployment, or scheduled outcome | None | Timestamped state and next condition |

An agent may move from one mode to the next only when the previous mode produced its required outcome. For example, Inspect may lead to Diagnose, then Plan, then Implement. A request to “fix it” starts with enough Inspect and Diagnose work to avoid guessing, but does not authorize Deliver.

## Plan

Use Plan when the owner needs a safe implementation path before code changes.

- Read relevant contracts and inspect enough current state to identify constraints.
- Define goal, non-goals, acceptance criteria, risks, validation, rollback, and batches.
- Identify decisions that need owner input instead of choosing a product, security, or delivery policy alone.
- Do not edit implementation files, create remote branches, push, or open a pull request.

Exit Plan only when the plan is specific enough that another implementer can execute it without rediscovering its boundaries.

## Inspect

Use Inspect for factual questions: where behavior lives, what is configured, which branches exist, or what a system currently returns.

- Prefer direct repository, runtime, test, and configuration evidence over assumptions.
- Record the source, command, path, version, or timestamp needed to make each finding reproducible.
- Preserve the worktree; inspection does not justify formatting, dependency updates, or “small fixes”.
- Distinguish observed facts from reasonable inferences.

Exit Inspect with a concise inventory or evidence-backed answer. Move to Diagnose if the question is why something fails.

## Diagnose

Use Diagnose to identify why a known symptom occurs.

1. State the symptom, affected scope, and expected behavior.
2. Reproduce it with the smallest safe case or explain why reproduction is unavailable.
3. Trace the path from trigger to failure and identify the causal defect, not only a correlated location.
4. State impact, confidence, and the smallest safe remediation direction.

Do not implement a fix in Diagnose mode unless the request also explicitly asks for one. Exit with a root-cause report or a clearly marked inconclusive result.

## Review

Use Review to evaluate code, a plan, a pull request, configuration, or release evidence independently.

- Read the intended behavior first, then inspect the change and its tests.
- Report only actionable findings: severity, location, evidence, impact, and a concrete remediation direction.
- Call out missing validation, migration safety, authorization gaps, and untracked generated changes.
- If no blocking issue exists, say what was reviewed and what remains unverified; “looks good” alone is not a review.

Review is read-only unless the owner asks the reviewer to apply a specific correction after reporting it.

## Implement

Use Implement only for explicitly requested local changes.

- Complete the preflight, choose a flow, and create or use the scoped branch.
- Follow the approved plan or write the smallest required task declaration.
- Finish one batch at a time: change, focused validation, diff review, and one local commit.
- Stop and replan when scope, data compatibility, risk, or batch size exceeds the declared boundary.

Implement permits local commits. It does not permit pushing, opening a pull request, merging, releasing, deploying, deleting remote resources, or changing credentials.

## Verify

Use Verify to prove a local or remote change meets its declared acceptance criteria.

- Select the smallest valid focused gate and every broader gate required for the target stage.
- Record command, environment or target, result, and any relevant artifact.
- Separate passing, failing, skipped, and blocked checks. Never turn a blocked check into a pass.
- If verification reveals a defect, return to Diagnose or Implement with a new scoped batch.

Verify changes no files unless the owner explicitly asks to fix findings.

## Deliver

Use Deliver only after the owner explicitly authorizes the exact remote action.

| Authorized action | Deliver may do |
| --- | --- |
| Push | Push the named branch and confirm its remote ref |
| Pull request | Push if also authorized, create the named PR, and report its URL and checks |
| Merge | Merge only the named, approved PR by the approved method |
| Release or deploy | Follow the dedicated runbook and report operator evidence |

Deliver never expands authorization. A requested push does not authorize a PR; a PR does not authorize a merge; a merge does not authorize a release or deploy.

## Monitor

Use Monitor when a task asks to wait for CI, a deployment, an external integration, or a scheduled condition.

- State the target, success condition, timeout or follow-up point, and whether an action is allowed on failure.
- Read state without changing it unless a separately authorized remediation is provided.
- Report meaningful state transitions rather than repeating unchanged status.
- Stop monitoring when the success condition, failure condition, timeout, or owner cancellation occurs.

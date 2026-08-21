# Delivery flows

Choose the smallest flow that preserves safety, reviewability, and the owner's authorization boundaries. Every flow starts with the [required preflight](/dev/agent-workflows/) and follows the [branch workflow](/dev/branches).

## Flow selection

| Flow | Use when | Delivery shape |
| --- | --- | --- |
| Plan | The requested result is analysis, design, or a plan | Read-only unless the owner requests a plan document |
| Standard | Default for normal product, infrastructure, and documentation work | Branch, planned batches, local commits, validation, then only authorized remote actions |
| Yeet | A small, urgent, low-risk correction needs a fast review path | One branch, one batch, one local commit, focused regression evidence; push and PR only if explicitly authorized |
| Hotfix | A production incident needs containment and a tracked correction | `hotfix/` branch, impact assessment, regression evidence, limited batches, PR or explicitly authorized direct-main push |
| Release | A version or production delivery is requested | Follow [release operations](/release-operations); never implied by another flow |

## Standard flow

1. Inspect the worktree, fetch/prune tags and branches, and update `main` with a fast-forward-only pull.
2. Create a purpose-named branch from the updated base.
3. Declare scope, acceptance, batch count, validation, and requested remote actions.
4. Complete each batch: implement, run focused checks, review the diff, and create one local commit.
5. Run the agreed broader merge gate and report unavailable gates.
6. Push and open a pull request only when the owner explicitly authorized each action.
7. Integrate through a pull-request merge unless the owner gave exact confirmation for a direct push to `main`.

## Yeet flow

Yeet is a speed limit, not a safety bypass. It is allowed only when all of these are true:

- one isolated, backwards-compatible correction;
- no schema or data migration, dependency change, secret, access-control change, release, or deployment;
- one batch and one local commit;
- a focused regression check proves the correction;
- the owner explicitly authorizes any push and pull request.

If any condition is false, use Standard or Hotfix instead. A request that says only “use Yeet” authorizes neither push nor PR.

## Hotfix flow

1. Record user impact, affected version or environment, and a minimal reproduction.
2. Create a `hotfix/<short-description>` branch from the current approved production base.
3. Apply the smallest safe correction with a regression test.
4. Use one to three batches unless the owner explicitly approves a broader plan.
5. Deliver by pull request, or by a direct push to `main` only after the owner gives exact confirmation for that push.
6. Release or deploy only through an independently authorized Release flow.

## The only two paths to `main`

1. **Pull-request path:** an approved branch is merged through a pull request.
2. **Exceptional direct-push path:** the owner gives exact, task-specific confirmation to push the named commit or branch directly to `main`.

No agent may invent a third path: no direct merge, force-push, rebased history replacement, or “urgent” bypass. A successful push to any other branch is not integration, release, or deployment.

## Remote branch cleanup

After a pull request is merged or closed without merge, remove the remote branch only when the owner or repository policy allows it. Then synchronize and remove the matching local branch:

```bash
git fetch --all --prune --tags
git branch -vv
git worktree list
git branch -d <branch>
```

Use `git branch -D <branch>` only after verifying that the branch is abandoned, its pull request is closed, and it is not checked out in any worktree. Never delete the current branch, an active branch, or a branch that may contain unmerged work.

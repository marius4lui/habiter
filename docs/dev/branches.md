# Branch workflow

Branches are named after the work they contain, never after the person, coding agent, or tool that creates them.

This page owns branch names and lifecycle mechanics. Read [agent workflows](/dev/agent-workflows/) for required preflight, authorization, batch commits, the two allowed paths to `main`, and remote-branch cleanup.

## Create a branch

Start from an up-to-date `main` and use `<type>/<short-description>`:

```bash
git switch main
git pull --ff-only
git switch -c feat/weekly-overview
```

| Type | Purpose | Example |
| --- | --- | --- |
| `feat` | User-facing functionality | `feat/weekly-overview` |
| `fix` | Bug fix | `fix/reminder-timezone` |
| `docs` | Documentation only | `docs/vitepress-refresh` |
| `refactor` | Internal restructuring | `refactor/reminder-scheduler` |
| `test` | Test-only work | `test/release-api-errors` |
| `chore` | Maintenance/dependencies | `chore/update-flutter` |
| `ci` | CI automation | `ci/cache-flutter-sdk` |
| `build` | Build or packaging | `build/linux-package` |
| `perf` | Performance work | `perf/habit-list-rendering` |
| `release` | Release preparation | `release/1-4-0` |
| `hotfix` | Urgent production correction | `hotfix/download-redirect` |

Use lowercase kebab-case. With an issue identifier, use a name such as `fix/HAB-123-reminder-timezone`.

## Forbidden names

Never add creator, assistant, vendor, or username prefixes:

```text
codex/feat/dynamic-reminders   # invalid
claude/fix/reminders           # invalid
ai/update-docs                 # invalid
marius/new-feature             # invalid
feat/dynamic-reminders         # valid
```

Avoid vague names including `changes`, `work`, `test`, `new-feature`, or `final-fix-2`.

## Maintain and finish

- Keep one coherent concern per branch.
- Commit logical, reviewable steps.
- Before a new task, inspect status, run `git fetch --all --prune --tags`, update `main` with `git pull --ff-only origin main`, then create the task branch from that base.
- Bring current `main` into an existing branch only under the pull request merge policy or with explicit owner direction; do not perform a hidden merge or rebase.
- Avoid renaming a published branch; coordinate it if necessary.
- After a remote branch is deleted, prune and delete its matching local branch after confirming it is not current, checked out elsewhere, or still needed.

Check the current name with `git branch --show-current`. Rename an unpublished branch with `git branch -m docs/descriptive-name`.

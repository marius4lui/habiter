# Branch workflow

Branches are named after the work they contain, never after the person, coding agent, or tool that creates them.

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
- Bring in current `main` according to the pull request merge policy.
- Avoid renaming a published branch; coordinate it if necessary.
- Delete local and remote branches after merge.

Check the current name with `git branch --show-current`. Rename an unpublished branch with `git branch -m docs/descriptive-name`.

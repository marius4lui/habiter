# Repository instructions

## Branches

- Create a dedicated branch for each coherent change before editing files, unless the work is already taking place on a suitable branch.
- Name branches after the purpose of the change, using `<type>/<short-description>`.
- Allowed types are `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `ci`, `build`, `perf`, `release`, and `hotfix`.
- Use lowercase kebab-case and keep names short, specific, and free of contributor or tool names.
- Never add an agent, assistant, vendor, or personal prefix. Do not create `codex/...`, `claude/...`, `ai/...`, or `<username>/...` branches.
- Good examples are `feat/dynamic-reminders`, `fix/reminder-timezone`, `docs/branch-workflow`, and `chore/update-flutter`.
- Keep one concern per branch, update it from `main` when needed, and delete it after merge.

See `docs/dev/branches.md` for the complete workflow.

# GitHub Actions

The repository intentionally has five workflows:

- `quality.yml`: all quality gates on every push and pull request.
- `platform-builds.yml`: path-filtered platform compilation.
- `worker-deploy.yml`: production Release API deployment from `main`.
- `worker-preview.yml`: isolated Worker previews for same-repository pull requests.
- `release.yml`: signed Android and desktop release pipeline for SemVer tags.

Direct pushes to `main` are allowed. Application publication still requires an explicit `v<major>.<minor>.<patch>` tag. Worker previews never use production data or the production environment.

Required repository secrets and variables are documented in `docs/release-operations.md`.

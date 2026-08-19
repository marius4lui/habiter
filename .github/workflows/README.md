# GitHub Actions

The repository intentionally has seven workflows:

- `quality.yml`: all quality gates on every push and pull request.
- `platform-builds.yml`: path-filtered platform compilation.
- `worker-deploy.yml`: production Release API deployment from `main`.
- `worker-preview.yml`: native versioned Worker previews for same-repository pull requests.
- `release.yml`: signed Android and desktop release pipeline for SemVer tags.
- `installer.yml`: path-filtered shell, PowerShell, distro-container, resolver, metadata, and installation-doc contract tests.
- `docs-deploy.yml`: builds and deploys VitePress to GitHub Pages on documentation changes to `main`, with manual dispatch support.

Direct pushes to `main` are allowed. Application publication still requires an explicit `v<major>.<minor>.<patch>` tag. Worker previews upload aliased versions to the shared `habiter-release-api-preview` Worker and never use production data or the production environment.

Required repository secrets and variables are documented in `docs/release-operations.md`.

# GitHub Actions

The repository intentionally has eight workflows:

- `quality.yml`: all quality gates on every push and pull request.
- `platform-builds.yml`: path-filtered platform compilation.
- `worker-deploy.yml`: production Release API deployment from `main`.
- `worker-preview.yml`: native versioned Worker previews for same-repository pull requests.
- `website-deploy.yml`: static website deployment to the `habiterdev` production Worker from `main`.
- `release.yml`: signed Android and desktop release pipeline for SemVer tags.
- `installer.yml`: path-filtered shell, PowerShell, distro-container, resolver, metadata, and installation-doc contract tests.
- `docs-deploy.yml`: builds and deploys VitePress to GitHub Pages on documentation changes to `main`, with manual dispatch support.
- `sync-docker.yml`: path-filtered Personal Sync Docker Beta image hardening and full setup/replacement/backup/restore/rollback lifecycle drill; it never publishes the image.

Direct pushes to `main` are allowed. Application publication still requires an explicit `v<major>.<minor>.<patch>` tag. Worker previews upload aliased versions to the shared `habiter-release-api-preview` Worker and never use production data or the production environment.

Required repository secrets and variables are documented in `docs/release-operations.md`. Public routes and response schemas are documented in `docs/api/release-api.md`; local and CI commands are mapped in `docs/dev/testing.md`.

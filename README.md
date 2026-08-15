# Habiter

Habiter is a local-first habit application with a static product website and a versioned release API. The repository is a single monorepo and starts its new public product line at `1.0.0`.

## Repository

```text
apps/habiter       Flutter application and platform projects
apps/website       Standalone product page
apps/release-api   Cloudflare Worker for releases, updates and downloads
packages/release-core
                    Release manifest, schema and deterministic tooling
docs                Product and engineering documentation
```

## Development

Flutter commands run from `apps/habiter`:

```bash
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test
```

Workspace commands run from the repository root:

```bash
pnpm install --frozen-lockfile
pnpm release:validate
pnpm release:test
pnpm website:check
pnpm --filter @habiter/release-api types
pnpm --filter @habiter/release-api check
pnpm --filter @habiter/release-api deploy:dry
```

## Releases

`packages/release-core/data/releases.json` is the human-reviewed source of truth. A tag is accepted only when its SemVer, Flutter version, build number and release entry agree. Normal pushes never publish application releases.

The first new line is `1.0.0+10000`. Android release builds fail unless valid signing material is present. Windows, Linux and macOS bundles carry checksums but are not code-signed in v1.

Operational release, signing, recovery and rollback instructions are in [docs/release-operations.md](docs/release-operations.md).

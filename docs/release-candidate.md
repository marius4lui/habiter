# Habiter 1A release-candidate evidence

This document records reproducible release-candidate gates. It is not a release announcement and authorizes no deployment or publication.

## Required gates

| Area | Commands | Environment note |
|---|---|---|
| Flutter | `dart format --output=none --set-exit-if-changed .`, `flutter analyze --fatal-infos`, `flutter test --coverage` | Flutter 3.44.8 in CI |
| Platforms | Android, web, Linux, macOS, Windows, unsigned iOS release builds | GitHub matrix runners |
| Landing | frozen install, lint, TypeScript, `pnpm test`, production build | Node 24 / pnpm 11 |
| Docs | `npm ci`, `npm run docs:build` | Node 24 |
| Security | Gitleaks plus explicit secret/reference scans | full Git history in CI |

## Manual device gates

- Verify reminder delivery and actions when foregrounded, backgrounded, and terminated across a DST boundary.
- Verify Android App Lock permission denial, service restart, midnight recovery, and battery-policy messaging on a physical device.
- Verify Classly-compatible OAuth against a trusted public HTTPS test server supporting PKCE.
- Confirm import preview, collision choice, backup creation, cancellation, and recovery from a deliberately corrupt file.

Any unavailable or failing gate remains a release blocker and must be reported in the pull request rather than waived silently.

# Habiter v1.6 Distribution and Installers Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Deliver Issue #22 as a repository-backed, checksum-verified, user-scoped desktop installation system with tested release resolution, smart routing, packaging, CI, and maintained platform documentation.

**Architecture:** The release manifest remains the source of artifact identity and gains explicit artifact format/primary fields. The Release API centralizes artifact selection in an installer resolver, proxies only two allow-listed scripts from the repository, and routes browsers to explicit installation guidance. POSIX shell and PowerShell clients validate resolver data before downloading, verify SHA-256, stage changes in temporary paths, then replace user-scoped installations. Release workflows produce deterministic desktop payloads and installer CI exercises scripts, API routes, distro fixtures, and documentation.

**Tech Stack:** Flutter desktop, POSIX shell, PowerShell 7/Windows PowerShell, TypeScript/Cloudflare Workers, Node test runner, GitHub Actions, VitePress.

---

### Task 1: Record scope and batch contract

**Files:**
- Create: `docs/plans/2026-08-19-v1-6-distribution-installers.md`

**Steps:**
1. Capture the Issue #22 architecture, exact implementation files, verification commands, and commit boundaries.
2. Verify the plan references at least ten substantive batches.
3. Commit as `docs(plan): define v1.6 installer delivery`.

### Task 2: Extend release artifact identity

**Files:**
- Modify: `packages/release-core/schema/releases.schema.json`
- Modify: `packages/release-core/src/release-manifest.mjs`
- Modify: `packages/release-core/test/release-manifest.test.mjs`
- Modify: `packages/release-core/data/releases.json`

**Steps:**
1. Add backwards-compatible `format` and `primary` artifact fields with strict allowed values.
2. Make ambiguous primary install artifacts fail validation.
3. Migrate checked-in desktop artifacts explicitly.
4. Run `pnpm release:test` and `pnpm release:validate`.
5. Commit as `feat(release): identify installer artifacts explicitly`.

### Task 3: Add the installation resolver

**Files:**
- Modify: `apps/release-api/src/types/releases.ts`
- Modify: `apps/release-api/src/services/platform.ts`
- Modify: `apps/release-api/src/services/release-service.ts`
- Modify: `apps/release-api/src/router.ts`
- Modify: `apps/release-api/test/router.test.ts`

**Steps:**
1. Add strict platform, architecture, distro, channel, and optional version parsing.
2. Resolve exactly one primary artifact by explicit format/role rather than array order.
3. Return artifact checksum, size, URL, format, version, and docs URL.
4. Test stable/beta, normalization, distro fallback, missing and ambiguous artifacts.
5. Run `pnpm --filter @habiter/release-api check`.
6. Commit as `feat(api): add desktop install resolver`.

### Task 4: Redesign smart download routing

**Files:**
- Modify: `apps/release-api/src/services/platform.ts`
- Modify: `apps/release-api/src/router.ts`
- Modify: `apps/release-api/test/router.test.ts`

**Steps:**
1. Give explicit platform and distro query parameters precedence over User-Agent detection.
2. Route desktop browsers to platform/distro documentation and retain Android direct downloads.
3. Fall back unknown Linux distros and platforms to safe documentation pages.
4. Test every Issue #22 routing case and strict channels.
5. Commit as `feat(api): route smart downloads to install guides`.

### Task 5: Proxy repository-backed installer scripts

**Files:**
- Create: `apps/release-api/src/services/installer-source.ts`
- Modify: `apps/release-api/src/router.ts`
- Modify: `apps/release-api/test/router.test.ts`

**Steps:**
1. Allow-list only `/install.sh` and `/install.ps1` to fixed raw repository paths.
2. Fail closed on non-OK, HTML, or invalid upstream responses.
3. Emit explicit MIME, cache, ETag, nosniff, and source headers.
4. Test upstream success/failure and open-proxy resistance.
5. Commit as `feat(api): serve allow-listed repository installers`.

### Task 6: Implement and test the POSIX installer

**Files:**
- Create: `scripts/install/install.sh`
- Create: `scripts/install/test/install-sh.test.sh`
- Create: `scripts/install/test/os-release/{ubuntu,debian,fedora,arch,opensuse,generic}`

**Steps:**
1. Implement strict argument parsing, TTY/NO_COLOR output, cleanup, OS/architecture/distro normalization, and resolver validation.
2. Add checksum-verified staged AppImage and macOS app installation with user-scoped defaults, dry-run, idempotent replacement, and desktop integration.
3. Test flags, normalization, unsupported architectures, network/checksum failure, and mutation-free dry-run using local fixtures/mocks.
4. Run `sh -n scripts/install/install.sh` and `sh scripts/install/test/install-sh.test.sh`.
5. Commit as `feat(installer): add verified Unix desktop installer`.

### Task 7: Implement and test the PowerShell installer

**Files:**
- Create: `scripts/install/install.ps1`
- Create: `scripts/install/test/install-ps1.test.ps1`

**Steps:**
1. Implement architecture detection, strict resolver validation, HTTPS download, SHA-256 verification, staged ZIP extraction, and atomic user-scoped replacement.
2. Add deterministic Start Menu integration, optional CLI command, dry-run, verbose output, and cleanup.
3. Test resolver errors, checksum mismatch, extraction, paths, repeat install, Start Menu, and dry-run with mocks/test hooks.
4. Run `pwsh -NoProfile -File scripts/install/test/install-ps1.test.ps1`.
5. Commit as `feat(installer): add verified Windows installer`.

### Task 8: Establish Linux application identity and AppImage packaging

**Files:**
- Modify: `apps/habiter/linux/CMakeLists.txt`
- Modify: `apps/habiter/linux/runner/my_application.cc`
- Create: `packaging/linux/dev.habiter.Habiter.desktop`
- Create: `packaging/linux/dev.habiter.Habiter.appdata.xml`
- Create: `scripts/release/package-linux-appimage.sh`

**Steps:**
1. Replace the placeholder application ID with `dev.habiter.Habiter` consistently.
2. Assemble an AppDir from the complete Flutter bundle and checked-in desktop metadata.
3. Produce a deterministic x64 AppImage name while retaining the advanced tar bundle.
4. Add shell validation for expected metadata and bundle contents.
5. Commit as `build(linux): package Habiter as an AppImage`.

### Task 9: Integrate deterministic desktop artifacts into releases

**Files:**
- Modify: `.github/workflows/release.yml`
- Modify: `scripts/release/enrich-artifacts.mjs`
- Modify: `scripts/release/validate.mjs`
- Modify: related release-core tests

**Steps:**
1. Package AppImage, Linux bundle, Windows bundle, and macOS app archive with stable names.
2. Require format, URL, SHA-256, and size before installable publication.
3. Make installer/resolver smoke tests stable-release blockers.
4. Run release validation/tests and workflow contract tests.
5. Commit as `ci(release): publish deterministic installer artifacts`.

### Task 10: Add installer CI and fixtures

**Files:**
- Create: `.github/workflows/installer.yml`
- Modify: `apps/habiter/test/ci_workflow_test.dart`
- Create or modify: installer validation helpers under `scripts/install/test/`

**Steps:**
1. Add shellcheck/syntax/unit jobs, a five-distro container matrix, macOS dry-run tests, PowerShell tests, API checks, and docs validation.
2. Limit triggers to installer-contract paths and make failures review-blocking.
3. Validate workflow structure locally and run available script tests.
4. Commit as `ci(installer): validate supported desktop installs`.

### Task 11: Add installation information architecture

**Files:**
- Create: `docs/install/README.md`
- Create: `docs/install/linux/README.md`
- Modify: `docs/.vitepress/config.mts`
- Modify: `docs/guide/getting-started.md`

**Steps:**
1. Add platform and distro chooser landing pages usable on GitHub and VitePress.
2. Add first-class Installation navigation/sidebar entries.
3. Reduce Getting Started to a concise quick start linking canonical guides.
4. Run `npm --prefix docs run docs:build`.
5. Commit as `docs(install): add installation guide structure`.

### Task 12: Document Ubuntu and Debian installs

**Files:**
- Create: `docs/install/linux/ubuntu.md`
- Create: `docs/install/linux/debian.md`

**Steps:**
1. Document separately verified dependencies, AppImage/FUSE, GTK, Wayland/X11, keyring, update, uninstall, and safe diagnostics.
2. Avoid stale fixed release versions and security-bypass advice.
3. Build documentation and validate internal links.
4. Commit as `docs(linux): document Ubuntu and Debian installs`.

### Task 13: Document Fedora, Arch, openSUSE, and generic Linux

**Files:**
- Create: `docs/install/linux/fedora.md`
- Create: `docs/install/linux/arch.md`
- Create: `docs/install/linux/opensuse.md`
- Create: `docs/install/linux/generic.md`

**Steps:**
1. Add genuine distro-specific package, FUSE, SELinux/rolling-release, display, keyring, library, and diagnostics guidance.
2. Mark tested and community coverage honestly.
3. Build documentation and validate the chooser links.
4. Commit as `docs(linux): add distro-specific install guides`.

### Task 14: Document Windows and macOS installs

**Files:**
- Create: `docs/install/windows.md`
- Create: `docs/install/macos.md`

**Steps:**
1. Document recommended and manual checksum-verified installation, updates, complete uninstall, signing status, and safe diagnostics.
2. Do not recommend global execution-policy weakening, Gatekeeper bypass, or quarantine removal.
3. Build documentation.
4. Commit as `docs(desktop): document Windows and macOS installs`.

### Task 15: Finish operations, quality gates, and review handoff

**Files:**
- Modify: `docs/release-operations.md`
- Modify: `.github/workflows/README.md`
- Modify: `README.md`
- Modify as needed: roadmap/generated documentation only through `pnpm roadmap:sync`

**Steps:**
1. Document installer source-of-truth, cache/revalidation, smoke tests, release blocking, and rollback.
2. Run script tests, Release API checks, release validation/tests, roadmap check, docs build, Flutter static tests relevant to workflow contracts, `git diff --check`, and secret scan where locally available.
3. Verify at least ten commits, a clean worktree, and the diff against `origin/main`.
4. Commit as `docs(release): add installer operations runbook`.
5. Fetch and pull once more, push `feat/v1-6`, open a non-draft PR closing #22, and request review readiness without merging, releasing, or deploying.

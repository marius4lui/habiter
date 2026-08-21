# Change playbooks

These playbooks select the usual mode, flow, separation, and evidence for common work. Follow the more specific product, platform, security, or release contract when one exists.

## Documentation change

Start in Inspect, then Implement with the Standard flow. Keep a documentation change focused on one audience or contract. Update navigation and cross-links in the same batch, validate with `npm run docs:check`, and do not publish workstation details, secrets, or temporary agent transcripts. See [documentation development](/dev/documentation).

## Isolated bug fix

Inspect and Diagnose first, then use Standard. Use Yeet only when the correction is isolated, backwards compatible, covered by one focused regression check, and meets every Yeet condition. Keep the fix and regression test in one batch; do not combine opportunistic cleanup. See [delivery flows](/dev/agent-workflows/flows).

## Feature

Plan before Implement. Identify the user outcome, data and state ownership, accessibility, localization, persistence or migration needs, and acceptance tests. Split domain/application, presentation, platform, and operational changes into batches when they can be independently reviewed. Use the relevant [architecture](/dev/architecture), [state](/dev/state), and [testing](/dev/testing) contracts.

## Refactor

Inspect current behavior and establish a characterization test when coverage is missing. Keep the refactor behavior-preserving; a behavior change needs a separate declared batch. Do not mix formatting, dependency updates, and unrelated cleanup into the refactor. Verify the affected test boundary and the required broader gate.

## Dependency or toolchain update

Inspect the pinned source of truth and lockfile ownership first. Plan compatibility, generated-file effects, rollback, CI impact, and the exact validation matrix. Keep dependency metadata and required lockfile changes together, but separate unrelated application changes. Never regenerate or rewrite a lockfile merely because a different local tool does so.

## Data, API, or schema migration

Plan first and use Standard unless an active incident requires Hotfix. Document existing-data compatibility, rollout order, backwards and forwards behavior, verification, and rollback before editing. Separate preparation, compatibility code, migration execution, and destructive cleanup whenever each can be independently reviewed or rolled back. A migration is never eligible for Yeet.

## Security or access-control change

Start with Inspect and Diagnose, then write a risk-aware plan. Define the asset, trust boundary, exploit path, affected users, fail-safe behavior, test evidence, and rollback. Do not expose secrets or reduce a control merely to make a test pass. Security work is never eligible for Yeet and remote or credential actions always need separate authorization.

## Production incident

Use Hotfix: capture impact and reproduction, branch from the approved production base, make the smallest safe fix, add regression evidence, and keep the fix to one to three batches unless the owner approves more. Deliver through a PR or a specifically authorized direct push to `main`; release and deployment remain separate actions.

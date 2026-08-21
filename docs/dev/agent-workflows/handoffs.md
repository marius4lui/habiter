# Handoffs and evidence

A handoff lets another person or agent continue safely without reconstructing hidden context. It is required when ownership changes, work pauses, a review begins, or a delivery action is requested.

## Handoff template

```md
## Status

- Mode and flow:
- Scope completed:
- Scope intentionally not started:
- Current branch and local commit:

## Evidence

- Focused checks:
- Broader checks:
- Blocked or unavailable checks:

## Decisions and risks

- Source of truth:
- Compatibility or rollback notes:
- Owner decisions still needed:

## Next action

- Exact next batch or authorized delivery action:
- Remote authorization: none | push | PR | merge | release | deploy
```

## Evidence quality

Evidence names what was run, against which target, and what happened. It does not replace missing evidence with confidence.

| Weak handoff | Useful handoff |
| --- | --- |
| “Tests pass.” | “`flutter test test/features/foo_test.dart` passed; full suite not run because the task is still in batch 2.” |
| “Ready to ship.” | “Branch has commit `abc123`; PR creation is requested but not authorized yet.” |
| “Investigated the issue.” | “Reproduced with input X; the null value reaches Y at line Z; no fix applied in Diagnose mode.” |

## Review handoff

A reviewer receives the intended behavior, changed areas, tests run, known limitations, and any migration or security considerations. The reviewer returns findings with severity, location, evidence, impact, and a concrete requested correction.

## Delivery handoff

Before a push, PR, merge, release, or deploy, repeat the exact authorized action, branch or commit, target environment, and required checks. The delivery operator must stop if any of these differ from the owner authorization.

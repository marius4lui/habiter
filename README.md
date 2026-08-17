<div align="center">

<img src="apps/website/logo.png" width="128" alt="Habiter logo" />

# Habiter

**Build better habits. Keep your data yours.**

A polished, local-first habit tracker for mobile, desktop, and web — built with Flutter and shipped through a signed, reproducible release pipeline.

</div>

---

## Roadmap

This roadmap shows the released baseline and the next planned product milestones.

### Released

**v1.4.0 — Dynamic notifications**

- Local smart timing and calibration.
- Explainable reminder behavior.
- Dynamic reminder experience.

### Upcoming

**v1.4.1 — Completion UI stability**

- Fix completion-state layout issues.

**v1.4.2 — Widget/App lifecycle reliability**

- Improve state synchronization between app, widgets and background actions.

**v1.5.0 — Automatic updates**

- Add the client update experience on top of the existing Release API.

**v1.6.0 — Habit Experience v3**

- Improve habit schedule understanding.
- Improve onboarding navigation.
- Align reminder creation flows.

**v1.7.0 — Persistent Habiter Runtime**

- Introduce a shared background runtime for adaptive reminders and future focus features.

**v1.8.0 — App Block 2.0**

- Add local distraction discovery and habit-based app blocking.

The detailed engineering roadmap is maintained in [`ROADMAP.md`](ROADMAP.md).

---

## Repository

```text
habiter/
├── apps/
├── packages/
├── scripts/
├── docs/
└── .github/workflows/
```

The release manifest in `packages/release-core/data/releases.json` remains the source of truth for published releases.

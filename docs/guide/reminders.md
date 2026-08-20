# Reminders

Habiter schedules reminders locally from each habit's rhythm, your global limits, and the device time zone. Reminder planning does not upload habit names, completion history, or learning signals.

## Choose a reminder mode

Open a habit, edit it, and continue to the reminder step. Three modes are available:

- **Smart** proposes useful windows and can adapt from local availability feedback.
- **Random within a window** chooses deterministic times inside the window you define.
- **Fixed times** uses the exact wall-clock times you select, subject to operating-system delivery.

The habit schedule remains authoritative. A reminder can help with timing, but it never changes which days count toward the habit.

## Global guardrails

Open **Rhythm** to review reminder-wide settings. Habiter applies these constraints before scheduling any notification:

- active hours and quiet periods;
- a daily notification limit;
- minimum spacing between notifications;
- the habit's daily, weekday, or weekly-frequency schedule;
- completed, paused, archived, and deleted state;
- the device's current time zone.

When several reminders compete for the same time, the planner ranks candidates and keeps only those that satisfy every guardrail. Pending notifications are reconciled after schedule edits, lifecycle changes, completion, app resume, and time-zone changes.

## Smart timing and calibration

Smart timing starts with category-based defaults. You can optionally run a seven-day calibration that asks whether broad time windows are feasible.

- Calibration asks at most once per two-hour window.
- Ignored and dismissed prompts are neutral; they are not treated as negative feedback.
- Explicit feedback and completion timing influence local availability profiles.
- Raw learning signals expire after 180 days.
- Aggregated profiles remain on the device until reminder data is reset or application data is deleted.

The Rhythm screen explains whether a suggested window comes from learned, personal, or fallback information. Habiter does not use network, location, contacts, calendar, microphone, or sensor data for reminder learning.

## Permissions and delivery

Android and iOS require notification permission. Habiter asks through an explicit user action and does not repeatedly prompt after denial. You can reopen the operating-system notification settings from the app.

Habiter uses inexact scheduling by default and does not require Android's exact-alarm permission. Delivery time is best effort: battery policy, focus modes, device restarts, and manufacturer scheduling can delay or suppress a notification.

::: warning Delivery is not an alarm-clock guarantee
The planned time is the target, not a promise of exact delivery. Use the device's alarm or calendar tools for safety-critical timing.
:::

## Notification actions

Supported reminders can expose completion, snooze, and feasibility actions. Incoming actions are written to a durable local inbox before processing, so retries from foreground, background, or terminated states remain idempotent.

Habiter assigns stable notification IDs and removes obsolete pending notifications during reconciliation. Diagnostics show safe identifiers and known delivery times without displaying habit descriptions, action payloads, credentials, or learning signals.

## Troubleshooting

If a reminder does not arrive:

1. Confirm notification permission in **Rhythm** and in system settings.
2. Check active hours, quiet periods, the daily limit, and the habit's schedule.
3. Confirm the habit is active and incomplete for the relevant date.
4. Open Habiter after changing time zone, date, or notification settings so reconciliation can run.
5. Review reminder diagnostics for permission and pending-schedule status.
6. Check operating-system battery or focus restrictions.

Resetting reminder learning clears adaptive profiles and calibration state without deleting habits or completion history. For engineering verification, see the [Reminder QA matrix](/reminder-qa).

# Reminder QA

Habiter schedules reminders in the device time zone and uses inexact Android
alarms by default. The diagnostics panel shows notification permission, safe
notification IDs, and known delivery times without exposing payloads or habit
descriptions.

## Automated contracts

- Stable persisted notification IDs and duplicate reconciliation.
- Daily, weekday, and times-per-week planning with a 64-item capacity.
- Berlin, New York, and Kolkata timezone rules, including DST gaps/overlaps.
- Permission states without repeated prompts; exact alarms are not required.
- Durable, idempotent foreground/background/terminated action inbox.
- Redacted diagnostics that never display action payloads or credentials.

## Manual device gates

- Android 13–16: permission dialog, reboot, timezone change, battery saver,
  background and killed-process actions, and representative OEM policies.
- iOS: permission dialog, pending-limit behavior, DST transition, background and
  terminated actions on physical hardware.
- Delivery time remains subject to operating-system scheduling and power policy;
  the app does not claim exact delivery or universal OEM reliability.

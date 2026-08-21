# Reminder QA

Habiter schedules reminders in the device time zone. Fixed and random reminders
use inexact Android notification scheduling. Smart reminders are re-evaluated
locally by the shared foreground runtime immediately before dispatch. Its
targeted one-shot recovery wake uses the best alarm mode currently available;
exact-alarm access is not required. The Settings diagnostics panel shows
notification permission, safe notification IDs, feature state, and persisted
runtime timestamps without exposing payloads or habit descriptions.

## Automated contracts

- Stable persisted notification IDs and duplicate reconciliation.
- Daily, weekday, and times-per-week planning; the 64-item capacity applies to
  platform-scheduled fixed/random reminders, not to a long-horizon Smart queue.
- Smart completion before an expected delivery invalidates the candidate, and
  the runtime materializes at most the next eligible Smart notification.
- Independent reminder/App Block state across all four on/off combinations.
- Targeted recovery reconstruction after reboot and package replacement.
- Berlin, New York, and Kolkata timezone rules, including DST gaps/overlaps.
- Permission states without repeated prompts; exact alarms are not required.
- Durable, idempotent foreground/background/terminated action inbox.
- Redacted diagnostics that never display action payloads or credentials.

## Manual device gates

- Android 13–16: permission dialog, reboot, timezone change, battery saver,
  background and killed-process actions, reminder-only/App-Block-only/both/off
  transitions, and representative OEM policies.
- iOS: permission dialog, pending-limit behavior, DST transition, background and
  terminated actions on physical hardware.
- Delivery time remains subject to operating-system scheduling and power policy;
  the app does not claim exact delivery or universal OEM reliability.

User behavior, permission guidance, privacy, and troubleshooting are documented in [Reminders](/guide/reminders). The native time-zone and settings methods are documented in [Platform-channel contracts](/dev/platform-contracts).

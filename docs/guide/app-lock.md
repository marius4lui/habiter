# App Lock

App Lock can temporarily block selected Android apps until the configured habit requirement is met.

::: warning Android only
App Lock is unavailable on iOS, desktop, and web. Android manufacturer behavior varies, so test recovery on the actual device.
:::

## Setup

1. Go to **Settings → App Lock**.
2. Grant the required permissions:
   - **Usage Access** detects which app is in the foreground.
   - **Display over other apps** shows the blocking screen.
3. Select installed launcher apps to restrict.
4. Choose whether all habits scheduled today or only selected habits are required.
5. Enable App Lock and confirm Habiter's neutral persistent background notification.

## How it works

When a selected app opens before the requirement is complete, Habiter presents its lock screen. Completing the configured habits unlocks those apps for the current day. App Lock and adaptive reminders share one Android background runtime but remain independent: turning either feature off does not stop the other.

## Safety and recovery

- Revoking a permission disables monitoring and fails open.
- App Lock exposes a direct disable path and does not trap the user in an overlay.
- Monitoring pauses while the screen is off and recovers after reboot only when permissions remain valid.
- Battery guidance opens Android's system settings; Habiter does not silently request an exemption.

If behavior is unreliable, disable App Lock, grant both permissions again, and verify that Android permits the foreground service. See the [engineering and device test notes](/app-lock) for the full safety contract.

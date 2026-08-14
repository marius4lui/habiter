# Android App Lock

App Lock is an optional Android-only feature. It requires explicit Usage Access
and overlay permission, a selected app, and a visible foreground-service
notification. Missing or revoked access disables monitoring and fails open.

The service checks usage events on a dedicated background thread at no less than
750 ms while the screen is on. It stops callbacks while the screen is off,
avoids duplicate monitor loops, and disables the stored native flag if boot or
watchdog recovery cannot restart safely. Battery guidance opens the system-wide
optimization settings; Habiter does not request a direct exemption.

Package visibility is scoped to launcher apps rather than `QUERY_ALL_PACKAGES`.
The foreground-service `specialUse` declaration and App Lock behavior must be
reviewed against the applicable store policy before distribution.

## Manual verification

- Android 13–16 permission grant/revocation and one-tap disable.
- Screen off/on, reboot, process kill, midnight completion reset, and battery
  saver on representative OEM devices.
- Overlay recovery actions return to Habiter or the launcher without trapping
  the user.

No claim is made that every OEM will preserve the service indefinitely.

# Android App Lock

App Lock is an optional Android-only feature. It requires explicit Usage Access
and overlay permission, a selected app, and a visible foreground-service
notification. Missing or revoked access disables monitoring and fails open.

The service checks usage events on a dedicated background thread at no less than
750 ms while the screen is on. It stops callbacks while the screen is off,
avoids duplicate monitor loops, and disables the stored native flag if boot or
watchdog recovery cannot restart safely. Battery guidance opens the system-wide
optimization settings; Habiter does not request a direct exemption.

The blocking UI is derived from the current runtime state. It exists only while
App Lock is enabled, both permissions are available, relevant habits remain
open, and the foreground package is selected for blocking. A launcher or allowed
app transition, habit completion, disablement, permission loss, screen-off, or
service shutdown removes the overlay. Switching directly between blocked apps
replaces the displayed app and habit context instead of retaining stale copy.

The overlay uses the shared Habiter palette and calm, autonomy-preserving copy.
It has no persistent motion, remains scrollable for large text and landscape,
keeps system and gesture insets clear, and offers explicit actions to open the
relevant Habiter context or return to the Home screen.

Package visibility is scoped to launcher apps rather than `QUERY_ALL_PACKAGES`.
The foreground-service `specialUse` declaration and App Lock behavior must be
reviewed against the applicable store policy before distribution.

## Guided setup and per-app rules

The optional guided setup explains Usage Access and overlay access before it
opens either Android settings screen. A first decline leads to one respectful
second explanation; a second decline exits immediately. Draft progress is
feature-local and resumable after process recreation, so the parent onboarding
depends only on the `enabled`, `skipped`, or `deferred` result.

Recommendations combine seven days of local foreground usage, a versioned local
package catalog, and recency. They never auto-select an app. Every selected app
has its own general-focus or specific-habit requirement. Dart evaluates daily,
fixed-weekday, and flexible weekly schedules and publishes only current
per-package blockers to Android. Missing projections and revoked permissions
fail open.

## Manual verification

- Android 13–16 permission grant/revocation and one-tap disable.
- Screen off/on, reboot, process kill, midnight completion reset, and battery
  saver on representative OEM devices.
- Overlay recovery actions return to Habiter or the launcher without trapping
  the user.
- Blocked app → launcher/allowed app, blocked app A → blocked app B, final habit
  completion, disablement, permission revocation, and service shutdown.
- Gesture navigation, rotation, landscape, and 200 percent font scaling.

No claim is made that every OEM will preserve the service indefinitely.

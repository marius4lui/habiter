# Updates

Habiter uses signed release metadata to decide whether a newer build is available. Installation remains visible and user-controlled on every platform.

## Platform behavior

| Platform | Update behavior |
| --- | --- |
| Android direct build | Downloads an APK through Android, verifies it, then opens the system installer. |
| Android store build | Uses Google Play's official flexible or immediate in-app update flow and never downloads an APK directly. |
| Windows | A maintained user-scoped bundle can apply a signed ZIP after SHA-256 and publisher-continuity checks. Unsigned, system-wide, and unowned installs use the external installer. |
| macOS | A maintained user-scoped bundle can apply a signed and Gatekeeper-approved ZIP without changing the app signature. Unsigned, system-wide, and unowned installs use the external installer. |
| Linux | A maintained user-scoped `Habiter.AppImage` can replace itself after SHA-256 verification. Package-manager and other external formats stay on their original update path. |
| iOS, web | Does not self-update; installation remains an external distribution concern. |

Habiter 1.5.0 introduced the updater. A client older than 1.5 needs one manual upgrade through the download page, GitHub Releases, or a store before automatic checks are available.

## Stable and beta tracks

The **stable** track is the default and considers stable releases only. The **beta** track considers both stable and beta releases, then selects the newest eligible build without downgrading. Publishing a beta never changes the latest stable release. Change the track in the Update Center only if you are comfortable testing a prerelease.

An update decision compares both semantic version and monotonic build number. The Update Center shows version, publication date, localized release notes, progress, and one of the explicit lifecycle states: current, available, downloading, ready, restart required, failed, or unsupported. A release can also declare a minimum supported version and a future mandatory deadline. A mandatory screen is allowed only after a fresh successful online verification; an offline or failed check does not lock access to habits.

## Download profiles

Habiter offers three profiles for automatic checks. Automatic download applies only when the selected platform path supports a safe direct transfer; Store and external-installer prompts always require a visible user action.

- **Immediate** checks hourly and on startup/resume, and can auto-download on any validated network, including metered networks.
- **Balanced** checks daily and auto-downloads only on an unmetered validated network.
- **Saver** checks weekly and never auto-downloads; starting a transfer remains your decision.

Desktop systems are treated as metered because Habiter cannot establish connection cost portably. Consequently, Balanced never starts an automatic desktop download; manual downloads and the explicit Immediate profile remain available.

Android's Download Manager, Google Play, or Habiter's bounded desktop download cache owns the transfer as appropriate. Habiter persists the transfer identifier and expected build, reports progress, and reconciles it after process recreation. Direct transfers can be canceled and retried. A declined Store or operating-system prompt returns to the available state without deleting user data.

## Trust, installation, and rollback

Before offering or applying an artifact, Habiter verifies:

1. the manifest envelope uses a trusted key ID and a valid Ed25519 signature;
2. the release and artifact metadata parse under the supported schema;
3. exactly one primary artifact matches platform, architecture, format, channel, and Android distribution;
4. the artifact URL is HTTPS, redirects are rejected for in-app transfers, and the file name is safe;
5. downloaded size and SHA-256 match the signed metadata;
6. the target build is newer than the installed build;
7. platform trust where applicable: Android signer continuity, Windows Authenticode publisher continuity, or macOS code-signing team, notarization/Gatekeeper, and bundle identity.

Desktop replacement is available only when installer ownership metadata identifies the exact user-scoped target. The helper waits for the running app, stages beside that target, performs an atomic rename, relaunches, and restores the previous version when startup fails. It never writes to a package-manager install, escalates privileges, disables SmartScreen or Gatekeeper, or changes arbitrary paths. Current unsigned Windows and macOS artifacts therefore remain on the visible external-installer path until their release metadata truthfully reports verified signing.

Android direct builds additionally verify that the APK signing certificate matches the installed application and that build flavor plus install source permit direct installation. Habiter never silently installs an update and never bypasses Android's unknown-app permission screen. Google Play remains authoritative for Store eligibility, staged rollout, device compatibility, download, and installation.

## Errors and recovery

Offline checks, insufficient storage, interrupted transfers, integrity failures, declined installation, and unavailable external flows map to localized categories instead of internal exception text. Retry performs a new safe check or transfer. A failed integrity check deletes the invalid payload. Clearing update downloads removes only updater cache and lifecycle markers; it does not affect habits, entries, settings, backups, reminders, or credentials.

If an update repeatedly fails, keep the current version, use the platform's documented installer route, and include the visible failure category in a support report. Release operators can withdraw an offered build through the manifest kill switch without deleting historical release evidence; see [release operations](/release-operations).

## Privacy and offline behavior

Update checks send only the selected release channel and normal HTTP cache metadata. They contain no account, install, advertising, habit, or device identifier and create no tracking event merely to measure checks. The signed manifest endpoint supports `ETag` revalidation. A previously verified manifest may support non-blocking offline status, but a stale cache cannot activate a mandatory deadline. Manual checks surface their failure and preserve the last valid application state.

## Storage and cleanup

The Update Center shows downloaded storage and provides cleanup controls. Successful upgrades remove obsolete download metadata. Part files and failure markers stay inside Habiter's per-user update cache and are bounded by the signed artifact size.

For the network contract, see the [Release API reference](/api/release-api). Release operators should follow the [release operating model](/release-operations) and [verification checklist](/release-candidate).

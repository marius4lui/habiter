# Updates

Habiter uses signed release metadata to decide whether a newer build is available. Installation remains visible and user-controlled on every platform.

## Platform behavior

| Platform | Update behavior |
| --- | --- |
| Android direct build | Downloads an APK through Android, verifies it, then opens the system installer. |
| Android store build | Opens the configured store path and never downloads an APK directly. |
| Windows, Linux, macOS | Opens the matching verified release URL in the browser. |
| iOS, web | Does not self-update; installation remains an external distribution concern. |

Habiter 1.5.0 introduced the updater. A client older than 1.5 needs one manual upgrade through the download page, GitHub Releases, or a store before automatic checks are available.

## Stable and beta tracks

The **stable** track is the default and considers stable releases only. The **beta** track considers both stable and beta releases, then selects the newest eligible build without downgrading. Publishing a beta never changes the latest stable release. Change the track in the Update Center only if you are comfortable testing a prerelease.

An update decision compares both semantic version and monotonic build number. A release can also declare a minimum supported version and a future mandatory deadline. A mandatory screen is allowed only after a fresh successful online verification; an offline or failed check does not lock access to habits.

## Download profiles

Direct Android builds offer three profiles:

- **Immediate** checks hourly and on startup/resume, and can auto-download on any validated network, including metered networks.
- **Balanced** checks daily and auto-downloads only on an unmetered validated network.
- **Saver** checks weekly and never auto-downloads; starting a transfer remains your decision.

Android's Download Manager owns the transfer. Habiter persists the download identifier, reports progress, and can resume status tracking after process recreation.

## Trust and verification

Before presenting an Android APK to the installer, Habiter verifies:

1. the manifest envelope uses a trusted key ID and a valid Ed25519 signature;
2. the release and artifact metadata parse under the supported schema;
3. the artifact URL is HTTPS and the file name is safe;
4. downloaded size and SHA-256 match the signed metadata;
5. the target build is newer than the installed build;
6. the APK signing certificate matches the installed application;
7. the build and install source permit direct installation.

A failed check removes or rejects the candidate before Android receives an install intent. Habiter never silently installs an update and never bypasses Android's unknown-app permission screen.

## Caching and offline behavior

The signed manifest endpoint supports `ETag` revalidation. A previously verified manifest may support non-blocking offline status, but a stale cache cannot activate a mandatory deadline. Manual checks surface their underlying failure and preserve the last valid application state.

## Storage and cleanup

The Update Center shows downloaded storage and provides cleanup controls. Successful upgrades remove obsolete download metadata. Clearing update downloads does not affect habits, entries, settings, backups, or reminder data.

For the network contract, see the [Release API reference](/api/release-api). Release operators should follow the [release operating model](/release-operations) and [verification checklist](/release-candidate).

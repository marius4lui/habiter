# Release verification checklist

Use this checklist for every release candidate. It records reproducible gates; it is not a release announcement and authorizes no deployment or publication.

## Required gates

| Area | Commands | Environment note |
|---|---|---|
| Flutter | `dart format --output=none --set-exit-if-changed .`, `flutter analyze --fatal-infos`, `flutter test --coverage` | Flutter 3.44.8 in CI |
| Platforms | Android, web, Linux, macOS, Windows, unsigned iOS release builds | GitHub matrix runners |
| Workspace | `pnpm install --frozen-lockfile`, roadmap, release-core, Worker, and website checks from `quality.yml` | Node 24 / pnpm 11 |
| Docs | `npm ci`, `npm run docs:check` | Node 24 |
| Security | Gitleaks plus explicit secret/reference scans | full Git history in CI |

## Manual device gates

- Verify reminder delivery and actions when foregrounded, backgrounded, and terminated across a DST boundary.
- Verify Android App Lock permission denial, service restart, midnight recovery, and battery-policy messaging on a physical device.
- Verify Classly-compatible OAuth against a trusted public HTTPS test server supporting PKCE.
- Confirm pasted-JSON import preview, keep-existing collision behavior, clipboard recovery backup, cancellation, and rejection of deliberately corrupt JSON.

## Update-system gates

The Android build job runs both native unit-test variants and validates the
actual merged manifests with `scripts/android/verify-update-flavors.sh`.
Source-manifest inspection alone is not accepted as evidence for flavor
isolation. The desktop matrix builds each target and runs the generated-helper
contract test; Windows parses the PowerShell helper and POSIX runners parse the
shell helpers.

- Install Habiter 1.5 manually over the newest pre-1.5 direct build, then update to a higher RC build from inside the app.
- Confirm the direct APK resumes after process termination, works over Wi-Fi and mobile data according to the selected profile, asks clearly for unknown-app permission, and still requires Android's explicit **Install** action.
- Deny unknown-app permission and verify that Habiter remains usable and can reopen the correct Android settings page without a prompt loop.
- Install the Store flavor from a Play-recognized test track and exercise both flexible and mandatory/immediate Play flows. Verify accept, decline, progress, process recreation, downloaded/restart-required, and completion states. It must never download an APK and must contain no `REQUEST_INSTALL_PACKAGES` permission or update FileProvider.
- Corrupt the APK, substitute a different signing certificate, report the wrong size, and use an unsafe URL; every case must delete or reject the candidate before Android receives an install intent.
- Interrupt a DownloadManager transfer, terminate Habiter, relaunch it and verify that progress resumes from the persisted download ID.
- Verify that a completed and validated build creates exactly one **Ready to install** system notification, including across process restarts.
- Exercise an expired mandatory deadline once with a successful online verification and once offline. Online must show the non-dismissible update screen; offline must preserve app access with a permanent warning until verification succeeds.
- Check the Update Center and release stories in German and English, light and dark themes, reduced motion, large text, compact phones and a wide desktop window.
- On Linux, install the maintained user-scoped AppImage, interrupt/resume and cancel a transfer, reject a bad checksum, verify the running-process wait, complete a relaunch, and inject an early-exit failure to prove rollback. Confirm a package-manager/custom install opens the external route and remains untouched.
- On Windows, test a signed fixture in a maintained user-scoped bundle: wrong checksum, ZIP traversal/reparse entry, unsigned executable, publisher mismatch, locked/running app, successful relaunch, and early-exit rollback must all have the documented result. Confirm the current unsigned production artifact remains external and SmartScreen is never disabled.
- On macOS, test a signed/notarized fixture under `~/Applications`: wrong checksum, unexpected archive root, bundle-ID mismatch, invalid signature, Gatekeeper rejection, Team Identifier mismatch, successful relaunch, and early-exit rollback. Confirm the adjacent ownership manifest leaves the bundle signature valid and that `/Applications` remains external without an elevation prompt.
- Publish a preview signed envelope that omits the offered RC. A verified-ready client must delete the cached candidate on its next successful check and return to the current/available state; an in-flight client must remain cancelable and must not install without reaching that revalidation point. Restore the preview, verify the new ETag, and preserve the withdrawn release evidence.

Habiter 1.5 is the bootstrap version for automatic updates, so the first installation from an older client remains manual. Every stable publication is blocked until this matrix and the normal release-candidate gates pass.

Any unavailable or failing gate remains a release blocker and must be reported in the pull request rather than waived silently.

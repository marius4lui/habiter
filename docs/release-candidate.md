# Habiter 1A release-candidate evidence

This document records reproducible release-candidate gates. It is not a release announcement and authorizes no deployment or publication.

## Required gates

| Area | Commands | Environment note |
|---|---|---|
| Flutter | `dart format --output=none --set-exit-if-changed .`, `flutter analyze --fatal-infos`, `flutter test --coverage` | Flutter 3.44.8 in CI |
| Platforms | Android, web, Linux, macOS, Windows, unsigned iOS release builds | GitHub matrix runners |
| Landing | frozen install, lint, TypeScript, `pnpm test`, production build | Node 24 / pnpm 11 |
| Docs | `npm ci`, `npm run docs:build` | Node 24 |
| Security | Gitleaks plus explicit secret/reference scans | full Git history in CI |

## Manual device gates

- Verify reminder delivery and actions when foregrounded, backgrounded, and terminated across a DST boundary.
- Verify Android App Lock permission denial, service restart, midnight recovery, and battery-policy messaging on a physical device.
- Verify Classly-compatible OAuth against a trusted public HTTPS test server supporting PKCE.
- Confirm import preview, collision choice, backup creation, cancellation, and recovery from a deliberately corrupt file.

## v1.5 update-system gates

- Install Habiter 1.5 manually over the newest pre-1.5 direct build, then update to a higher RC build from inside the app.
- Confirm the direct APK resumes after process termination, works over Wi-Fi and mobile data according to the selected profile, asks clearly for unknown-app permission, and still requires Android's explicit **Install** action.
- Deny unknown-app permission and verify that Habiter remains usable and can reopen the correct Android settings page without a prompt loop.
- Install the Store flavor from a Store-recognized source and verify that it opens the Store listing, never downloads an APK, and contains no `REQUEST_INSTALL_PACKAGES` permission or update FileProvider.
- Corrupt the APK, substitute a different signing certificate, report the wrong size, and use an unsafe URL; every case must delete or reject the candidate before Android receives an install intent.
- Interrupt a DownloadManager transfer, terminate Habiter, relaunch it and verify that progress resumes from the persisted download ID.
- Verify that a completed and validated build creates exactly one **Ready to install** system notification, including across process restarts.
- Exercise an expired mandatory deadline once with a successful online verification and once offline. Online must show the non-dismissible update screen; offline must preserve app access with a permanent warning until verification succeeds.
- Check the Update Center and release stories in German and English, light and dark themes, reduced motion, large text, compact phones and a wide desktop window.

Habiter 1.5 is the bootstrap version for automatic updates, so the first installation from an older client remains manual. Stable publication is blocked until this matrix and the normal RC gates pass.

Any unavailable or failing gate remains a release blocker and must be reported in the pull request rather than waived silently.

# Platform-channel contracts

Flutter and native platform code communicate through a small set of named method channels. Treat every channel as a versioned application binary interface: change Dart and native handlers together, preserve safe failure behavior, and cover the serialized shape with tests.

These channels are internal to the Habiter application. They are not a public plugin API and must not be consumed by third-party applications.

## Contract rules

- Arguments and results use Flutter standard message-codec values only.
- Native handlers return `notImplemented` for unknown methods.
- Dart adapters translate missing plugins, platform exceptions, and malformed values into typed failures where the domain contract provides them.
- Sensitive credentials, reminder payloads, and full habit records never cross a channel unless the receiving native feature requires that exact data.
- Android-only calls are guarded before invocation; iOS implements only the shared channels listed below.
- Method names, required keys, result keys, and error codes are compatibility-sensitive.

## App Lock

- Channel: `com.habiter.app/applock`
- Platforms: Android only
- Dart boundary: `AppLockGateway`

| Method | Arguments | Success result |
| --- | --- | --- |
| `getInstalledApps` | none | List of `{packageName, appName, iconBytes?}` launcher-app maps. |
| `hasUsageStatsPermission` | none | `bool` |
| `requestUsageStatsPermission` | none | `null` after opening system settings. |
| `hasOverlayPermission` | none | `bool` |
| `requestOverlayPermission` | none | `null` after opening system settings. |
| `isBatteryOptimized` | none | `bool`; `true` means Android still applies battery optimization. |
| `requestBatteryOptimizationExemption` | none | `null` after opening system-wide battery settings. |
| `startMonitoring` | `{lockedPackages: List<String>}` | `bool` indicating whether monitoring started. |
| `stopMonitoring` | none | `null` |
| `updateLockedApps` | `{lockedPackages: List<String>}` | `null` |
| `updateIncompleteHabits` | `{habitNames: List<String>}` | `null` |
| `habitsComplete` | none | `null` |
| `habitsIncomplete` | none | `null` |

The Dart adapter exposes safe failure categories for unsupported platform, native failure, and malformed response. Permission loss or a failed service start must leave App Lock disabled and fail open.

## Device time zone

- Channel: `com.habiter.app/timezone`
- Platforms: Android and iOS

| Method | Arguments | Success result |
| --- | --- | --- |
| `getTimeZoneId` | none | IANA time-zone identifier as `String`. |

The reminder service resolves the identifier against the bundled time-zone database. A missing or unknown identifier falls back to UTC and is recorded as a fallback; it must not crash startup.

## Notification settings

- Channel: `com.habiter.app/settings`
- Platforms: Android and iOS

| Method | Arguments | Success result |
| --- | --- | --- |
| `openNotificationSettings` | none | `null` after opening the platform settings destination. |

Permission status and permission prompts use the notification plugin. This channel only opens the relevant system settings screen after an explicit user action.

## Android widget pinning

- Channel: `com.habiter.app/widget_pin`
- Platforms: Android 8.0 and newer when the launcher supports pin requests

| Method | Arguments | Success result |
| --- | --- | --- |
| `isSupported` | none | `bool` |
| `requestPin` | none | `bool` indicating whether Android accepted the request. |
| `pinResult` | none | `idle`, `requested`, or `pinned`. |
| `hasInstalledWidgets` | none | `bool` |
| `listWidgetInstances` | none | List of `{widgetId, widthDp, heightDp, breakpoint, configuration}` maps for installed instances. |
| `saveWidgetConfiguration` | `{widgetId: int, configuration: String}` | `null` after atomically persisting the matching versioned JSON configuration and requesting an update for only that widget ID. |
| `resetWidgetConfiguration` | `{widgetId: int}` | `null` after removing only that instance's configuration and requesting its legacy-default render. |

The pin result tracks platform callback state, not a guarantee that a widget remains installed forever. Configuration is keyed by Android `appWidgetId`; deleting an instance removes only its configuration. Missing, invalid, or unsupported configuration schemas fall back to legacy rendering defaults. Widget content and actions continue to use the `home_widget` bridge and the sanitized shared `habiter_widget_snapshot`; configuration is not a second habit-state source of truth.

## Android updates

- Channel: `com.habiter.app/updates`
- Platforms: Android for native methods; desktop uses external URLs and an HTTP manifest transport

| Method | Required arguments | Success result |
| --- | --- | --- |
| `getRuntimeInfo` | none | `{distribution, directInstallAllowed, installerSource?}` |
| `getNetworkStatus` | none | `{isOnline, isMetered}` |
| `fetchManifest` | `{url, etag?}` | `{statusCode, body, etag?}` |
| `enqueueDownload` | `{url, fileName, sha256, size, buildNumber, allowMetered}` | Android Download Manager ID. |
| `getDownloadStatus` | `{downloadId}` | `{phase, downloadedBytes, totalBytes, failureCode?}` |
| `verifyDownload` | `{downloadId, sha256, size, buildNumber, version}` | `{valid, failureCode?}` |
| `removeDownload` | `{downloadId}` | `null` |
| `clearDownloads` | none | `null` |
| `installUpdate` | `{downloadId, buildNumber}` | `launched`, `permissionRequired`, or `unavailable`. |
| `openInstallerPermission` | none | `null` after opening Android settings. |
| `openStore` | none | `bool` |
| `storedDownloadBytes` | none | Non-negative byte count. |
| `cleanupAfterUpgrade` | `{currentBuild}` | `null` |
| `consumePendingOpen` | none | `bool` |

`fetchManifest` accepts HTTPS only, does not follow redirects, applies bounded timeouts, caps response bytes, and supports `If-None-Match`. Direct-download methods reject store distributions, unsafe URLs and file names, stale builds, invalid hashes, insufficient storage, mismatched sizes, and mismatched signing certificates.

The native side can invoke `openUpdateCenter` on the same channel when a notification intent is delivered to a running Flutter engine. At cold start, Dart calls `consumePendingOpen` to consume the equivalent intent flag exactly once.

Native update failures use stable machine-readable codes such as `unsafe_manifest_url`, `manifest_too_large`, `manifest_network_error`, `unsafe_url`, `unsafe_file_name`, `invalid_hash`, `stale_apk`, `insufficient_storage`, and `update_platform_error`. UI copy must map these to safe localized messages rather than exposing exception details.

## Changing a channel

1. Update the domain gateway before the transport details.
2. Update every native platform that owns the channel.
3. Add adapter tests for success, malformed result, platform error, and missing plugin.
4. Add native tests for validation and side effects that Dart cannot prove.
5. Re-run Flutter tests plus both Android flavor unit-test tasks.
6. Update this page in the same change.

Do not reuse a method name with a new incompatible payload. Add a new method or an explicit schema-version field when old and new application components can coexist.

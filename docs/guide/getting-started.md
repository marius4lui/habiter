# Getting started

This guide covers installation, the first habit, everyday completion, and safe backup.

## Installation

Use the [smart download page](https://get.habiter.dev/download) to select the current artifact for Android, Windows, Linux, or macOS. Release files and checksums are also available on [GitHub Releases](https://github.com/marius4lui/habiter/releases).

::: info Platform status
Android releases are signed. Windows, Linux, and macOS packages have verified checksums; Windows and macOS code signing is still planned. iOS CI artifacts are unsigned and require manual signing. The web build is validated but is not the primary distribution format.

Starting with Habiter 1.5, the direct Android build can download a newer signed APK in the background and hand it to Android's system installer. Habiter never installs an update silently. Store builds stay on the Store path, desktop builds open the matching download in the browser, and iOS/web do not self-update in 1.5. If you are upgrading from a version older than 1.5, install 1.5 once through the download page or Store; automatic updates are available after that bootstrap upgrade.
:::

### Build from source

```bash
git clone https://github.com/marius4lui/habiter.git
cd habiter/apps/habiter
flutter pub get --enforce-lockfile
flutter run
```

## Your first habit

1. Open **Today** and select the create action.
2. Choose a clear name, icon, and color.
3. Select daily, specific weekdays, or a weekly frequency.
4. Optionally configure a reminder.
5. Review and save the habit.

## Completing habits

Tap an active habit once to complete it for today. Undo is available immediately. Paused and archived habits retain their history and can be restored later.

## Keep your data safe

Open **Settings → Data & privacy** to copy a versioned JSON backup to the clipboard. Imports accept pasted backup JSON, show a preview before changing local data, preserve existing collisions, and copy the pre-import recovery backup to the clipboard after success.

Habiter does not require a cloud account. Paste exported backups into secure storage you control, then clear clipboard history if your platform retains it.

## Next steps

- Review all [features and platform limits](/guide/features).
- Configure and troubleshoot [reminders](/guide/reminders).
- Understand [updates and verification](/guide/updates).
- Review [data and privacy boundaries](/guide/data-and-privacy).
- Configure Android [App Lock](/guide/app-lock).
- Connect an optional [Classly-compatible service](/guide/classly-sync).

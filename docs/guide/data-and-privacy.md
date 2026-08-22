# Data and privacy

Habiter is local-first. Core tracking requires no account, and the project does not provide a company-operated synchronization service.

## What stays on the device

The application stores these categories locally:

- habits, schedules, lifecycle state, and completion history;
- appearance, locale, onboarding, and reminder preferences;
- reminder plans, stable notification IDs, action records, and local learning profiles;
- App Lock configuration and the sanitized projection required by Android services and widgets;
- update preferences, verified manifest cache, and download state;
- optional integration configuration.

Widget snapshots and native service projections contain only the data required for their feature. They are not a second source of truth and are reconciled from canonical application state.

## Data that can leave the device

Data leaves Habiter only after you choose a boundary that requires it:

- **Backup export** copies a versioned JSON document to the clipboard so you can place it in storage you control.
- **Backup import** reads JSON that you paste and shows a preview before mutation.
- **Classly-compatible sync** communicates with the HTTPS service you configure.
- **Personal Sync Beta** sends only the allow-listed synchronization contract to the Docker/SQLite or Worker/D1 instance you operate. There is no Habiter-hosted fallback.
- **Experimental remote AI** sends the data required for the selected request to the provider you configure.
- **Release checks** request signed release metadata and platform download information; they do not send habit data.

External services have their own privacy, retention, availability, and pricing terms. Core habit tracking continues to work when optional integrations are disconnected.

See [Personal Sync Beta](/guide/personal-sync) for the exact synchronized, device-local, and never-synchronized categories; server ownership; backups; sessions; and deletion boundaries.

## Credentials

OAuth tokens and experimental AI keys use secure platform storage where available. They must never be stored in ordinary preferences, exported backups, diagnostics, notification payloads, logs, or source control.

Non-secret endpoint URLs, enablement flags, and sync timestamps can use ordinary local preferences. Disconnecting an integration removes its local authorization state; imported habits remain ordinary local data until you archive or delete them.

## Export and import

Open **Settings → Data & privacy** to copy a versioned JSON backup. Treat the clipboard contents and any file you create from them as sensitive because they can contain habit names and history.

See the [Backup JSON format](/api/backup-format) for every field, compatibility rules, and the machine-readable schema.

Import follows a staged flow:

1. parse and validate without mutating storage;
2. show counts and conflicts in a preview;
3. keep existing habits when IDs collide;
4. persist one canonical state;
5. copy the pre-import recovery backup to the clipboard after a successful import;
6. reconcile reminders, widgets, and other projections.

Malformed, unsupported, or corrupt input is rejected before storage changes. The current user flow preserves existing habits when IDs collide and imports entries only for known habits.

## Deletion and reset scope

Uninstalling the desktop application does **not** reset Habiter data. The maintained uninstallers remove only the verified application payload and integration created for that exact installation. They preserve databases/preferences, reminder state, secure-storage credentials, backups, exports, clipboard history, and operating-system backups, and state that preservation in both the removal plan and completion summary. The initial uninstaller contract deliberately has no `--remove-data` or `-RemoveData` option.

Use the [safe platform uninstall workflow](/install/#uninstall-safely) for the application. Export a backup first if you later choose to remove data through Habiter or operating-system facilities.

Use the narrowest reset that matches your intent:

- reset reminder learning to remove calibration and adaptive timing data;
- clear update downloads to remove downloaded artifacts and update transfer state;
- disconnect integrations to remove their credentials and connection state;
- delete or archive individual habits to control their lifecycle;
- clear Habiter's application data through the operating system for a full local reset.

Operating-system backups, clipboard history, or manually copied exports can outlive an in-app reset. Delete those separately where they are stored.

## Diagnostics and support

Diagnostics are designed to expose state categories and safe identifiers, not content. Before sharing a screenshot or exported file, still review it for habit names, server URLs, package names, and other information you consider private.

Developers can find persistence and boundary rules in [Services and gateways](/dev/services) and the [platform-channel contract](/dev/platform-contracts).

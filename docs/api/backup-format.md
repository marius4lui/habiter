# Backup JSON format

Habiter exports a portable, versioned JSON document from **Settings → Data & privacy**. The current interface copies the document to the clipboard and accepts pasted JSON for import.

The canonical exporter schema is available as [JSON Schema 2020-12](/habiter-backup.schema.json).

## Top-level document

```json
{
  "schemaVersion": 1,
  "exportedAt": "2026-08-19T10:15:30.000Z",
  "habits": [],
  "entries": [],
  "settings": {
    "theme": "system",
    "notifications": true,
    "reminderTime": "20:00",
    "aiInsights": false,
    "language": "en"
  }
}
```

| Field | Type | Exported | Imported | Meaning |
| --- | --- | :---: | :---: | --- |
| `schemaVersion` | Integer | Yes | Yes | Format version. Current value is `1`. |
| `exportedAt` | ISO 8601 UTC string | Yes | No | Informational export timestamp. |
| `habits` | Array | Yes | Yes | Habit definitions and lifecycle metadata. |
| `entries` | Array | Yes | Yes | Completion records associated with habits. |
| `settings` | Object | Yes | No | Non-secret settings snapshot for inspection and future compatibility. |

Import requires `schemaVersion`, `habits`, and `entries`. Unknown top-level fields and version-1 object fields are tolerated. A version greater than the app supports is rejected before storage changes.

::: warning Sensitive content
Backups contain habit names, descriptions, categories, history, and source metadata. Store them as private data. Integration credentials, passwords, tokens, secrets, and API keys are excluded.
:::

## Habit object

Every exported habit contains these fields:

| Field | Type | Meaning |
| --- | --- | --- |
| `id` | String | Stable local identity. IDs must be unique within the backup. |
| `name` | String | Display name. |
| `description` | String or null | Optional detail text. |
| `color` | String | Stored display color, currently a hex color string. |
| `icon` | String | Stored icon identifier or glyph. |
| `frequency` | `daily`, `weekly`, or `custom` | Scheduling mode. |
| `targetCount` | Integer | Target completions for the schedule. |
| `category` | String | User-visible grouping. |
| `customDays` | Array of integers or null | Weekdays using Dart's `1` (Monday) through `7` (Sunday) numbering. |
| `createdAt` | ISO 8601 string | Creation instant. |
| `isActive` | Boolean | Whether the habit is currently active. |
| `notificationEnabled` | Boolean | Legacy per-habit notification flag. |
| `notificationTime` | `HH:mm` string or null | Legacy per-habit reminder time. |

Lifecycle-aware habits may also contain:

| Field | Type | Meaning |
| --- | --- | --- |
| `pauses` | Array of pause objects | Each item has `startedAt` and nullable `endedAt` ISO 8601 strings. |
| `archivedAt` | ISO 8601 string | Most recent archive instant. |
| `restoredAt` | ISO 8601 string | Most recent restore instant. |
| `source` | Object | Origin metadata for imported or suggested habits. |

`source.kind` is currently `local`, `classlyCompatible`, `imported`, `aiSuggested`, or an unknown forward-compatible string. `source.externalId` is the optional stable ID in the origin system. Additional source fields are preserved.

## Entry object

| Field | Type | Meaning |
| --- | --- | --- |
| `id` | String | Stable entry identity. |
| `habitId` | String | ID of the owning habit. |
| `date` | `yyyy-MM-dd` string | Local calendar date represented by the entry. |
| `completed` | Boolean | Whether the target was met. |
| `count` | Integer | Recorded completion count. |
| `timestamp` | ISO 8601 string | Time of the latest stored entry state. |

Entries whose `habitId` is not known after habit merging are ignored during import.

## Settings snapshot

The current app exports `theme`, `notifications`, `reminderTime`, `aiInsights`, `language`, and, when disabled, `showRecoverySupport`. Settings are intentionally not applied during import. Keys whose names resemble `token`, `secret`, `password`, `apiKey`, or `credential` are removed by the exporter.

## Import transaction

1. Habiter parses and validates the complete document.
2. Duplicate habit IDs inside the backup cause rejection.
3. The preview reports habit, entry, and local-ID collision counts without mutation.
4. The current Settings flow keeps existing local habits on ID collision.
5. Imported entries are upserted by entry ID only when their habit exists.
6. The repository mutation is transactional and rolls back on failure.
7. After a successful import, the pre-import recovery backup replaces the clipboard contents.

Imports do not delete local records that are absent from the backup. The internal service also supports replacing colliding habits for controlled callers, but that policy is not exposed by the current Settings UI.

## Compatibility rules

- Producers should emit schema version `1` exactly as described by the JSON Schema.
- Consumers may ignore unknown fields so version-1 documents can gain additive metadata.
- Changing a required field, its meaning, or its type requires a new schema version and migration tests.
- Import behavior must remain reject-before-mutate for malformed or unsupported documents.

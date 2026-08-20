# Classly-compatible sync

Import supported school events from a trusted Classly-compatible service as habits. The integration is optional and disabled until configured.

## Setup

1. Go to **Settings → Advanced integrations → Classly Sync**.
2. Enter the public HTTPS URL of the service you trust.
3. Complete the OAuth login. Habiter uses PKCE and stores credentials in secure platform storage where available.
4. Review the connection and select **Sync now**.

Imported items retain source metadata so repeated syncs can reconcile them rather than creating uncontrolled duplicates.

Service operators can implement the exact three-route protocol from the [Classly-compatible API reference](/api/classly-compatible).

::: warning Trust boundary
Only connect to a service you recognize. Login and event data are handled by that service under its own privacy and availability terms.
:::

## Auto-Sync

When supported, auto-sync can check for new items at these intervals:

- 5 minutes
- 15 minutes
- 30 minutes
- 60 minutes

Background execution remains subject to operating-system scheduling. Use **Sync now** when you need an immediate refresh.

## Supported event types

| Event Type | Habit Icon |
|------------|------------|
| Homework   | 📚         |
| Exam       | 📝         |
| Presentation | 🎤       |
| Other      | 📋         |

## Disconnecting

Disable automatic sync and disconnect the integration from Settings to remove the local authorization state. Existing imported habits remain under your control and can be archived or deleted separately.

# Classly-compatible service API

This contract defines the smallest remote API a service must implement for Habiter's optional Classly-compatible sync. It is a client compatibility contract, not a Habiter-hosted API.

The machine-readable definition is available as [OpenAPI 3.1 JSON](/classly-compatible.openapi.json).

## Trust and transport

Users provide the service origin. Habiter accepts only a root `https://` origin on port 443. Origins containing credentials, a path, query, fragment, localhost, `.local`, or a private IPv4 address are rejected.

Habiter uses a 15-second HTTP timeout. It never logs an access token or a response body from a failed request. A non-`200` token or events response fails the operation; the response body is not part of the client error.

## Required routes

| Method | Path | Authentication | Purpose |
| --- | --- | --- | --- |
| `GET` | `/api/oauth/authorize` | OAuth session chosen by the service | Start authorization-code login with PKCE |
| `POST` | `/api/oauth/token` | Authorization code and PKCE verifier | Exchange the code for an access token |
| `GET` | `/api/events` | `Authorization: Bearer <token>` | Fetch a full or incremental event list |

Subjects, user-info, refresh-token, and push-registration routes are not part of Habiter's current contract.

## Authorization request

Habiter opens `GET /api/oauth/authorize` in the system browser with these query parameters:

| Parameter | Value |
| --- | --- |
| `client_id` | `habiter-app` |
| `redirect_uri` | `habiter://auth/callback` on mobile and web-capable flows; `http://localhost:43823/callback` on desktop |
| `response_type` | `code` |
| `scope` | `read:events` |
| `state` | Cryptographically random, URL-safe value |
| `code_challenge` | Base64url-encoded SHA-256 PKCE challenge without padding |
| `code_challenge_method` | `S256` |

After authorization, redirect to the supplied URI with `code` and the unchanged `state` query parameter. Habiter rejects a missing code or mismatched state.

## Token exchange

`POST /api/oauth/token` uses `application/x-www-form-urlencoded` with:

```text
grant_type=authorization_code
code=<authorization code>
client_id=habiter-app
redirect_uri=<the same redirect URI>
code_verifier=<PKCE verifier>
```

A successful response is JSON and must include a string `access_token`:

```json
{
  "access_token": "opaque-access-token",
  "token_type": "Bearer",
  "scope": "read:events"
}
```

Habiter stores only `access_token`. Additional response fields are ignored. The current client has no refresh-token flow, so an expired or revoked token requires reconnecting.

## Events request

`GET /api/events` sends the bearer token and these query parameters:

| Parameter | Type | Required | Behavior |
| --- | --- | :---: | --- |
| `limit` | Integer | Yes | Habiter currently requests up to `500` events during sync. |
| `updated_since` | ISO 8601 date-time | No | Omitted for a full sync; present for an incremental sync. |

The response must be a JSON object with an `events` array:

```json
{
  "events": [
    {
      "id": "event-42",
      "type": "homework",
      "subject_name": "Mathematics",
      "title": "Complete worksheet 7",
      "date": "2026-08-21T00:00:00Z",
      "created_at": "2026-08-18T14:05:00Z"
    }
  ]
}
```

### Event fields

| Field | Type | Required | Habiter behavior |
| --- | --- | :---: | --- |
| `id` | String | Yes | Stable identity used to merge sync results and prevent duplicate imports. |
| `type` | String | Yes | Determines whether the event is actionable and selects the imported icon. |
| `subject_name` | String or null | No | Used as a title fallback and imported category. |
| `title` | String or null | No | Preferred imported habit name. |
| `date` | ISO 8601 string or null | No | Required for import; missing or invalid dates cause the event to be skipped. |
| `created_at` | ISO 8601 string or null | No | Sorting fallback when `date` is unavailable. |

Unknown event and response fields are ignored. An absent `events` field is treated as an empty list for compatibility, although conforming services should return it.

## Import semantics

- Events whose `type` equals `info`, ignoring case, are not imported.
- Events without a valid `date` are not imported.
- An event ID already present in any local habit, including an archived habit, is not imported again.
- The name falls back from `title` to `subject_name` to `Classly Task`.
- Homework, exam/test, and presentation types receive specialized icons; all other actionable types use the generic task icon.
- The source event ID and local occurrence date are retained as habit source metadata.

Sync failures affect only the optional integration. Core habit tracking remains available and existing imported habits stay local after disconnecting.

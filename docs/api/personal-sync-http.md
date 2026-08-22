# Personal Sync HTTP API

Habiter personal sync exposes one versioned HTTP contract from both the Docker/SQLite and Cloudflare Worker/D1 targets. The route implementation is runtime-neutral: adapters provide persistence, while `@habiter/sync-http` owns validation, authentication presentation, response envelopes, and security headers.

The API is private infrastructure for one Habiter account. It is not a public multi-user registration service.

## Endpoint summary

All routes are below the configured HTTPS origin. JSON request bodies must use `Content-Type: application/json`; unknown fields, unbounded input, and unsupported query parameters are rejected.

| Route | Authentication | Purpose |
| --- | --- | --- |
| `GET /v1/health` | Public | Bounded liveness response |
| `GET /v1/capabilities` | Public | Protocol, PKCE, refresh, and batch capabilities |
| `GET /v1/instance-info` | Public | Instance display name, public base URL, and setup state |
| `GET /v1/authorize` | Public | Minimal external-browser login in German or English |
| `POST /v1/authorize` | CSRF state | Begin or complete a password-proof challenge |
| `POST /v1/token` | One-time code + PKCE | Redeem an authorization code |
| `POST /v1/refresh` | Rotating refresh token | Rotate a device session and issue a short access token |
| `POST /v1/revoke` | Bearer | Revoke the current device or every device |
| `POST /v1/push` | Bearer | Validate and commit a bounded operation batch |
| `GET /v1/pull` | Bearer | Read a bounded cursor page |
| `GET /v1/snapshot` | Bearer | Read a validated replacement snapshot for initial sync or cursor recovery |
| `GET /v1/device` | Bearer | Describe the current authenticated device |
| `DELETE /v1/device` | Bearer | Revoke the current device |

Authorization uses the shared protocol documented in [Personal Sync Authentication](/dev/personal-sync-auth). The browser derives the PBKDF2 password key locally and sends only a challenge-bound HMAC proof. The plaintext password is cleared before the proof request and never reaches the service.

## Authorization request

`GET /v1/authorize` accepts exactly these parameters:

- `response_type=code`
- `redirect_uri`, exactly matching a configured allowlist entry
- `code_challenge`, an RFC 7636 S256 challenge
- `state`, at least 16 characters of opaque client entropy
- `attempt_id` and `device_id`
- optional `lang=de` or `lang=en`

The login document contains no third-party scripts, fonts, images, analytics, or remote styles. A per-response nonce permits only its embedded script and style. Keyboard focus, browser autofill, large text, reduced motion, status announcements, dark mode, and narrow screens are supported.

After successful proof verification, the browser appends `code` and the unchanged `state` to the exact allowlisted redirect. The token endpoint burns the code atomically before validating its PKCE verifier, redirect URI, and attempt ID.

## JSON examples

Begin a login challenge:

```http
POST /v1/authorize
Content-Type: application/json
X-Habiter-CSRF: state-123456789012

{
  "action": "begin",
  "csrf": "state-123456789012",
  "attempt": {
    "username": "owner",
    "codeChallenge": "…",
    "state": "state-123456789012",
    "redirectUri": "https://app.example/auth/callback",
    "attemptId": "attempt-a",
    "deviceId": "phone-a"
  }
}
```

Redeem the resulting code:

```http
POST /v1/token
Content-Type: application/json

{
  "grantType": "authorization_code",
  "code": "…",
  "codeVerifier": "…",
  "redirectUri": "https://app.example/auth/callback",
  "attemptId": "attempt-a"
}
```

Push accepts `{ "operations": [...] }`. Pull accepts `cursor` and `limit`; omit `cursor` for the first page. A response with `requiresSnapshot: true` carries the stable recovery reason from the storage contract.

`GET /v1/snapshot` returns the current synchronized records, lifecycle markers, and the cursor that immediately follows the snapshot. Clients validate the complete authenticated response before mutation. They use it only for a confirmed initial replacement or when pull reports an invalid or compacted cursor, and create a local recovery artifact before replacing synchronized state. Unsent local operations remain durable and are reconciled afterward.

## Error envelope

Errors use a stable public shape:

```json
{
  "error": "invalid_request",
  "message": "Request is invalid",
  "requestId": "opaque-request-id"
}
```

Authentication failures are deliberately generic. Missing users and incorrect credentials produce the same code, message, and status. Storage exceptions and unexpected errors are replaced with bounded public errors. Client-supplied request IDs are accepted only when they match the safe identifier grammar.

## Browser and transport security

Every response is `no-store`, denies framing and MIME sniffing, uses `no-referrer`, isolates cross-origin resources, and disables unrelated browser capabilities. HTTPS instances also emit HSTS. HTML receives a nonce-bound CSP with `default-src 'none'`, `connect-src 'self'`, `form-action 'self'`, `base-uri 'none'`, and `frame-ancestors 'none'`.

CORS is deny-by-default. Operators may configure exact trusted origins; wildcard origins and credentialed cookies are not supported. Preflights allow only the documented methods and headers. Authorization actions additionally require matching state in the JSON body and `X-Habiter-CSRF`, and reject cross-site Fetch Metadata.

The optional structured log callback receives only request ID, bounded method, path without query string, status, and duration. Headers, bodies, query strings, usernames, authorization codes, and tokens are never passed to it. Logging failures cannot alter the protocol response.

## Runtime configuration

Both targets construct the same handler with:

- an initialized `SyncStorage` adapter;
- a `SyncAuth` instance using the target's instance encryption key;
- one public base URL and display name;
- one or more exact redirect URIs;
- optional exact CORS origins;
- bounded body, push, and pull limits.

The default maximum body is 256 KiB, a push contains at most 100 operations, and a pull returns at most 500 operations. Every push operation is validated before the first write, preventing a malformed later item from causing a partially accepted request.

## Validation contract

The shared route suite runs unchanged against in-memory SQLite and an actual local Miniflare Worker/D1 binding. It covers discovery, complete PKCE authentication, push/pull, refresh, revocation, request IDs, generic failures, CORS, CSRF, content types, body limits, redirect allowlisting, sanitized logging, and security headers. DOM tests inspect both localized login variants for semantic labels, autofocus, autofill, live error announcements, viewport behavior, CSP, and absence of remote resources.

This package does not deploy either target and does not implement native app presentation.

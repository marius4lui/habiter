# Release API

The Habiter Release API publishes release metadata, signed update manifests, update decisions, and download redirects. It is a read-only HTTPS API served from `https://get.habiter.dev`.

The [OpenAPI 3.1 document](/release-api.openapi.json) is the machine-readable contract. This page explains behavior that matters to clients and release operators.

## Conventions

- All API bodies use UTF-8 JSON with `content-type: application/json; charset=utf-8`.
- The API is unauthenticated and read-only.
- `stable` is the default channel; `beta` must be requested explicitly.
- Supported distribution platforms are `android`, `windows`, `linux`, and `macos`.
- Release versions use three-component SemVer without a leading `v`, for example `1.5.1`.
- Build numbers are positive integers and increase monotonically across releases.
- Redirect responses use HTTP `302` and an absolute `Location` header.
- Unknown routes and unsupported extra path segments return `404`; they are never interpreted as private release subresources.

## Errors and request IDs

API errors share this shape:

```json
{
  "error": {
    "code": "release_not_found",
    "message": "Release not found",
    "requestId": "8f2db821-fc92-4f0f-900f-6cae40d52ce2"
  }
}
```

`code` is the stable machine-readable value. `message` is safe explanatory text but is not a localization or parsing contract. `requestId` identifies one failed request for diagnostics.

| Status | Code | Meaning |
| --- | --- | --- |
| `400` | `invalid_pagination` | `page` or `limit` is outside its accepted positive-integer range. |
| `400` | `invalid_channel` | `channel` is neither `stable` nor `beta`. |
| `400` | `invalid_update_request` | Platform, SemVer version, or positive build coordinate is missing or invalid. |
| `404` | `not_found` | The route does not exist. |
| `404` | `release_not_found` | No matching published release exists. |
| `404` | `platform_not_supported` | The download platform is unsupported. |
| `404` | `artifact_not_found` | The release has no artifact for the platform/architecture pair. |
| `503` | `manifest_unavailable` | No signed manifest envelope is loaded; the response is not cacheable. |
| `500` | `internal_error` | An unexpected request failure occurred. |

## Cache contract

| Response class | Cache behavior |
| --- | --- |
| Release list, latest release, update decision, signed manifest | `public, max-age=60, s-maxage=300` |
| Concrete release and its downloads | `public, max-age=86400, s-maxage=31536000, immutable` |
| Missing signed manifest | `no-store` |

The signed manifest includes an `ETag`. Send `If-None-Match` with the exact received value; an unchanged envelope returns `304` without a body.

## `GET /health`

Reports Worker availability and runtime environment.

```json
{
  "status": "ok",
  "environment": "production",
  "requestId": "74f1136f-19b3-4d11-b6c5-ff36a65e3780"
}
```

`environment` is deployment metadata such as `production` or `preview`. Clients must not use it as an authorization or trust signal.

## `GET /download`

Selects a platform from explicit query parameters or the request `User-Agent`, then redirects to the versioned download route. If no supported platform can be determined, it redirects to the website download section.

| Query | Required | Contract |
| --- | :---: | --- |
| `platform` | no | `android`, `windows`, `linux`, or `macos`; a valid value overrides detection. |
| `arch` | no | Architecture string. Defaults to `universal` for Android/macOS and `x64` for Windows/Linux. |
| `channel` | no | `stable` or `beta`; defaults to `stable`. |

Examples:

```text
GET /download?platform=linux&arch=x64
302 Location: https://get.habiter.dev/api/v1/download/linux/x64

GET /download?platform=android&channel=beta
302 Location: https://get.habiter.dev/api/v1/download/android/universal?channel=beta
```

This endpoint performs selection only. The target API route performs release and artifact lookup.

## `GET /api/v1/manifest`

Returns the signed, published-only update manifest envelope.

Optional request header:

```text
If-None-Match: "release-2026-01.signature-prefix"
```

Successful response:

```json
{
  "schemaVersion": 1,
  "keyId": "release-2026-01",
  "algorithm": "ed25519",
  "payload": "eyJzY2hlbWFWZXJzaW9uIjoxLCJyZWxlYXNlcyI6W119",
  "signature": "base64url-signature"
}
```

`payload` and `signature` are unpadded Base64URL. Verify the signature over the decoded payload bytes before parsing the payload as a release manifest. Do not reserialize JSON before verification. See the [manifest and signature reference](/api/release-manifest).

Responses: `200` envelope, `304` unchanged, or `503 manifest_unavailable`.

## `GET /api/v1/releases`

Lists compact summaries of published releases in one channel, newest build first.

| Query | Default | Accepted values |
| --- | --- | --- |
| `channel` | `stable` | `stable`, `beta` |
| `page` | `1` | Integer from `1` through `100000` |
| `limit` | `20` | Integer from `1` through `100` |

```json
{
  "page": 1,
  "limit": 20,
  "total": 1,
  "releases": [
    {
      "version": "1.5.1",
      "buildNumber": 10501,
      "channel": "stable",
      "publishedAt": "2026-08-17T22:56:31+02:00"
    }
  ]
}
```

An empty valid page returns `200` with an empty `releases` array. Invalid pagination returns `400 invalid_pagination`.

## `GET /api/v1/releases/latest`

Returns the complete newest published release in a channel.

| Query | Default | Accepted values |
| --- | --- | --- |
| `channel` | `stable` | `stable`, `beta` |

Responses: `200` with a [release object](#release-object), `400 invalid_channel`, or `404 release_not_found`.

## `GET /api/v1/releases/{version}`

Returns one complete published release. The response is immutable because a concrete published version must not be rewritten.

```text
GET /api/v1/releases/1.5.1
```

The lookup is by version across published channels. Draft releases are never exposed. Responses: `200` with a release object or `404 release_not_found`.

## `GET /api/v1/releases/{version}/downloads`

Returns only the version and artifact list for one published release.

```json
{
  "version": "1.5.1",
  "artifacts": [
    {
      "platform": "linux",
      "architecture": "x64",
      "fileName": "habiter-1.5.1-linux-x64.tar.gz",
      "signed": false,
      "url": "https://github.com/marius4lui/habiter/releases/download/v1.5.1/habiter-1.5.1-linux-x64.tar.gz",
      "sha256": "777e2d7b995b0daff81cb0e7f0f01c4b1bf067b4e1f079472c182e7eb0eead7a",
      "size": 11820261
    }
  ]
}
```

Responses: `200` or `404 release_not_found`. Additional path segments return `404 not_found`.

## `GET /api/v1/update/{platform}`

Computes an update decision against the latest published release in one channel.

| Input | Required | Accepted values |
| --- | :---: | --- |
| `platform` path | yes | `android`, `windows`, `linux`, `macos` |
| `version` query | yes | Three-component SemVer such as `1.5.1` |
| `build` query | yes | Positive integer |
| `channel` query | no | `stable` or `beta`; defaults to `stable` |

```json
{
  "platform": "android",
  "updateAvailable": true,
  "mandatory": false,
  "current": {
    "version": "1.5.0",
    "buildNumber": 10500
  },
  "target": {
    "version": "1.5.1",
    "buildNumber": 10501
  },
  "minimumSupportedVersion": "1.0.0",
  "download": "/api/v1/download/android"
}
```

`updateAvailable` is true when the target build is greater or the target semantic version is newer. `mandatory` is true only when an update is available and the latest release's `mandatoryAfter` timestamp has passed.

For beta requests, `download` preserves `?channel=beta`. The path is relative to the API origin. Clients that need signed integrity metadata should use the verified manifest rather than trusting the decision response alone.

Responses: `200`, `400 invalid_update_request`, `400 invalid_channel`, or `404 release_not_found`.

## `GET /api/v1/download/{platform}`

## `GET /api/v1/download/{platform}/{architecture}`

Redirects to the matching artifact URL from the latest published release in a channel.

| Input | Default | Accepted values |
| --- | --- | --- |
| `platform` path | none | `android`, `windows`, `linux`, `macos` |
| `architecture` path | Platform default | A manifest architecture such as `universal` or `x64` |
| `channel` query | `stable` | `stable`, `beta` |

Successful response:

```text
302 Location: https://github.com/marius4lui/habiter/releases/download/v1.5.1/habiter-1.5.1-windows-x64.zip
```

Responses: `302`, `400 invalid_channel`, `404 platform_not_supported`, `404 release_not_found`, or `404 artifact_not_found`.

Android releases can contain direct APK and Play Store AAB artifacts with the same architecture. The public download route selects the first published matching artifact, which is the direct-download artifact in the reviewed manifest. Store clients use their store route instead of this endpoint.

## Release object

| Field | Type | Meaning |
| --- | --- | --- |
| `version` | string | Three-component SemVer. |
| `buildNumber` | integer | Monotonic Flutter build number. |
| `channel` | `stable` or `beta` | Publication track. |
| `status` | `published` | Draft entries are filtered before deployment. |
| `publishedAt` | date-time string | Immutable publication time. |
| `minimumSupportedVersion` | string | Oldest supported client version. |
| `mandatoryAfter` | date-time or `null` | Deadline used by update policy. |
| `notes` | note object | `added`, `changed`, `fixed`, and `security` string arrays. |
| `presentation` | localized presentation or absent | German and English release-story content. |
| `media` | media array or absent | Integrity-protected release-story media. |
| `artifacts` | non-empty artifact array | Platform downloads and integrity metadata. |

An artifact includes `platform`, `architecture`, `fileName`, `signed`, optional Android `distribution`, and—when published—`url`, `sha256`, and positive byte `size`.

## Client example

```bash
curl --fail-with-body \
  'https://get.habiter.dev/api/v1/releases?channel=stable&page=1&limit=20'

curl --fail-with-body \
  'https://get.habiter.dev/api/v1/update/linux?version=1.5.0&build=10500'

curl --fail-with-body --location \
  'https://get.habiter.dev/api/v1/download/linux/x64'
```

For update security, fetching successfully is only the first step. Verify the signed manifest envelope and artifact hash before treating remote metadata as trusted.

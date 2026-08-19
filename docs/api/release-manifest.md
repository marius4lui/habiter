# Release manifest and signatures

The release manifest is the reviewed source of truth for Habiter versions, channels, release stories, and artifacts. It feeds release validation, GitHub publication, the Release API, and the in-app updater.

## Three representations

| Representation | Location | Contains drafts | Integrity role |
| --- | --- | :---: | --- |
| Source manifest | `packages/release-core/data/releases.json` | yes | Reviewed repository state. |
| Runtime manifest | `apps/release-api/src/generated/releases.json` | no in production | Worker query and redirect data. |
| Signed envelope | `apps/release-api/src/generated/manifest-envelope.json` | no | Exact bytes trusted by update clients. |

Generated Worker files must come from release tooling. Do not edit them independently of the source manifest.

## Top-level schema

```json
{
  "schemaVersion": 1,
  "releases": []
}
```

The JSON Schema lives at `packages/release-core/schema/releases.schema.json`. Unknown properties are rejected at every defined object level.

## Release fields

| Field | Required | Contract |
| --- | :---: | --- |
| `version` | yes | Three-component SemVer without `v`. |
| `buildNumber` | yes | Positive integer, globally unique, and strictly decreasing in newest-first file order. |
| `channel` | yes | `stable` or `beta`. |
| `status` | yes | `draft` or `published`. |
| `publishedAt` | yes | `null` for drafts; date-time for published releases. |
| `minimumSupportedVersion` | yes | Three-component SemVer. |
| `mandatoryAfter` | yes | Date-time or `null`. |
| `notes` | yes | `added`, `changed`, `fixed`, and `security` arrays. |
| `presentation` | no | Localized German and English release-story content. |
| `media` | no | Declared release-story images. |
| `artifacts` | yes | At least one platform artifact. |

Versions and build numbers are unique. A published release cannot omit its publication timestamp or complete artifact integrity metadata. A draft cannot carry a publication timestamp.

## Artifacts

```json
{
  "platform": "android",
  "architecture": "universal",
  "fileName": "habiter-1.5.1-android-universal.apk",
  "signed": true,
  "distribution": "direct",
  "url": "https://github.com/marius4lui/habiter/releases/download/v1.5.1/habiter-1.5.1-android-universal.apk",
  "sha256": "524e65ac7ed7fcf1d759886748f4effb6b14d39f44af4891de7e71490358961f",
  "size": 63754668
}
```

| Field | Draft | Published | Contract |
| --- | :---: | :---: | --- |
| `platform` | required | required | `android`, `windows`, `linux`, `macos`, `ios`, or `web`. |
| `architecture` | required | required | Non-empty architecture identifier. |
| `fileName` | required | required | Safe basename containing letters, digits, dots, underscores, or hyphens. |
| `signed` | required | required | Whether platform code signing is verified. Android must be `true`. |
| `distribution` | Android required | Android required | `direct` or `play`; forbidden for non-Android artifacts. |
| `url` | optional | required | HTTPS publication URL. |
| `sha256` | optional | required | Lowercase SHA-256 hex digest. |
| `size` | optional | required | Positive byte count. |

Artifact identity is unique within a release by platform, architecture, and file name. Publication enriches declared artifacts from actual files; it must not change platform, architecture, signing, or distribution metadata.

## Localized presentation and media

When `presentation` is present, it contains both `de` and `en`. Each locale provides:

- `headline` and `summary`;
- at most five `highlights`;
- localized `changes` with the same four note categories.

Each highlight has a stable lowercase/hyphen ID, title, description, icon, and optional `mediaId`. A referenced media ID must exist in the release's `media` array.

Media declarations include an ID, safe file name, and one of `image/avif`, `image/jpeg`, `image/png`, or `image/webp`. Publication adds immutable HTTPS URL, SHA-256, and byte size from the actual file.

## Signing envelope

The public endpoint returns:

```json
{
  "schemaVersion": 1,
  "keyId": "release-2026-01",
  "algorithm": "ed25519",
  "payload": "unpadded-base64url",
  "signature": "unpadded-base64url"
}
```

The signing process:

1. filters the manifest to published releases;
2. serializes `{schemaVersion, releases}` once with deterministic `JSON.stringify` ordering;
3. signs those UTF-8 bytes with Ed25519;
4. encodes payload and signature as unpadded Base64URL;
5. publishes the envelope and derives its `ETag` from key ID plus signature prefix.

Clients must:

1. require envelope schema version `1` and algorithm `ed25519`;
2. select the trusted 32-byte raw public key by exact `keyId`;
3. Base64URL-decode payload and signature;
4. verify the signature over the untouched payload bytes;
5. parse JSON only after verification;
6. validate the supported manifest schema and reject unpublished entries;
7. select artifacts from the verified object;
8. verify downloaded artifact size, SHA-256, and platform signature as applicable.

Do not decode and reserialize the payload before signature verification. JSON whitespace or key-order changes produce different signed bytes.

## Key ring and rotation

`HABITER_UPDATE_PUBLIC_KEYS` is a JSON object from key ID to the canonical unpadded Base64URL encoding of exactly 32 raw Ed25519 public-key bytes. `RELEASE_MANIFEST_KEY_ID` selects the active signing key.

Rotation requires an overlap release:

1. ship a client that trusts current and next public keys;
2. wait until that client is the minimum supported baseline;
3. switch the server-side signing key ID and private key;
4. verify both cached old envelopes and new envelopes during the overlap;
5. remove the old client key only in a later release.

The private PKCS#8 key exists only in the protected release environment and operator-controlled encrypted backups. It must never enter Worker variables, application assets, logs, documentation examples, or repository history.

## Validation commands

From the repository root:

```bash
pnpm release:validate
pnpm release:test
pnpm --filter @habiter/release-api check
```

Use [release operations](/release-operations) for publication and recovery. Use the [Release API reference](/api/release-api) for HTTP behavior.

# Personal Sync authentication

`@habiter/sync-auth` is the runtime-neutral single-user authentication core
shared by the Docker/SQLite and Worker/D1 services. It provides one-time setup,
password proof, OAuth-style authorization codes with PKCE, short-lived access
tokens, rotating device refresh sessions, revocation, and rate limiting.

It does not provide registration, browser pages, HTTP routing, native deep
links, or secure client storage. Those layers must preserve this protocol's
boundaries rather than accepting raw passwords or inventing alternate token
flows.

## Exactly one account

An instance starts without an account and accepts one explicit operator setup.
The storage singleton constraint is authoritative: every later setup attempt
fails, including concurrent attempts. There is no registration endpoint and no
account list.

The username is not treated as secret. Login still returns the same challenge
shape and generic failure for an unknown username. A deterministic fake salt,
derived under the instance key, avoids a stable-salt-versus-random-salt account
existence signal.

## Password-key protocol

The raw password remains on the setup/login client. The client derives a
32-byte password key with PBKDF2-HMAC-SHA-256, a random 16-byte per-account
salt, and exactly 600,000 iterations. This matches the current
[OWASP PBKDF2-HMAC-SHA-256 work factor](https://github.com/OWASP/CheatSheetSeries/blob/master/cheatsheets/Password_Storage_Cheat_Sheet.md).
Passwords are restricted to 12–1,024 characters before derivation to bound
accidental denial-of-service inputs.

During the one-time instance setup, the client sends the derived password key
over the required trusted HTTPS or loopback channel. The server immediately
encrypts it with AES-256-GCM under a random instance key supplied outside the
database. The database stores only salt, work factor, IV, and authenticated
ciphertext. It never stores the password or an unwrapped password key.

For login, the server issues an expiring single-use challenge. The client
returns HMAC-SHA-256 over a canonical message binding:

- challenge ID and username;
- PKCE S256 challenge and state;
- exact redirect URI and instance attempt ID;
- device ID and protocol purpose/version.

The server decrypts the password key only in request memory, recomputes the
proof, compares without an early byte exit, and consumes the challenge whether
the proof succeeds or fails. A database compromise alone cannot test password
guesses. A simultaneous database and instance-key compromise permits
impersonation and therefore requires instance-key rotation, session revocation,
and password reset.

## Authorization code and PKCE

Only RFC 7636 S256 is accepted. The verifier is 43–128 unreserved characters;
`plain` and downgrade fallback are unsupported. The
[RFC 7636 requirements](https://www.rfc-editor.org/info/rfc7636/) call for at
least 256 bits of verifier entropy, so the helper generates 32 random bytes and
base64url-encodes them.

Authorization codes are random 256-bit values. Only their SHA-256 hashes enter
storage. A code is bound to PKCE challenge, state, exact redirect URI, attempt,
device, account, and password version. Redemption atomically consumes it before
checking expiry or bindings, so even a failed redemption burns the code.
Redirect URIs must be HTTPS, except explicit loopback HTTP, and may not contain
userinfo or a fragment.

## Tokens and device sessions

Access tokens are signed opaque-to-clients `v1` envelopes containing issuer,
audience, subject, device, password version, issued/expiry times, and a random
token ID. They live for five minutes by default and are never persisted.
Signature, issuer, audience, and expiry are checked on every use.

Refresh tokens are random 256-bit bearer credentials. Storage receives only a
SHA-256 hash. They have a fixed 30-day absolute lifetime by default and rotate
on every use. Rotation atomically marks the prior hash and inserts its
replacement. Reusing a rotated token is explicit replay evidence and revokes
every refresh session for that device. Individual-device and revoke-all
operations are supported.

Password change uses a storage compare-and-swap, increments the password
version, and revokes all refresh sessions. A refresh surviving an interrupted
revocation still fails because its stored password version no longer matches.
Already issued access tokens remain valid only until their short expiry.

## Failure and logging contract

Login proof, unknown-account, expired challenge, and consumed-challenge failures
all return `authentication_failed`. Failure counters use a hashed username
scope. Five failures start a 15-second cooldown, with exponential growth capped
at five minutes. Successful proof clears the counter.

The core has no logging calls. Error serialization uses an allow-list of public
codes and fixed messages; it never echoes an exception message. HTTP layers
must call `redactAuthError` and must not log request bodies, proofs, codes,
access tokens, refresh tokens, instance keys, or decrypted password keys.

## Threat model and focused review

| Threat | Control | Residual boundary |
| --- | --- | --- |
| Database theft | Client KDF; AES-GCM wrapped password key; hashed one-time and refresh credentials | Database plus instance key permits impersonation. |
| Login/code replay | Atomic single-use records with expiry and complete request binding | A live authorized browser session remains trusted. |
| Authorization interception | Mandatory PKCE S256, state, redirect, and attempt binding | TLS and native redirect ownership remain client/platform duties. |
| Refresh theft | Hash-only storage, one-use rotation, replay-triggered device revocation | Theft before the legitimate use can win once. |
| Timing oracle | Fixed-shape failures and non-early byte comparison | Network/storage timing still needs operational monitoring. |
| Online guessing | Generic failures and persistent exponential cooldown | Distributed source throttling belongs to the HTTP/edge layer. |
| Secret leakage | No core logging, fixed redaction, persistence inspection tests | Host memory and operator secret handling remain trusted. |

The review specifically rejects raw SHA password storage, a server-side
600,000-round KDF on every Worker login, PKCE `plain`, reusable codes, stored
bearer tokens, sliding refresh expiry, and error-message passthrough.

## Worker compatibility and benchmarks

Cloudflare documents a [10 ms CPU allowance per Free Worker request](https://developers.cloudflare.com/workers/platform/limits/)
and provides Web Crypto implementations for
[PBKDF2, AES-GCM, HMAC, and SHA-256](https://developers.cloudflare.com/workers/runtime-apis/web-crypto/).
The expensive 600,000-round password KDF therefore runs on the client, not in
the Worker.

The automated gate measures two separate budgets:

| Workload | Gate |
| --- | ---: |
| Client PBKDF2-HMAC-SHA-256, 600,000 rounds | under 2,000 ms on CI hardware |
| Worker AES wrap/unwrap, two HMACs, and two constant comparisons | under 10 ms inside Miniflare/workerd |
| SQLite setup, challenge, proof, and code creation using a pre-derived key | under 100 ms wall time |

These are regression ceilings, not production telemetry. Worker deployment
must monitor CPU outcomes and raise no limit merely to hide a cryptographic
regression.

## Validation

```sh
pnpm sync:auth:check
```

The same behavioral suite runs against SQLite and a bundled Worker using local
D1. It covers setup races, generic failures, expiry, atomic single use, PKCE and
redirect binding, access verification, rotation/replay, device/global
revocation, password change, cooldown recovery, persistence inspection,
constant comparison, redaction, and both crypto benchmarks.

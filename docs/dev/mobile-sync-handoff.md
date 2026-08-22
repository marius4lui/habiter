# Mobile Personal Sync handoff

`mobile.habiter.dev` is a stateless bridge between an operator-hosted Personal Sync Beta authorization page and the native Habiter app. It is deliberately separate from every sync instance. It has no Worker script, database, cookies, authentication state, token redemption, analytics, or third-party assets and never proxies API traffic.

The handoff source lives in `apps/mobile-handoff`. This child adds the source and platform contracts only; it does not deploy the domain or claim physical-device verification.

## Privacy boundary

The sync instance redirects to this exact registered URI:

```text
https://mobile.habiter.dev/auth/callback#code=<short-lived-code>&state=<opaque-state>
```

The authorization code and state are placed in the fragment. Browsers do not include fragments in HTTP requests, referrers, or Cloudflare access logs. The static page accepts exactly one bounded base64url `code` and one bounded base64url `state`, immediately removes the fragment from the address bar, and uses them only to open the app. It makes no network request and clears its in-page fallback after 60 seconds.

Access tokens, refresh tokens, usernames, passwords, password-derived keys, PKCE verifiers, habit data, device data, and recovery material are never accepted by or sent through this site. The native client introduced separately validates origin, path, state, expiry, and replay before exchanging the code directly with the configured personal instance.

## Automatic link and fallback

Android declares a verified App Link for the exact HTTPS host and `/auth/callback` path. iOS declares `applinks:mobile.habiter.dev`. When the installed platform association is valid, the HTTPS callback opens Habiter directly.

If the browser stays on the page—for example because Habiter is not installed, an association is not yet cached, or the browser does not support the platform handoff—the page automatically tries the reverse-DNS custom scheme `dev.habiter.app://auth/callback`. The visible **Open Habiter** button repeats that same action explicitly. Installation guidance points to the first-party smart-download domain. After installation, the user starts a fresh connection in Habiter; old callback material must not be reused.

The older `habiter://` handler remains temporarily for existing Classly compatibility. Personal Sync uses the collision-resistant reverse-DNS fallback only.

## Association identities

Android `assetlinks.json` contains package `com.habiter.app` and the public SHA-256 certificate fingerprint extracted from the checksummatched v1.7.4 direct universal APK. The direct APK fingerprint is:

```text
82:8F:35:B5:48:94:40:98:E9:B5:FC:41:78:33:22:74:94:07:52:2B:FB:5A:52:B3:11:A6:F0:17:9C:20:F5:C8
```

Google Play App Signing can use a different public app-signing certificate. Before claiming Store-build verification, obtain that fingerprint from Play Console, append it to `sha256_cert_fingerprints`, and verify an installed Store build. Do not substitute an upload-key fingerprint by assumption.

The repository currently has no verifiable production Apple Team ID or signed iOS release. Local builds therefore generate a syntactically valid `0000000000.com.example.habiter` placeholder. A production build fails closed until `HABITER_APPLE_APP_ID` supplies the exact `TEAMID.bundle.identifier` from the signed app:

```bash
HABITER_APPLE_APP_ID=ABCDE12345.com.example.habiter \
  pnpm --filter @habiter/mobile-handoff build:production
```

The value is public association metadata, not a credential. Confirm that the bundle identifier, Team ID, provisioning profile, `Runner.entitlements`, and generated AASA all agree before deployment.

## Local build and checks

From the repository root:

```bash
pnpm install --frozen-lockfile
pnpm mobile:handoff:check
```

The check builds static output, validates both association documents, exercises valid and adversarial fragments, proves that production Apple placeholders fail closed, starts a local Wrangler server, verifies real response headers and MIME types, checks a missing route, and performs a Cloudflare deployment dry run.

For manual inspection:

```bash
pnpm --filter @habiter/mobile-handoff dev
```

Open the printed local URL and `/auth/callback` with a dummy `code`/`state` fragment. Browser developer tools must show no requests after the initial first-party HTML, JavaScript, and CSS assets. The callback HTML response must never contain the fragment values.

## Security headers and caching

The checked-in `_headers` contract applies a restrictive policy to all assets:

- `default-src 'none'`, with only same-origin script and style exceptions;
- `connect-src 'none'`, `form-action 'none'`, `frame-ancestors 'none'`, and `base-uri 'none'`;
- `Referrer-Policy: no-referrer`, `X-Frame-Options: DENY`, and `nosniff`;
- restrictive Permissions, opener, and resource policies;
- `no-store` for HTML and callbacks.

The two association documents are the only cacheable responses and revalidate after one hour. They must be served over HTTPS at their exact `.well-known` paths with `application/json`, status 200, and no redirect.

## Platform verification runbook

After deploying a preview or production-equivalent custom domain with the correct public identities, first verify transport without following redirects:

```bash
curl --fail --include --max-redirs 0 https://mobile.habiter.dev/.well-known/assetlinks.json
curl --fail --include --max-redirs 0 https://mobile.habiter.dev/.well-known/apple-app-site-association
```

On a connected Android device with the matching signed APK:

```bash
adb shell pm verify-app-links --re-verify com.habiter.app
adb shell pm get-app-links com.habiter.app
adb shell am start -W -a android.intent.action.VIEW \
  -d 'https://mobile.habiter.dev/auth/callback#code=ccccccccccccccccccccccccccccccccccccccccccc&state=ssssssssssssssssssssssssssssssss'
adb shell am start -W -a android.intent.action.VIEW \
  -d 'dev.habiter.app://auth/callback#code=ccccccccccccccccccccccccccccccccccccccccccc&state=ssssssssssssssssssssssssssssssss'
```

Record the package, signing fingerprint, Android version, verification state, resolved activity, cold/warm result, and browser used. A chooser, browser landing, wrong activity, or mismatched fingerprint is a failed association, not a pass.

For iOS, use an installed build signed with the exact Team ID represented by the AASA. Confirm the Associated Domains entitlement in the signed app, remove and reinstall after association changes, and open the HTTPS callback from Notes or another domain in Safari for both cold and warm states. Safari navigation from the same domain can intentionally remain in Safari, so also exercise the visible custom-scheme button. Record the iOS version, device/simulator, signing identity, cold/warm behavior, and any Apple CDN diagnostics. Do not claim iOS Universal Link support while the placeholder App ID remains.

## Update and rollback

Association changes affect installed clients and cached platform metadata. Add new signing identities before releasing a newly signed app, retain old fingerprints through the supported upgrade window, and narrow paths rather than broadening the domain. Deploy the static assets only after `build:production` and all checks pass.

Rollback by redeploying the last reviewed static revision. Never redirect either `.well-known` document. If an association identity is wrong, keep the HTTPS fallback page available, remove the incorrect identity, deploy the corrected document, and repeat platform verification after reinstalling the app. No sync data or credentials need migration because this site owns none.

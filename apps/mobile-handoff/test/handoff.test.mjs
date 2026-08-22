import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { spawnSync } from "node:child_process";
import test from "node:test";
import { customSchemeUrl, parseCallbackFragment } from "../src/assets/callback.js";

const root = new URL("../", import.meta.url);
const read = (path) => readFile(new URL(path, root), "utf8");

test("callback accepts only bounded code/state fragment data", () => {
  const code = "c".repeat(43);
  const state = "s".repeat(32);
  assert.deepEqual(parseCallbackFragment(`#code=${code}&state=${state}`), { code, state });
  assert.equal(customSchemeUrl({ code, state }), `dev.habiter.app://auth/callback#code=${code}&state=${state}`);
  for (const value of [
    `?code=${code}&state=${state}`,
    `#code=${code}&state=${state}&token=forbidden`,
    `#code=${code}&code=${code}&state=${state}`,
    `#code=short&state=${state}`,
    `#code=${code}&state=bad%20state`,
    `#access_token=${code}&state=${state}`,
  ]) assert.throws(() => parseCallbackFragment(value), /invalid_callback/);
});

test("handoff is static, first-party, and storage-free", async () => {
  const callback = await read("src/auth/callback.html");
  const home = await read("src/index.html");
  const script = await read("src/assets/callback.js");
  for (const html of [callback, home]) {
    assert.doesNotMatch(html, /<script(?![^>]*\bsrc=)/i);
    assert.doesNotMatch(html, /<style|<iframe|<form|<input/i);
    assert.doesNotMatch(html, /https:\/\/(?!get-the\.habiter\.dev)/i);
  }
  assert.doesNotMatch(script, /fetch\(|XMLHttpRequest|sendBeacon|localStorage|sessionStorage|document\.cookie|console\./);
  assert.doesNotMatch(script, /access_token|refresh_token|password|verifier/i);
});

test("association documents are narrow and use verified native identities", async () => {
  const android = JSON.parse(await read("dist/.well-known/assetlinks.json"));
  assert.deepEqual(android[0].relation, ["delegate_permission/common.handle_all_urls"]);
  assert.equal(android[0].target.package_name, "com.habiter.app");
  assert.deepEqual(android[0].target.sha256_cert_fingerprints, ["82:8F:35:B5:48:94:40:98:E9:B5:FC:41:78:33:22:74:94:07:52:2B:FB:5A:52:B3:11:A6:F0:17:9C:20:F5:C8"]);
  const apple = JSON.parse(await read("dist/.well-known/apple-app-site-association"));
  assert.deepEqual(apple.applinks.details[0].components.map((item) => item["/"]), ["/auth/callback"]);
  assert.match(apple.applinks.details[0].appIDs[0], /^[A-Z0-9]{10}\.[A-Za-z0-9.-]+$/);
});

test("production association build fails closed without a real Apple App ID", () => {
  const environment = { ...process.env };
  delete environment.HABITER_APPLE_APP_ID;
  const result = spawnSync(process.execPath, ["scripts/build.mjs", "--production"], {
    cwd: root,
    encoding: "utf8",
    env: environment,
  });
  assert.equal(result.status, 2);
  assert.match(result.stderr, /HABITER_APPLE_APP_ID/);
});

test("native projects declare the verified link and collision-resistant fallback", async () => {
  const android = await read("../habiter/android/app/src/main/AndroidManifest.xml");
  const info = await read("../habiter/ios/Runner/Info.plist");
  const entitlements = await read("../habiter/ios/Runner/Runner.entitlements");
  assert.match(android, /android:autoVerify="true"/);
  assert.match(android, /android:host="mobile\.habiter\.dev"/);
  assert.match(android, /android:path="\/auth\/callback"/);
  assert.match(android, /android:scheme="dev\.habiter\.app"/);
  assert.match(info, /<string>dev\.habiter\.app<\/string>/);
  assert.match(entitlements, /<string>applinks:mobile\.habiter\.dev<\/string>/);
});

test("security headers forbid data egress, framing, and referrers", async () => {
  const headers = await read("src/_headers");
  for (const contract of [
    "default-src 'none'",
    "connect-src 'none'",
    "frame-ancestors 'none'",
    "form-action 'none'",
    "Referrer-Policy: no-referrer",
    "X-Content-Type-Options: nosniff",
    "X-Frame-Options: DENY",
    "Cache-Control: no-store",
  ]) assert.match(headers, new RegExp(contract.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")));
});

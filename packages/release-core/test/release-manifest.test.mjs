import assert from "node:assert/strict";
import { createHash, generateKeyPairSync, verify } from "node:crypto";
import { test } from "node:test";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import {
  assertTagMatches,
  enrichRelease,
  finalizeRelease,
  parseRawPublicKeyRing,
  parsePubspecVersion,
  readJson,
  renderNotes,
  signManifestEnvelope,
  validateManifest
} from "../src/release-manifest.mjs";

const manifestPath = new URL("../data/releases.json", import.meta.url);
const schemaPath = new URL("../schema/releases.schema.json", import.meta.url);

test("the checked-in release manifest is valid", async () => {
  await validateManifest(await readJson(manifestPath), await readJson(schemaPath));
});

test("tag, pubspec version and build number must agree", async () => {
  const manifest = await readJson(manifestPath);
  const pubspec = parsePubspecVersion(await readFile(new URL("../../../apps/habiter/pubspec.yaml", import.meta.url), "utf8"));
  assert.equal(
    assertTagMatches({ tag: `v${pubspec.version}`, pubspec, manifest }).buildNumber,
    pubspec.buildNumber,
  );
  assert.throws(() => assertTagMatches({ tag: "v0.0.0", pubspec, manifest }), /does not match/);
});

test("the published v1.5 release carries the complete update experience contract", async () => {
  const manifest = await readJson(manifestPath);
  const release = manifest.releases.find((item) => item.version === "1.5.0");
  assert.equal(release?.buildNumber, 10500);
  assert.equal(release?.channel, "stable");
  assert.equal(release?.status, "published");
  assert.deepEqual(Object.keys(release?.presentation ?? {}).sort(), ["de", "en"]);
  assert.equal(release?.presentation.de.highlights.length, 5);
  assert.equal(release?.presentation.en.highlights.length, 5);
  assert.deepEqual(
    release?.artifacts.filter((item) => item.platform === "android").map((item) => item.distribution).sort(),
    ["direct", "play"]
  );
  assert.deepEqual(
    new Set(release?.artifacts.map((item) => item.platform)),
    new Set(["android", "windows", "linux", "macos"])
  );
});

test("release notes are deterministic", async () => {
  const manifest = await readJson(manifestPath);
  const notes = renderNotes(manifest.releases[0]);
  assert.doesNotMatch(notes, /^# Habiter/m);
  assert.match(notes, /^## (Added|Changed|Fixed|Security)/m);
  assert.equal(notes, renderNotes(manifest.releases[0]));
  assert.match(notes, /Desktop signing/);
});

test("duplicate versions are rejected", async () => {
  const manifest = await readJson(manifestPath);
  const schema = await readJson(schemaPath);
  manifest.releases.push(structuredClone(manifest.releases[0]));
  await assert.rejects(validateManifest(manifest, schema), /Duplicate version/);
});

test("primary installer artifacts require an explicit, unambiguous format", async () => {
  const manifest = await readJson(manifestPath);
  const schema = await readJson(schemaPath);
  const windows = manifest.releases[0].artifacts.find((item) => item.platform === "windows");
  windows.format = "zip";
  windows.primary = true;
  await assert.doesNotReject(validateManifest(manifest, schema));

  const missingFormat = structuredClone(manifest);
  delete missingFormat.releases[0].artifacts.find((item) => item.platform === "windows").format;
  await assert.rejects(validateManifest(missingFormat, schema), /Primary artifact requires a format/);

  const ambiguous = structuredClone(manifest);
  ambiguous.releases[0].artifacts.push({
    ...ambiguous.releases[0].artifacts.find((item) => item.platform === "windows"),
    fileName: "habiter-alternative-windows-x64.zip"
  });
  await assert.rejects(validateManifest(ambiguous, schema), /Ambiguous primary artifact: windows:x64/);
});

test("published assets require HTTPS and complete integrity metadata", async () => {
  const manifest = await readJson(manifestPath);
  const schema = await readJson(schemaPath);
  const unsafe = structuredClone(manifest);
  const publishedIndex = unsafe.releases.findIndex((release) => release.status === "published");
  unsafe.releases[publishedIndex].artifacts[0].url = "http://example.com/habiter.apk";
  await assert.rejects(validateManifest(unsafe, schema), /must use HTTPS/);

  const missingDistribution = structuredClone(manifest);
  delete missingDistribution.releases[0].artifacts[0].distribution;
  await assert.rejects(validateManifest(missingDistribution, schema), /requires a distribution/);
});

test("localized highlights may reference only declared release media", async () => {
  const manifest = await readJson(manifestPath);
  const schema = await readJson(schemaPath);
  const invalid = structuredClone(manifest);
  invalid.releases[0].presentation = {
    de: {
      headline: "Neu",
      summary: "Zusammenfassung",
      highlights: [{ id: "one", title: "Eins", description: "Text", icon: "update", mediaId: "missing" }],
      changes: { added: [], changed: [], fixed: [], security: [] }
    },
    en: {
      headline: "New",
      summary: "Summary",
      highlights: [],
      changes: { added: [], changed: [], fixed: [], security: [] }
    }
  };
  await assert.rejects(validateManifest(invalid, schema), /Unknown media id missing/);
});

test("release enrichment hashes and publishes declared story media", async (context) => {
  const directory = await mkdtemp(path.join(tmpdir(), "habiter-release-media-"));
  context.after(() => rm(directory, { recursive: true, force: true }));
  const manifest = await readJson(manifestPath);
  const release = structuredClone(
    manifest.releases.find((item) => item.presentation != null),
  );
  release.artifacts = [release.artifacts[0]];
  release.media = [{ id: "update-center", fileName: "update-center.webp", mimeType: "image/webp" }];
  release.presentation.de.highlights[0].mediaId = "update-center";
  release.presentation.en.highlights[0].mediaId = "update-center";
  const artifactBytes = Buffer.from("signed-apk-fixture");
  const mediaBytes = Buffer.from("verified-webp-fixture");
  await writeFile(path.join(directory, release.artifacts[0].fileName), artifactBytes);
  await writeFile(path.join(directory, release.media[0].fileName), mediaBytes);

  const enriched = await enrichRelease({
    release,
    artifactDirectory: directory,
    repository: "example/habiter",
    publishedAt: "2026-08-17T12:00:00Z"
  });

  assert.equal(enriched.status, "published");
  assert.equal(enriched.media[0].size, mediaBytes.length);
  assert.equal(enriched.media[0].sha256, createHash("sha256").update(mediaBytes).digest("hex"));
  assert.equal(
    enriched.media[0].url,
    "https://github.com/example/habiter/releases/download/v1.5.0/update-center.webp"
  );
  assert.equal(enriched.artifacts[0].size, artifactBytes.length);
});

test("signed manifests are deterministic, published-only and tamper evident", async () => {
  const manifest = await readJson(manifestPath);
  const draft = structuredClone(manifest.releases[0]);
  draft.version = "9.0.0";
  draft.buildNumber = 90000;
  draft.status = "draft";
  draft.publishedAt = null;
  const source = { schemaVersion: 1, releases: [draft, ...manifest.releases] };
  const { privateKey, publicKey } = generateKeyPairSync("ed25519");
  const privatePem = privateKey.export({ format: "pem", type: "pkcs8" });
  const publicPem = publicKey.export({ format: "pem", type: "spki" });

  const first = signManifestEnvelope({ manifest: source, keyId: "test-2026-01", privateKey: privatePem });
  const second = signManifestEnvelope({ manifest: source, keyId: "test-2026-01", privateKey: privatePem });
  assert.deepEqual(first, second);
  const payload = Buffer.from(first.payload, "base64url");
  const signature = Buffer.from(first.signature, "base64url");
  const signedManifest = JSON.parse(payload.toString("utf8"));
  assert.equal(signedManifest.releases.some((release) => release.version === "9.0.0"), false);
  assert.equal(verify(null, payload, publicPem, signature), true);

  const tampered = { ...first, payload: `${first.payload.slice(0, -1)}${first.payload.endsWith("A") ? "B" : "A"}` };
  assert.equal(
    verify(null, Buffer.from(tampered.payload, "base64url"), publicPem, signature),
    false,
  );
});

test("manifest verification supports explicit key rotation", async () => {
  const manifest = await readJson(manifestPath);
  const oldPair = generateKeyPairSync("ed25519");
  const nextPair = generateKeyPairSync("ed25519");
  const pem = (key, type) => key.export({ format: "pem", type });
  const oldEnvelope = signManifestEnvelope({
    manifest,
    keyId: "release-2026-01",
    privateKey: pem(oldPair.privateKey, "pkcs8")
  });
  const nextEnvelope = signManifestEnvelope({
    manifest,
    keyId: "release-2027-01",
    privateKey: pem(nextPair.privateKey, "pkcs8")
  });
  const oldPayload = Buffer.from(oldEnvelope.payload, "base64url");
  const nextPayload = Buffer.from(nextEnvelope.payload, "base64url");
  assert.equal(verify(null, oldPayload, oldPair.publicKey, Buffer.from(oldEnvelope.signature, "base64url")), true);
  assert.equal(verify(null, nextPayload, nextPair.publicKey, Buffer.from(nextEnvelope.signature, "base64url")), true);
  assert.equal(verify(null, nextPayload, oldPair.publicKey, Buffer.from(nextEnvelope.signature, "base64url")), false);
});

test("embedded raw public-key rings are canonical and contain the active key", () => {
  const raw = Buffer.alloc(32, 7).toString("base64url");
  assert.deepEqual(parseRawPublicKeyRing(JSON.stringify({ "release-2026-01": raw }), "release-2026-01"), {
    "release-2026-01": raw
  });
  assert.throws(() => parseRawPublicKeyRing("{}"), /non-empty/);
  assert.throws(() => parseRawPublicKeyRing(JSON.stringify({ bad: "not+base64" })), /Base64URL/);
  assert.throws(
    () => parseRawPublicKeyRing(JSON.stringify({ "release-2026-01": raw }), "release-2027-01"),
    /active key/
  );
});

test("runtime metadata finalizes a release without changing its channel contract", async () => {
  const manifest = await readJson(manifestPath);
  const source = structuredClone(manifest.releases[0]);
  source.channel = "beta";
  const runtime = structuredClone(source);
  runtime.channel = "stable";
  runtime.status = "published";
  runtime.publishedAt = "2026-08-17T12:00:00Z";
  runtime.artifacts = runtime.artifacts.map((artifact, index) => ({
    ...artifact,
    url: `https://example.com/${artifact.fileName}`,
    sha256: String(index).padStart(64, "a"),
    size: index + 1
  }));

  const finalized = finalizeRelease(
    { schemaVersion: 1, releases: [source] },
    { schemaVersion: 1, releases: [runtime] },
    source.version
  ).releases[0];

  assert.equal(finalized.channel, "beta");
  assert.equal(finalized.status, "published");
  assert.equal(finalized.publishedAt, runtime.publishedAt);
  assert.equal(finalized.artifacts[0].url, runtime.artifacts[0].url);
});

test("release finalization rejects incomplete or mismatched runtime artifacts", async () => {
  const manifest = await readJson(manifestPath);
  const source = structuredClone(manifest.releases[0]);
  const runtime = {
    ...structuredClone(source),
    status: "published",
    publishedAt: "2026-08-17T12:00:00Z",
    artifacts: []
  };
  assert.throws(
    () => finalizeRelease({ schemaVersion: 1, releases: [source] }, { schemaVersion: 1, releases: [runtime] }, source.version),
    /incomplete/
  );
});

import assert from "node:assert/strict";
import { generateKeyPairSync } from "node:crypto";
import { test } from "node:test";
import { readFile } from "node:fs/promises";
import {
  assertTagMatches,
  compareVersions,
  finalizeRelease,
  manifestPayloadBytes,
  parsePubspecVersion,
  publishedManifest,
  readJson,
  renderNotes,
  signManifestEnvelope,
  validateManifest,
  verifyManifestEnvelope
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

test("version comparison is numeric and release notes are deterministic", async () => {
  const manifest = await readJson(manifestPath);
  const notes = renderNotes(manifest.releases[0]);
  assert.ok(compareVersions("1.10.0", "1.9.9") > 0);
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

test("published assets require HTTPS and complete integrity metadata", async () => {
  const manifest = await readJson(manifestPath);
  const schema = await readJson(schemaPath);
  const unsafe = structuredClone(manifest);
  unsafe.releases[0].artifacts[0].url = "http://example.com/habiter.apk";
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
  assert.deepEqual(manifestPayloadBytes(source), manifestPayloadBytes(source));
  assert.equal(publishedManifest(source).releases.some((release) => release.status === "draft"), false);

  const verified = verifyManifestEnvelope(first, { "test-2026-01": publicPem });
  assert.equal(verified.manifest.releases.some((release) => release.version === "9.0.0"), false);
  assert.deepEqual(verified.payload, manifestPayloadBytes(source));

  const tampered = { ...first, payload: `${first.payload.slice(0, -1)}${first.payload.endsWith("A") ? "B" : "A"}` };
  assert.throws(
    () => verifyManifestEnvelope(tampered, { "test-2026-01": publicPem }),
    /signature verification failed/
  );
});

test("manifest verification supports explicit key rotation", async () => {
  const manifest = await readJson(manifestPath);
  const oldPair = generateKeyPairSync("ed25519");
  const nextPair = generateKeyPairSync("ed25519");
  const pem = (key, type) => key.export({ format: "pem", type });
  const ring = {
    "release-2026-01": pem(oldPair.publicKey, "spki"),
    "release-2027-01": pem(nextPair.publicKey, "spki")
  };
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
  assert.equal(verifyManifestEnvelope(oldEnvelope, ring).manifest.schemaVersion, 1);
  assert.equal(verifyManifestEnvelope(nextEnvelope, ring).manifest.schemaVersion, 1);
  assert.throws(() => verifyManifestEnvelope(nextEnvelope, { "release-2026-01": ring["release-2026-01"] }), /Unknown/);
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

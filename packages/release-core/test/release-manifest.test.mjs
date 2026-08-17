import assert from "node:assert/strict";
import { test } from "node:test";
import { readFile } from "node:fs/promises";
import {
  assertTagMatches,
  compareVersions,
  finalizeRelease,
  parsePubspecVersion,
  readJson,
  renderNotes,
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

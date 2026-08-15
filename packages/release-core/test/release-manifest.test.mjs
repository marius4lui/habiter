import assert from "node:assert/strict";
import { test } from "node:test";
import { readFile } from "node:fs/promises";
import {
  assertTagMatches,
  compareVersions,
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
  assert.equal(assertTagMatches({ tag: "v1.0.0", pubspec, manifest }).buildNumber, 10000);
  assert.throws(() => assertTagMatches({ tag: "v1.0.1", pubspec, manifest }), /does not match/);
});

test("version comparison is numeric and release notes are deterministic", async () => {
  const manifest = await readJson(manifestPath);
  assert.ok(compareVersions("1.10.0", "1.9.9") > 0);
  assert.match(renderNotes(manifest.releases[0]), /^# Habiter 1\.0\.0/m);
  assert.match(renderNotes(manifest.releases[0]), /Desktop signing/);
});

test("duplicate versions are rejected", async () => {
  const manifest = await readJson(manifestPath);
  const schema = await readJson(schemaPath);
  manifest.releases.push(structuredClone(manifest.releases[0]));
  await assert.rejects(validateManifest(manifest, schema), /Duplicate version/);
});

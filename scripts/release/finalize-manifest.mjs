#!/usr/bin/env node
import { writeFile } from "node:fs/promises";
import {
  finalizeRelease,
  readJson,
  validateManifest
} from "../../packages/release-core/src/release-manifest.mjs";

const [version, runtimePath] = process.argv.slice(2);
if (!version || !runtimePath) {
  throw new Error("Usage: finalize-manifest.mjs <version> <runtime-manifest>");
}

const manifestUrl = new URL("../../packages/release-core/data/releases.json", import.meta.url);
const schemaUrl = new URL("../../packages/release-core/schema/releases.schema.json", import.meta.url);
const manifest = await readJson(manifestUrl);
const runtimeManifest = await readJson(runtimePath);
const finalized = finalizeRelease(manifest, runtimeManifest, version);
await validateManifest(finalized, await readJson(schemaUrl));
await writeFile(manifestUrl, `${JSON.stringify(finalized, null, 2)}\n`);
console.log(`Finalized release ${version} in the authoritative manifest.`);

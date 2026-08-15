#!/usr/bin/env node
import { readFile } from "node:fs/promises";
import {
  assertTagMatches,
  parsePubspecVersion,
  readJson,
  validateManifest
} from "../../packages/release-core/src/release-manifest.mjs";

const root = new URL("../../", import.meta.url);
const manifest = await readJson(new URL("packages/release-core/data/releases.json", root));
const schema = await readJson(new URL("packages/release-core/schema/releases.schema.json", root));
await validateManifest(manifest, schema);

const tagArgument = process.argv.find((argument) => argument.startsWith("--tag="));
if (tagArgument) {
  const pubspec = parsePubspecVersion(await readFile(new URL("apps/habiter/pubspec.yaml", root), "utf8"));
  assertTagMatches({ tag: tagArgument.slice(6), pubspec, manifest });
}

console.log(`Validated ${manifest.releases.length} release(s).`);

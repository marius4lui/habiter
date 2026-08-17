#!/usr/bin/env node
import { generateKeyPairSync } from "node:crypto";
import { writeFile } from "node:fs/promises";
import {
  readJson,
  signManifestEnvelope,
  validateManifest
} from "../../packages/release-core/src/release-manifest.mjs";

const [input, output, ...flags] = process.argv.slice(2);
if (!input || !output) {
  throw new Error("Usage: sign-manifest.mjs <manifest> <output> [--ephemeral]");
}

const ephemeral = flags.includes("--ephemeral");
const encodedKey = process.env.RELEASE_MANIFEST_PRIVATE_KEY_BASE64;
let privateKey;
let keyId = process.env.RELEASE_MANIFEST_KEY_ID;
if (encodedKey && keyId) {
  privateKey = Buffer.from(encodedKey, "base64").toString("utf8");
} else if (ephemeral) {
  privateKey = generateKeyPairSync("ed25519").privateKey;
  keyId = "development-ephemeral";
} else {
  throw new Error("RELEASE_MANIFEST_PRIVATE_KEY_BASE64 and RELEASE_MANIFEST_KEY_ID are required");
}

const manifest = await readJson(input);
const schema = await readJson(new URL("../../packages/release-core/schema/releases.schema.json", import.meta.url));
await validateManifest(manifest, schema);
const envelope = signManifestEnvelope({ manifest, keyId, privateKey });
await writeFile(output, `${JSON.stringify(envelope, null, 2)}\n`);
console.log(`Signed ${manifest.releases.length} release(s) with ${keyId}.`);

#!/usr/bin/env node
import { createHash, generateKeyPairSync } from "node:crypto";
import { writeFile } from "node:fs/promises";
import {
  readJson,
  signManifestEnvelope,
  validateManifest
} from "../../packages/release-core/src/release-manifest.mjs";

const preview = process.argv.includes("--preview");
const output = new URL("../../apps/release-api/src/generated/releases.json", import.meta.url);
const manifest = await readJson(new URL("../../packages/release-core/data/releases.json", import.meta.url));
const schema = await readJson(new URL("../../packages/release-core/schema/releases.schema.json", import.meta.url));
const releases = manifest.releases
  .filter((release) => preview || release.status === "published")
  .map((release) => preview && release.status === "draft" ? {
    ...release,
    status: "published",
    publishedAt: "2099-01-01T00:00:00Z",
    artifacts: release.artifacts.map((artifact) => previewAsset(release, artifact)),
    ...(release.media ? { media: release.media.map((item) => previewAsset(release, item)) } : {})
  } : release);

const runtimeManifest = { schemaVersion: manifest.schemaVersion, releases };
await validateManifest(runtimeManifest, schema);
await writeFile(output, `${JSON.stringify(runtimeManifest, null, 2)}\n`);
const encodedKey = process.env.RELEASE_MANIFEST_PRIVATE_KEY_BASE64;
let privateKey;
let keyId = process.env.RELEASE_MANIFEST_KEY_ID;
if (encodedKey && keyId) {
  privateKey = Buffer.from(encodedKey, "base64").toString("utf8");
} else if (preview) {
  privateKey = generateKeyPairSync("ed25519").privateKey;
  keyId = "preview-ephemeral";
} else {
  throw new Error("RELEASE_MANIFEST_PRIVATE_KEY_BASE64 and RELEASE_MANIFEST_KEY_ID are required");
}
const envelope = signManifestEnvelope({ manifest: runtimeManifest, keyId, privateKey });
const envelopeOutput = new URL("../../apps/release-api/src/generated/manifest-envelope.json", import.meta.url);
await writeFile(envelopeOutput, `${JSON.stringify(envelope, null, 2)}\n`);
console.log(`Prepared and signed ${releases.length} ${preview ? "preview" : "production"} release(s) with ${keyId}.`);

function previewAsset(release, asset) {
  return {
    ...asset,
    url: `https://github.com/marius4lui/habiter/releases/download/v${release.version}/${asset.fileName}`,
    sha256: asset.sha256 ?? createHash("sha256").update(`preview:${asset.fileName}`).digest("hex"),
    size: asset.size ?? 1
  };
}

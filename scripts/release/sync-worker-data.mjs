#!/usr/bin/env node
import { writeFile } from "node:fs/promises";
import { readJson } from "../../packages/release-core/src/release-manifest.mjs";

const preview = process.argv.includes("--preview");
const output = new URL("../../apps/release-api/src/generated/releases.json", import.meta.url);
const manifest = await readJson(new URL("../../packages/release-core/data/releases.json", import.meta.url));
const releases = manifest.releases
  .filter((release) => preview || release.status === "published")
  .map((release) => preview && release.status === "draft" ? {
    ...release,
    status: "published",
    publishedAt: "2099-01-01T00:00:00Z",
    artifacts: release.artifacts.map((artifact) => ({
      ...artifact,
      url: `https://github.com/marius4lui/habiter/releases/download/v${release.version}/${artifact.fileName}`
    }))
  } : release);

await writeFile(output, `${JSON.stringify({ schemaVersion: manifest.schemaVersion, releases }, null, 2)}\n`);
console.log(`Prepared ${releases.length} ${preview ? "preview" : "production"} release(s).`);

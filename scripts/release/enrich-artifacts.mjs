#!/usr/bin/env node
import { writeFile } from "node:fs/promises";
import { enrichRelease, readJson } from "../../packages/release-core/src/release-manifest.mjs";

const [version, artifactDirectory, output] = process.argv.slice(2);
if (!version || !artifactDirectory || !output) {
  throw new Error("Usage: enrich-artifacts.mjs <version> <artifact-directory> <output>");
}
const manifest = await readJson(new URL("../../packages/release-core/data/releases.json", import.meta.url));
const release = manifest.releases.find((item) => item.version === version);
if (!release) throw new Error(`Unknown release version: ${version}`);
const enriched = await enrichRelease({
  release,
  artifactDirectory,
  repository: process.env.GITHUB_REPOSITORY ?? "marius4lui/habiter",
  publishedAt: process.env.PUBLISHED_AT || new Date().toISOString()
});
const previouslyPublished = manifest.releases.filter((item) => item.status === "published" && item.version !== version);
await writeFile(output, `${JSON.stringify({ schemaVersion: 1, releases: [enriched, ...previouslyPublished] }, null, 2)}\n`);

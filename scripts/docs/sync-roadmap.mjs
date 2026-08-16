#!/usr/bin/env node
import { readFile, writeFile } from "node:fs/promises";

const root = new URL("../../", import.meta.url);
const roadmapUrl = new URL("ROADMAP.md", root);
const readmeUrl = new URL("README.md", root);
const startMarker = "<!-- roadmap:start -->";
const endMarker = "<!-- roadmap:end -->";
const checkOnly = process.argv.includes("--check");

const [roadmapSource, readmeSource] = await Promise.all([
  readFile(roadmapUrl, "utf8"),
  readFile(readmeUrl, "utf8"),
]);

const start = readmeSource.indexOf(startMarker);
const end = readmeSource.indexOf(endMarker);

if (start === -1 || end === -1 || end < start) {
  throw new Error("README.md must contain one ordered roadmap marker pair.");
}
if (readmeSource.indexOf(startMarker, start + startMarker.length) !== -1 ||
    readmeSource.indexOf(endMarker, end + endMarker.length) !== -1) {
  throw new Error("README.md must contain exactly one roadmap marker pair.");
}

const roadmap = roadmapSource.trim();
const generated = `${startMarker}\n${roadmap}\n${endMarker}`;
const current = readmeSource.slice(start, end + endMarker.length);

if (current === generated) {
  console.log("README roadmap is up to date.");
} else if (checkOnly) {
  console.error("README roadmap is stale. Run `pnpm roadmap:sync` and commit the result.");
  process.exitCode = 1;
} else {
  const updated = `${readmeSource.slice(0, start)}${generated}${readmeSource.slice(end + endMarker.length)}`;
  await writeFile(readmeUrl, updated);
  console.log("Synced ROADMAP.md into README.md.");
}


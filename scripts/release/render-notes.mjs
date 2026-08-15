#!/usr/bin/env node
import { readJson, renderNotes } from "../../packages/release-core/src/release-manifest.mjs";

const version = process.env.VERSION ?? process.argv[2] ?? "1.0.0";
const manifest = await readJson(new URL("../../packages/release-core/data/releases.json", import.meta.url));
const release = manifest.releases.find((item) => item.version === version);
if (!release) throw new Error(`Unknown release version: ${version}`);
process.stdout.write(renderNotes(release));

#!/usr/bin/env node
import assert from "node:assert/strict";
import { access, readFile } from "node:fs/promises";

const root = new URL("../../", import.meta.url);
const website = new URL("apps/website/", root);
const html = await readFile(new URL("index.html", website), "utf8");

await access(new URL("logo.png", website));
await access(new URL("favicon.ico", website));
assert.match(html, /data:image\/png;base64,/);
assert.match(html, /data:image\/x-icon;base64,/);
assert.match(html, /https:\/\/get\.habiter\.dev\/download/);
assert.match(html, /<link rel="canonical" href="https:\/\/habiter\.dev\/"/);
assert.doesNotMatch(html, /_next\/|supabase|next\.js/i);

console.log("Static website contract is valid.");

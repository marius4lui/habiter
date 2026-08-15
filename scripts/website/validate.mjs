#!/usr/bin/env node
import assert from "node:assert/strict";
import { access, readFile } from "node:fs/promises";

const root = new URL("../../", import.meta.url);
const website = new URL("apps/website/", root);
const page = await readFile(new URL("src/components/landing-page.tsx", website), "utf8");
const layout = await readFile(new URL("src/app/layout.tsx", website), "utf8");
const packageJson = JSON.parse(await readFile(new URL("package.json", website), "utf8"));

await access(new URL("public/logo.png", website));
await access(new URL("public/favicon.ico", website));
await access(new URL("src/app/page.tsx", website));
await access(new URL("src/app/globals.css", website));
assert.equal(packageJson.dependencies.next, "15.4.6");
assert.match(page, /https:\/\/get\.habiter\.dev\/download/);
assert.match(page, /<ThemeToggle \/>/);
assert.match(page, /<BrandLogo/);
assert.match(layout, /alternates: \{ canonical: "\/" \}/);
assert.match(layout, /lang="de"/);

console.log("Next.js website contract is valid.");

#!/usr/bin/env node
import assert from "node:assert/strict";
import { access, readFile } from "node:fs/promises";

const root = new URL("../../", import.meta.url);
const website = new URL("apps/website/", root);
const page = await readFile(new URL("src/components/landing-page.tsx", website), "utf8");
const interactions = await readFile(
  new URL("src/components/site-interactions.tsx", website),
  "utf8",
);
const styles = await readFile(new URL("src/app/globals.css", website), "utf8");
const layout = await readFile(new URL("src/app/layout.tsx", website), "utf8");
const nextConfig = await readFile(new URL("next.config.ts", website), "utf8");
const wrangler = JSON.parse(
  await readFile(new URL("wrangler.jsonc", website), "utf8"),
);
const packageJson = JSON.parse(await readFile(new URL("package.json", website), "utf8"));

await access(new URL("public/logo.png", website));
await access(new URL("public/favicon.ico", website));
await access(new URL("src/app/page.tsx", website));
await access(new URL("src/app/globals.css", website));
assert.equal(packageJson.dependencies.next, "15.4.6");
assert.match(page, /https:\/\/get\.habiter\.dev\/download/);
assert.match(page, /Habiter 1\.1 · Stable/);
assert.doesNotMatch(page, />\s*Beta testen\s*</);
assert.doesNotMatch(page, />\s*Beta-Tester werden\s*</);
assert.match(page, /<ThemeToggle \/>/);
assert.match(page, /<BrandLogo/);
assert.match(interactions, /setupCenteredScrollFocus/);
assert.match(interactions, /--scroll-presence/);
assert.match(interactions, /viewportHeight \* 0\.48/);
assert.doesNotMatch(interactions, /IntersectionObserver/);
assert.match(styles, /var\(--scroll-presence/);
assert.match(styles, /var\(--scroll-shift/);
assert.match(layout, /alternates: \{ canonical: "\/" \}/);
assert.match(layout, /lang="de"/);
assert.match(nextConfig, /output: "export"/);
assert.match(nextConfig, /unoptimized: true/);
assert.equal(packageJson.devDependencies.wrangler, "4.123.0");
assert.equal(wrangler.name, "habiter");
assert.equal(wrangler.assets.directory, "./out");

console.log("Static Cloudflare website contract is valid.");

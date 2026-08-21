#!/usr/bin/env node
import assert from "node:assert/strict";
import { access, readFile } from "node:fs/promises";

const root = new URL("../../", import.meta.url);
const website = new URL("apps/website/", root);

const read = (path) => readFile(new URL(path, website), "utf8");
const [
  landing,
  product,
  focus,
  privacy,
  demo,
  shell,
  styles,
  layout,
  productRoute,
  focusRoute,
  privacyRoute,
  sitemap,
  robots,
  manifest,
  nextConfig,
] = await Promise.all([
  read("src/components/landing-page.tsx"),
  read("src/components/product-page.tsx"),
  read("src/components/focus-page.tsx"),
  read("src/components/privacy-page.tsx"),
  read("src/components/habit-product-demo.tsx"),
  read("src/components/site-shell.tsx"),
  read("src/app/globals.css"),
  read("src/app/layout.tsx"),
  read("src/app/product/page.tsx"),
  read("src/app/focus/page.tsx"),
  read("src/app/privacy/page.tsx"),
  read("src/app/sitemap.ts"),
  read("src/app/robots.ts"),
  read("src/app/manifest.ts"),
  read("next.config.ts"),
]);

const wrangler = JSON.parse(await read("wrangler.jsonc"));
const packageJson = JSON.parse(await read("package.json"));

await Promise.all([
  access(new URL("public/logo.png", website)),
  access(new URL("public/favicon.ico", website)),
  access(new URL("src/app/page.tsx", website)),
  access(new URL("src/app/not-found.tsx", website)),
  access(new URL("src/app/product/page.tsx", website)),
  access(new URL("src/app/focus/page.tsx", website)),
  access(new URL("src/app/privacy/page.tsx", website)),
]);

assert.equal(packageJson.dependencies.next, "15.4.6");
assert.equal(packageJson.devDependencies.wrangler, "4.123.0");

for (const source of [landing, product, focus, privacy]) {
  assert.match(source, /https:\/\/get-the\.habiter\.dev\//);
  assert.doesNotMatch(source, /Habiter 1\.\d+ · Stable/);
  assert.doesNotMatch(source, />\s*Beta testen\s*</);
  assert.doesNotMatch(source, />\s*Beta-Tester werden\s*</);
}

assert.match(shell, /href="\/product\/"/);
assert.match(shell, /href="\/focus\/"/);
assert.match(shell, /href="\/privacy\/"/);
assert.match(shell, /<ThemeToggle \/>/);
assert.match(shell, /<BrandLogo \/>/);
assert.match(shell, /<details className=/);
assert.match(shell, /aria-label="Hauptnavigation"/);

assert.match(landing, /<HabitProductDemo \/>/);
assert.match(landing, /Kein Konto für die Kernfunktionen/);
assert.match(landing, /Open Source/);
assert.doesNotMatch(landing, /\d+[kKmM]\+ (Nutzer|Users|Ratings)/);

assert.match(demo, /^"use client";/);
assert.match(demo, /"today" \| "rhythm" \| "insight" \| "focus"/);
assert.match(demo, /role="tablist"/);
assert.match(demo, /role="tabpanel"/);
assert.match(demo, /aria-selected=/);
assert.match(demo, /aria-live="polite"/);
assert.match(demo, /setComplete/);

assert.match(product, /drei|3/iu);
assert.match(product, /pausieren, fortsetzen, archivieren und wiederherstellen/);
assert.match(focus, /Android · App Lock/);
assert.match(focus, /Nutzungszugriff/);
assert.match(focus, /schaltet Habiter App Lock sicher aus/);
assert.match(privacy, /Core Tracking braucht kein Habiter-Konto/);
assert.match(privacy, /keinen Habiter-Cloud-Sync/);
assert.match(privacy, /Versioniertes JSON-Backup/);
assert.match(privacy, /Release-Metadaten/);

assert.match(productRoute, /canonical: "\/product\/"/);
assert.match(focusRoute, /canonical: "\/focus\/"/);
assert.match(privacyRoute, /canonical: "\/privacy\/"/);
assert.match(sitemap, /"product\/", "focus\/", "privacy\/"/);
assert.match(sitemap, /dynamic = "force-static"/);
assert.match(robots, /sitemap: "https:\/\/habiter\.dev\/sitemap\.xml"/);
assert.match(robots, /dynamic = "force-static"/);
assert.match(manifest, /display: "standalone"/);
assert.match(manifest, /dynamic = "force-static"/);

assert.match(styles, /@media \(prefers-reduced-motion: reduce\)/);
assert.match(styles, /:focus-visible/);
assert.match(styles, /\.skip-link/);
assert.match(layout, /alternates: \{ canonical: "\/" \}/);
assert.match(layout, /lang="de"/);
assert.match(layout, /data-scroll-behavior="smooth"/);
assert.match(layout, /href="#content"/);
assert.match(nextConfig, /output: "export"/);
assert.match(nextConfig, /unoptimized: true/);
assert.equal(wrangler.name, "habiter");
assert.equal(wrangler.assets.directory, "./out");

console.log("Static multi-page Habiter website contract is valid.");

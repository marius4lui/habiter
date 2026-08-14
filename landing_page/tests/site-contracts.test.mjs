import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";

test("server home uses centralized dictionaries", () => {
  const page = readFileSync("app/[locale]/page.tsx", "utf8");
  const dictionaries = readFileSync("lib/dictionaries.ts", "utf8");
  assert.match(page, /getDictionary/);
  assert.match(dictionaries, /locales = \["de", "en"\]/);
  assert.doesNotMatch(page, /use client|useParams|useEffect/);
});

test("demo is local and honest", () => {
  const page = readFileSync("app/[locale]/live/page.tsx", "utf8");
  const island = readFileSync("app/[locale]/live/DemoIsland.tsx", "utf8");
  assert.match(page, /stores nothing/);
  assert.match(island, /useState/);
  assert.doesNotMatch(island, /fetch\(|supabase|login/i);
});

test("removed surfaces and dependencies have no source references", () => {
  const manifest = readFileSync("package.json", "utf8");
  const sitemap = readFileSync("app/sitemap.ts", "utf8");
  assert.doesNotMatch(manifest, /supabase/i);
  assert.doesNotMatch(sitemap, /test|feedback|admin/i);
});

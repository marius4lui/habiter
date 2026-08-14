import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";

describe("honest local demo", () => {
  it("declares local state and no account or backend dependency", () => {
    const page = readFileSync("app/[locale]/live/page.tsx", "utf8");
    const island = readFileSync("app/[locale]/live/DemoIsland.tsx", "utf8");
    expect(page).toContain("stores nothing");
    expect(island).toContain("useState");
    expect(island).not.toMatch(/fetch\(|supabase|login/i);
  });
});

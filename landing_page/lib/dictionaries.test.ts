import { describe, expect, it } from "vitest";
import { getDictionary, isLocale, locales } from "./dictionaries";

describe("typed dictionaries", () => {
  it("supports only public locales with matching contracts", () => {
    expect(locales).toEqual(["de", "en"]);
    expect(isLocale("de")).toBe(true);
    expect(isLocale("fr")).toBe(false);
    expect(getDictionary("de").features).toHaveLength(getDictionary("en").features.length);
  });
});

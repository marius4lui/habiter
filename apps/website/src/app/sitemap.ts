import type { MetadataRoute } from "next";

export const dynamic = "force-static";

const pages = ["", "product/", "focus/", "privacy/"] as const;

export default function sitemap(): MetadataRoute.Sitemap {
  return pages.map((page, index) => ({
    url: `https://habiter.dev/${page}`,
    changeFrequency: index === 0 ? "weekly" : "monthly",
    priority: index === 0 ? 1 : 0.8,
  }));
}

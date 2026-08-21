import type { MetadataRoute } from "next";

export const dynamic = "force-static";

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "Habiter — Gewohnheiten, die bleiben",
    short_name: "Habiter",
    description: "Ein local-first Habit Tracker für echte Wiederholung und Fokus.",
    start_url: "/",
    display: "standalone",
    background_color: "#faf9f5",
    theme_color: "#356859",
    icons: [
      { src: "/logo.png", sizes: "192x192", type: "image/png" },
      { src: "/icon.png", sizes: "32x32", type: "image/png" },
      { src: "/apple-icon.png", sizes: "180x180", type: "image/png" },
    ],
  };
}

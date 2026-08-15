import type { Metadata, Viewport } from "next";
import type { ReactNode } from "react";

import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL("https://habiter.dev"),
  title: "Habiter — Gewohnheiten, die bleiben.",
  description:
    "Habiter – Gewohnheiten, die bleiben. Ein Habit Tracker für Fokus, Routinen und langfristige Veränderung.",
  alternates: { canonical: "/" },
  icons: { icon: "/favicon.ico" },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  viewportFit: "cover",
  themeColor: [
    { media: "(prefers-color-scheme: dark)", color: "#090a09" },
    { media: "(prefers-color-scheme: light)", color: "#f4f6f1" },
  ],
};

export default function RootLayout({ children }: Readonly<{ children: ReactNode }>) {
  return (
    <html lang="de" suppressHydrationWarning>
      <body>{children}</body>
    </html>
  );
}

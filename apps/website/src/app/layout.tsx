import type { Metadata, Viewport } from "next";
import type { ReactNode } from "react";

import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL("https://habiter.dev"),
  title: {
    default: "Habiter — Gewohnheiten, die bleiben.",
    template: "%s · Habiter",
  },
  description:
    "Habiter macht gute Gewohnheiten leichter: mit einem ruhigen Tagesfokus, ehrlichen Insights und Schutz vor Ablenkung.",
  alternates: { canonical: "/" },
  keywords: ["Habit Tracker", "Gewohnheiten", "Routinen", "Fokus", "App Lock", "Habiter"],
  openGraph: {
    type: "website",
    locale: "de_DE",
    siteName: "Habiter",
    title: "Habiter — Gewohnheiten, die bleiben.",
    description:
      "Ein ruhiger Habit Tracker für echte Wiederholung, Fokus und eine freundliche Rückkehr.",
  },
  twitter: {
    card: "summary",
    title: "Habiter — Gewohnheiten, die bleiben.",
    description:
      "Ein ruhiger Habit Tracker für echte Wiederholung, Fokus und eine freundliche Rückkehr.",
  },
  icons: {
    icon: [
      { url: "/favicon.ico", sizes: "any" },
      { url: "/icon.png", type: "image/png", sizes: "32x32" },
    ],
    apple: "/apple-icon.png",
  },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  viewportFit: "cover",
  themeColor: [
    { media: "(prefers-color-scheme: dark)", color: "#151a18" },
    { media: "(prefers-color-scheme: light)", color: "#faf9f5" },
  ],
};

export default function RootLayout({ children }: Readonly<{ children: ReactNode }>) {
  return (
    <html lang="de" suppressHydrationWarning>
      <head>
        <script
          dangerouslySetInnerHTML={{
            __html: `(function(){try{var t=localStorage.getItem('habiter-theme');if(t!=='light'&&t!=='dark'){t=matchMedia('(prefers-color-scheme: light)').matches?'light':'dark'}document.documentElement.dataset.theme=t;document.documentElement.style.colorScheme=t}catch(e){}})()`,
          }}
        />
      </head>
      <body>
        <a className="skip-link" href="#content">
          Zum Inhalt springen
        </a>
        {children}
      </body>
    </html>
  );
}

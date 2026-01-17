import { LocaleProvider } from "@/lib/i18n";
import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";

const inter = Inter({
  subsets: ["latin"],
  weight: ["400", "500", "600", "800"],
});

export const metadata: Metadata = {
  metadataBase: new URL('https://habiter.qhrd.online'),
  title: {
    template: '%s | Habiter',
    default: 'Habiter - Build better habits',
  },
  description: "Track your habits and build a better routine with the Habiter App. Beautiful design meets haptic feedback.",
  keywords: [
    "Habiter",
    "Habiter App",
    "habit tracker",
    "habits",
    "routine",
    "productivity",
    "android app",
    "organic design",
    "streaks",
  ],
  authors: [{ name: "Habiter Team" }],
  creator: "Habiter Team",
  publisher: "Habiter",
  formatDetection: {
    email: false,
    address: false,
    telephone: false,
  },
  icons: {
    icon: "/icon.png",
    apple: "/icon.png",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html suppressHydrationWarning>
      <body className={inter.className}>
        <LocaleProvider>
          {children}
        </LocaleProvider>
      </body>
    </html>
  );
}

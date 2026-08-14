import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL('https://habiter.qhrd.online'),
  title: {
    template: '%s | Habiter',
    default: 'Habiter - Build better habits',
  },
  description: "A local-first habit tracker for calm routines, forgiving recovery, reminders, and user-controlled data.",
  keywords: [
    "Habiter",
    "Habiter App",
    "habit tracker",
    "habits",
    "routine",
    "productivity",
    "android app",
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
      <body>{children}</body>
    </html>
  );
}

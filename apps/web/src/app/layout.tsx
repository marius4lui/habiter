import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';

const inter = Inter({
  subsets: ['latin'],
  display: 'swap',
  variable: '--font-inter',
});

export const metadata: Metadata = {
  metadataBase: new URL('https://habiter.app'),
  title: {
    default: 'Habiter - Build Better Habits with AI',
    template: '%s | Habiter',
  },
  description: 'Track your daily habits with beautiful analytics and AI-powered insights. Free habit tracker for iOS, Android, and Web.',
  keywords: [
    'habit tracker',
    'habit tracking app',
    'daily habits',
    'habit builder',
    'productivity app',
    'streak tracker',
    'AI insights',
    'habit analytics',
  ],
  authors: [{ name: 'Habiter Team' }],
  creator: 'Habiter',
  publisher: 'Habiter',
  formatDetection: {
    email: false,
    address: false,
    telephone: false,
  },
  openGraph: {
    type: 'website',
    locale: 'en_US',
    url: 'https://habiter.app',
    title: 'Habiter - Build Better Habits with AI',
    description: 'Track your daily habits with beautiful analytics and AI-powered insights.',
    siteName: 'Habiter',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Habiter - Build Better Habits with AI',
    description: 'Track your daily habits with beautiful analytics and AI-powered insights.',
  },
  robots: {
    index: true,
    follow: true,
  },
  icons: {
    icon: '/favicon.ico',
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className={inter.variable} suppressHydrationWarning>
      <head>
        <meta charSet="utf-8" />
      </head>
      <body className="font-sans antialiased bg-background text-text">
        {children}
      </body>
    </html>
  );
}

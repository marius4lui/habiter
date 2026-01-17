import type { Metadata } from "next";

type Props = {
    params: Promise<{ locale: string }>;
};

export async function generateMetadata({ params }: Props): Promise<Metadata> {
    const { locale } = await params;
    const isDe = locale === "de";

    const title = isDe ? "Habiter App - Gewohnheiten, die bleiben" : "Habiter App - Build habits that stick";
    const description = isDe
        ? "Die Habiter App ist dein Habit Tracker fuer taegliche Routinen, Streaks und Fokus. Modern, organisch und mit haptischem Feedback."
        : "The Habiter App is a habit tracker for daily routines, streaks, and focus. Modern, organic, and built with haptic feedback.";
    const baseUrl = "https://habiter.qhrd.online";

    return {
        title,
        description,
        keywords: [
            "Habiter",
            "Habiter App",
            "habit tracker",
            "habits",
            "streaks",
            "routine",
            "productivity",
            "android app",
        ],
        robots: {
            index: true,
            follow: true,
        },
        alternates: {
            canonical: `${baseUrl}/${locale}`,
            languages: {
                en: `${baseUrl}/en`,
                de: `${baseUrl}/de`,
            },
        },
        openGraph: {
            title,
            description,
            url: `${baseUrl}/${locale}`,
            siteName: "Habiter",
            locale: isDe ? "de_DE" : "en_US",
            type: "website",
            images: [
                {
                    url: "/icon.png",
                    width: 512,
                    height: 512,
                    alt: "Habiter App Logo",
                },
            ],
        },
        twitter: {
            card: "summary_large_image",
            title,
            description,
            images: ["/icon.png"],
        },
        other: {
            "al:android:url": "android-app://com.habiter.app",
            "al:android:package": "com.habiter.app",
            "al:android:app_name": "Habiter App",
        },
    };
}

export function generateStaticParams() {
    return [{ locale: "de" }, { locale: "en" }];
}

export default async function LocaleLayout({
    children,
    params,
}: {
    children: React.ReactNode;
    params: Promise<{ locale: string }>;
}) {
    const { locale } = await params;
    const isDe = locale === "de";
    const baseUrl = "https://habiter.qhrd.online";
    const description = isDe
        ? "Die Habiter App ist dein Habit Tracker fuer taegliche Routinen, Streaks und Fokus. Modern, organisch und mit haptischem Feedback."
        : "The Habiter App is a habit tracker for daily routines, streaks, and focus. Modern, organic, and built with haptic feedback.";

    const jsonLd = {
        "@context": "https://schema.org",
        "@type": "SoftwareApplication",
        name: "Habiter App",
        description,
        applicationCategory: "ProductivityApplication",
        operatingSystem: "Android",
        url: `${baseUrl}/${locale}`,
        brand: {
            "@type": "Brand",
            name: "Habiter",
        },
        offers: {
            "@type": "Offer",
            price: "0",
            priceCurrency: "EUR",
            availability: "https://schema.org/InStock",
        },
        inLanguage: isDe ? "de" : "en",
    };

    return (
        <>
            {children}
            <script
                type="application/ld+json"
                dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
            />
        </>
    );
}

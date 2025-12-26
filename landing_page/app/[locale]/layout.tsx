import type { Metadata } from "next";

type Props = {
    params: Promise<{ locale: string }>;
};

export async function generateMetadata({ params }: Props): Promise<Metadata> {
    const { locale } = await params;

    if (locale === "en") {
        return {
            title: "Habiter - Better Habits",
            description: "Experience a modern, organic way to track your daily routines.",
        };
    }

    return {
        title: "Habiter - Bessere Gewohnheiten",
        description: "Erlebe eine moderne, organische Art, deine täglichen Routinen zu verfolgen.",
    };
}

export function generateStaticParams() {
    return [{ locale: "de" }, { locale: "en" }];
}

export default function LocaleLayout({
    children,
    params,
}: {
    children: React.ReactNode;
    params: Promise<{ locale: string }>;
}) {
    // We need to handle this synchronously for the layout
    // The locale will be validated in the page component
    return children;
}

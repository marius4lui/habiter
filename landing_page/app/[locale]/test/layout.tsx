import { Metadata } from "next";

type Props = {
    params: Promise<{ locale: string }>;
};

export async function generateMetadata({ params }: Props): Promise<Metadata> {
    const { locale } = await params;
    const isDe = locale === "de";

    const title = isDe ? "Beta-Tester werden - Habiter" : "Become a Beta Tester - Habiter";
    const description = isDe
        ? "Melde dich für den Habiter Beta-Test an und gestalte die Zukunft des Habit Trackings mit."
        : "Sign up for the Habiter beta test and help shape the future of habit tracking.";

    return {
        title,
        description,
        openGraph: {
            title,
            description,
        },
    };
}

export default function TestLayout({ children }: { children: React.ReactNode }) {
    return children;
}

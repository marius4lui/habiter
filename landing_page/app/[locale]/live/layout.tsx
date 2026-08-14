import { Metadata } from "next";

type Props = {
    params: Promise<{ locale: string }>;
};

export async function generateMetadata({ params }: Props): Promise<Metadata> {
    const { locale } = await params;
    const isDe = locale === "de";

    const title = isDe ? "Live Demo - Habiter ausprobieren" : "Live Demo - Try Habiter";
    const description = isDe
        ? "Teste einen kleinen lokalen Habit-Flow direkt im Browser. Die Demo speichert nichts und bildet native Funktionen nicht nach."
        : "Try a small local habit flow in your browser. The demo stores nothing and does not reproduce native features.";

    return {
        title,
        description,
        openGraph: {
            title,
            description,
        },
    };
}

export default function LiveLayout({ children }: { children: React.ReactNode }) {
    return children;
}

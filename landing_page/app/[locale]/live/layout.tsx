import { Metadata } from "next";

type Props = {
    params: Promise<{ locale: string }>;
};

export async function generateMetadata({ params }: Props): Promise<Metadata> {
    const { locale } = await params;
    const isDe = locale === "de";

    const title = isDe ? "Live Demo - Habiter ausprobieren" : "Live Demo - Try Habiter";
    const description = isDe
        ? "Teste den Habiter Habit Tracker direkt in deinem Browser. Erlebe das haptische Feedback und das organische Design."
        : "Try the Habiter habit tracker right in your browser. Experience the haptic feedback and organic design.";

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

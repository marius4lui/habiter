import type { Metadata } from "next";

export const metadata: Metadata = {
    title: "Habiter - Bessere Gewohnheiten",
    description: "Erlebe eine moderne, organische Art, deine täglichen Routinen zu verfolgen.",
};

export default function DeLayout({
    children,
}: {
    children: React.ReactNode;
}) {
    return (
        <html lang="de">
            <body>{children}</body>
        </html>
    );
}

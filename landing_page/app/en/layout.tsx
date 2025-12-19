import type { Metadata } from "next";

export const metadata: Metadata = {
    title: "Habiter - Build Better Habits",
    description: "Experience a modern, organic way to track your daily routines.",
};

export default function EnLayout({
    children,
}: {
    children: React.ReactNode;
}) {
    return (
        <html lang="en">
            <body>{children}</body>
        </html>
    );
}

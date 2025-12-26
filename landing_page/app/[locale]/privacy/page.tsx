"use client";

import { Footer, Header } from "@/components";
import { Locale } from "@/lib/i18n";
import { useParams } from "next/navigation";

export default function PrivacyPage() {
    const params = useParams();
    const locale = (params.locale as Locale) || "de";

    const content = {
        de: {
            title: "Datenschutzerklärung",
            lastUpdate: "Letzte Aktualisierung: 16. Dezember 2025",
            sections: [
                {
                    title: "1. Einführung",
                    content: "Willkommen bei Habiter. Wir respektieren Ihre Privatsphäre und verpflichten uns, Ihre persönlichen Daten zu schützen."
                },
                {
                    title: "2. Daten, die wir sammeln",
                    content: "Habiter ist \"Privacy-First\" konzipiert. Standardmäßig werden alle Ihre Gewohnheitsdaten lokal auf Ihrem Gerät gespeichert.",
                    list: [
                        "Lokale Daten: Gewohnheiten, Verlauf und Einstellungen werden auf Ihrem Gerät gespeichert.",
                        "Nutzungsdaten: Wir können anonymisierte Nutzungsdaten sammeln, um die App-Stabilität zu verbessern (z. B. Absturzberichte)."
                    ]
                },
                {
                    title: "3. KI-Funktionen",
                    content: "Wenn Sie KI-Insights aktivieren, werden Ihre Gewohnheitsdaten (Namen, Beschreibungen, Verlauf) möglicherweise von unserem KI-Anbieter verarbeitet, um Erkenntnisse zu generieren. Diese Daten werden nicht zum Training der KI-Modelle verwendet."
                },
                {
                    title: "4. Datensicherheit",
                    content: "Wir haben angemessene Sicherheitsvorkehrungen getroffen, um zu verhindern, dass Ihre persönlichen Daten versehentlich verloren gehen oder unbefugt abgerufen werden."
                },
                {
                    title: "5. Ihre Rechte",
                    content: "Unter bestimmten Umständen haben Sie datenschutzrechtliche Rechte in Bezug auf Ihre persönlichen Daten, einschließlich des Rechts auf Auskunft, Berichtigung, Löschung und Widerspruch."
                },
                {
                    title: "6. Kontakt",
                    content: "Bei Fragen zu dieser Datenschutzerklärung kontaktieren Sie uns bitte unter:",
                    contact: "Sebastian Lui | mariusstudio@pm.me | Ziegeleistr. 1/2, 70825 Korntal-Münchingen, Deutschland"
                }
            ]
        },
        en: {
            title: "Privacy Policy",
            lastUpdate: "Last updated: December 16, 2025",
            sections: [
                {
                    title: "1. Introduction",
                    content: "Welcome to Habiter. We respect your privacy and are committed to protecting your personal data."
                },
                {
                    title: "2. Data We Collect",
                    content: "Habiter is designed with \"Privacy-First\" in mind. By default, all your habit data is stored locally on your device.",
                    list: [
                        "Local Data: Habits, history, and settings are stored on your device.",
                        "Usage Data: We may collect anonymized usage data to improve app stability (e.g., crash reports)."
                    ]
                },
                {
                    title: "3. AI Features",
                    content: "If you enable AI Insights, your habit data (names, descriptions, history) may be processed by our AI provider to generate insights. This data is not used to train AI models."
                },
                {
                    title: "4. Data Security",
                    content: "We have implemented appropriate security measures to prevent your personal data from being accidentally lost or accessed by unauthorized parties."
                },
                {
                    title: "5. Your Rights",
                    content: "Under certain circumstances, you have data protection rights regarding your personal data, including the right to access, correct, delete, and object."
                },
                {
                    title: "6. Contact",
                    content: "If you have questions about this privacy policy, please contact us at:",
                    contact: "Sebastian Lui | mariusstudio@pm.me | Ziegeleistr. 1/2, 70825 Korntal-Münchingen, Germany"
                }
            ]
        }
    };

    const c = content[locale] || content.de;

    return (
        <div className="container">
            <Header locale={locale} showFeatures={false} showDownload={true} />

            <section className="legal-content">
                <h1>{c.title}</h1>
                <p>{c.lastUpdate}</p>

                {c.sections.map((section, i) => (
                    <div key={i}>
                        <h2>{section.title}</h2>
                        <p>{section.content}</p>
                        {section.list && (
                            <ul>
                                {section.list.map((item, j) => (
                                    <li key={j}>{item}</li>
                                ))}
                            </ul>
                        )}
                        {section.contact && <p><strong>{section.contact}</strong></p>}
                    </div>
                ))}
            </section>

            <Footer locale={locale} />
        </div>
    );
}

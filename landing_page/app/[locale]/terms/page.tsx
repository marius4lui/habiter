"use client";

import { Footer, Header } from "@/components";
import { Locale } from "@/lib/i18n";
import { useParams } from "next/navigation";

export default function TermsPage() {
    const params = useParams();
    const locale = (params.locale as Locale) || "de";

    const content = {
        de: {
            title: "Allgemeine Geschäftsbedingungen (AGB)",
            lastUpdate: "Letzte Aktualisierung: 16. Dezember 2025",
            sections: [
                {
                    title: "1. Geltungsbereich",
                    content: "Durch den Zugriff auf oder die Nutzung von Habiter erklären Sie sich mit diesen Bedingungen einverstanden."
                },
                {
                    title: "2. Lizenz",
                    content: "Wir gewähren Ihnen eine persönliche, nicht-exklusive, nicht übertragbare, widerrufliche Lizenz zur Nutzung von Habiter für Ihren persönlichen, nicht-kommerziellen Gebrauch."
                },
                {
                    title: "3. Haftungsausschluss für KI-Funktionen",
                    content: "Von der KI generierte Gewohnheits-Insights dienen nur zu Informationszwecken. Wir übernehmen keine Garantie für die Richtigkeit oder Nützlichkeit dieser Erkenntnisse."
                },
                {
                    title: "4. Haftungsbeschränkung",
                    content: "Habiter haftet nicht für indirekte, zufällige oder Folgeschäden, die aus Ihrer Nutzung der App resultieren."
                },
                {
                    title: "5. Kontakt",
                    content: "Fragen zu diesen Bedingungen richten Sie bitte an:",
                    contact: "Sebastian Lui | mariusstudio@pm.me"
                }
            ]
        },
        en: {
            title: "Terms of Service",
            lastUpdate: "Last updated: December 16, 2025",
            sections: [
                {
                    title: "1. Scope",
                    content: "By accessing or using Habiter, you agree to be bound by these terms."
                },
                {
                    title: "2. License",
                    content: "We grant you a personal, non-exclusive, non-transferable, revocable license to use Habiter for your personal, non-commercial use."
                },
                {
                    title: "3. AI Features Disclaimer",
                    content: "AI-generated habit insights are for informational purposes only. We do not guarantee the accuracy or usefulness of these insights."
                },
                {
                    title: "4. Limitation of Liability",
                    content: "Habiter is not liable for indirect, incidental, or consequential damages resulting from your use of the app."
                },
                {
                    title: "5. Contact",
                    content: "Questions about these terms should be directed to:",
                    contact: "Sebastian Lui | mariusstudio@pm.me"
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
                        {section.contact && <p><strong>{section.contact}</strong></p>}
                    </div>
                ))}
            </section>

            <Footer locale={locale} />
        </div>
    );
}

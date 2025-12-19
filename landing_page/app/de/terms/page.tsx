import { Footer, Header } from "@/components";
import type { Metadata } from "next";

export const metadata: Metadata = {
    title: "Allgemeine Geschäftsbedingungen - Habiter",
};

export default function DeTermsPage() {
    return (
        <div className="container">
            <Header locale="de" showFeatures={false} showDownload={true} />

            <section className="legal-content">
                <h1>Allgemeine Geschäftsbedingungen (AGB)</h1>
                <p>Letzte Aktualisierung: 16. Dezember 2025</p>

                <h2>1. Geltungsbereich</h2>
                <p>
                    Durch den Zugriff auf oder die Nutzung von Habiter erklären Sie sich
                    mit diesen Bedingungen einverstanden.
                </p>

                <h2>2. Lizenz</h2>
                <p>
                    Wir gewähren Ihnen eine persönliche, nicht-exklusive, nicht übertragbare,
                    widerrufliche Lizenz zur Nutzung von Habiter für Ihren persönlichen,
                    nicht-kommerziellen Gebrauch.
                </p>

                <h2>3. Haftungsausschluss für KI-Funktionen</h2>
                <p>
                    Von der KI generierte Gewohnheits-Insights dienen nur zu Informationszwecken.
                    Wir übernehmen keine Garantie für die Richtigkeit oder Nützlichkeit dieser
                    Erkenntnisse.
                </p>

                <h2>4. Haftungsbeschränkung</h2>
                <p>
                    Habiter haftet nicht für indirekte, zufällige oder Folgeschäden, die aus
                    Ihrer Nutzung der App resultieren.
                </p>

                <h2>5. Kontakt</h2>
                <p>Fragen zu diesen Bedingungen richten Sie bitte an:</p>
                <p>
                    Sebastian Lui<br />
                    mariusstudio@pm.me
                </p>
            </section>

            <Footer locale="de" />
        </div>
    );
}

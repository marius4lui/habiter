import { Footer, Header } from "@/components";
import type { Metadata } from "next";

export const metadata: Metadata = {
    title: "Datenschutzerklärung - Habiter",
};

export default function DePrivacyPage() {
    return (
        <div className="container">
            <Header locale="de" showFeatures={false} showDownload={true} />

            <section className="legal-content">
                <h1>Datenschutzerklärung</h1>
                <p>Letzte Aktualisierung: 16. Dezember 2025</p>

                <h2>1. Einführung</h2>
                <p>
                    Willkommen bei Habiter. Wir respektieren Ihre Privatsphäre und verpflichten uns,
                    Ihre persönlichen Daten zu schützen.
                </p>

                <h2>2. Daten, die wir sammeln</h2>
                <p>
                    Habiter ist &quot;Privacy-First&quot; konzipiert. Standardmäßig werden alle Ihre
                    Gewohnheitsdaten lokal auf Ihrem Gerät gespeichert.
                </p>
                <ul>
                    <li>
                        <strong>Lokale Daten:</strong> Gewohnheiten, Verlauf und Einstellungen werden
                        auf Ihrem Gerät gespeichert.
                    </li>
                    <li>
                        <strong>Nutzungsdaten:</strong> Wir können anonymisierte Nutzungsdaten sammeln,
                        um die App-Stabilität zu verbessern (z. B. Absturzberichte).
                    </li>
                </ul>

                <h2>3. KI-Funktionen</h2>
                <p>
                    Wenn Sie KI-Insights aktivieren, werden Ihre Gewohnheitsdaten (Namen, Beschreibungen,
                    Verlauf) möglicherweise von unserem KI-Anbieter verarbeitet, um Erkenntnisse zu
                    generieren. Diese Daten werden nicht zum Training der KI-Modelle verwendet und
                    dienen ausschließlich dazu, Ihnen personalisiertes Feedback zu geben.
                </p>

                <h2>4. Datensicherheit</h2>
                <p>
                    Wir haben angemessene Sicherheitsvorkehrungen getroffen, um zu verhindern, dass
                    Ihre persönlichen Daten versehentlich verloren gehen oder unbefugt abgerufen werden.
                </p>

                <h2>5. Ihre Rechte</h2>
                <p>
                    Unter bestimmten Umständen haben Sie datenschutzrechtliche Rechte in Bezug auf
                    Ihre persönlichen Daten, einschließlich des Rechts auf Auskunft, Berichtigung,
                    Löschung und Widerspruch.
                </p>

                <h2>6. Kontakt</h2>
                <p>Bei Fragen zu dieser Datenschutzerklärung kontaktieren Sie uns bitte unter:</p>
                <p>
                    Sebastian Lui<br />
                    mariusstudio@pm.me<br />
                    Ziegeleistr. 1/2, 70825 Korntal-Münchingen, Deutschland
                </p>
            </section>

            <Footer locale="de" />
        </div>
    );
}

import { Footer, Header } from "@/components";
import type { Metadata } from "next";

export const metadata: Metadata = {
    title: "Impressum - Habiter",
};

export default function DeImprintPage() {
    return (
        <div className="container">
            <Header locale="de" showFeatures={false} showDownload={true} />

            <section className="legal-content">
                <h1>Impressum</h1>
                <p>Angaben gemäß § 5 TMG</p>

                <h2>Kontakt</h2>
                <p>
                    Sebastian Lui<br />
                    Ziegeleistr. 1/2<br />
                    70825 Korntal-Münchingen<br />
                    Deutschland
                </p>

                <h2>E-Mail</h2>
                <p>Email: mariusstudio@pm.me</p>

                <h2>Vertretung</h2>
                <p>Sebastian Lui</p>

                <h2>Umsatzsteuer-ID</h2>
                <p>Kleinunternehmerregelung (keine USt-ID erforderlich)</p>

                <h2>Streitschlichtung</h2>
                <p>
                    Die Europäische Kommission stellt eine Plattform zur Online-Streitbeilegung (OS)
                    bereit: https://ec.europa.eu/consumers/odr. Wir sind nicht bereit oder verpflichtet,
                    an Streitbeilegungsverfahren vor einer Verbraucherschlichtungsstelle teilzunehmen.
                </p>
            </section>

            <Footer locale="de" />
        </div>
    );
}

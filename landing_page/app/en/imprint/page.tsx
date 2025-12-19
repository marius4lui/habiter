import { Footer, Header } from "@/components";
import type { Metadata } from "next";

export const metadata: Metadata = {
    title: "Imprint - Habiter",
};

export default function EnImprintPage() {
    return (
        <div className="container">
            <Header locale="en" showFeatures={false} showDownload={true} />

            <section className="legal-content">
                <h1>Imprint (Impressum)</h1>
                <p>Information according to § 5 TMG</p>

                <h2>Contact Information</h2>
                <p>
                    Sebastian Lui<br />
                    Ziegeleistr. 1/2<br />
                    70825 Korntal-Münchingen<br />
                    Deutschland
                </p>

                <h2>Contact</h2>
                <p>Email: mariusstudio@pm.me</p>

                <h2>Represented by</h2>
                <p>Sebastian Lui</p>

                <h2>VAT ID</h2>
                <p>
                    Sales tax identification number according to § 27a of the Sales Tax Law:<br />
                    Not applicable (Small business / Kleinunternehmer)
                </p>

                <h2>Dispute Resolution</h2>
                <p>
                    The European Commission provides a platform for online dispute resolution (OS):
                    https://ec.europa.eu/consumers/odr. Please find our email in the impressum/legal
                    notice. We do not take part in online dispute resolutions at consumer arbitration boards.
                </p>
            </section>

            <Footer locale="en" />
        </div>
    );
}

"use client";

import { Footer, Header } from "@/components";
import { Locale } from "@/lib/i18n";
import { useParams } from "next/navigation";

export default function ImprintPage() {
    const params = useParams();
    const locale = (params.locale as Locale) || "de";

    const content = {
        de: {
            title: "Impressum",
            subtitle: "Angaben gemäß § 5 TMG",
            contact: "Kontakt",
            email: "E-Mail",
            representative: "Vertretung",
            vatId: "Umsatzsteuer-ID",
            vatInfo: "Kleinunternehmerregelung (keine USt-ID erforderlich)",
            dispute: "Streitschlichtung",
            disputeText: "Die Europäische Kommission stellt eine Plattform zur Online-Streitbeilegung (OS) bereit: https://ec.europa.eu/consumers/odr. Wir sind nicht bereit oder verpflichtet, an Streitbeilegungsverfahren vor einer Verbraucherschlichtungsstelle teilzunehmen."
        },
        en: {
            title: "Imprint",
            subtitle: "Information according to § 5 TMG (German law)",
            contact: "Contact",
            email: "Email",
            representative: "Representative",
            vatId: "VAT ID",
            vatInfo: "Small business regulation (no VAT ID required)",
            dispute: "Dispute Resolution",
            disputeText: "The European Commission provides a platform for online dispute resolution (ODR): https://ec.europa.eu/consumers/odr. We are not willing or obliged to participate in dispute resolution proceedings before a consumer arbitration board."
        }
    };

    const c = content[locale] || content.de;

    return (
        <div className="container">
            <Header locale={locale} showFeatures={false} showDownload={true} />

            <section className="legal-content">
                <h1>{c.title}</h1>
                <p>{c.subtitle}</p>

                <h2>{c.contact}</h2>
                <p>
                    Sebastian Lui<br />
                    Ziegeleistr. 1/2<br />
                    70825 Korntal-Münchingen<br />
                    {locale === "de" ? "Deutschland" : "Germany"}
                </p>

                <h2>{c.email}</h2>
                <p>mariusstudio@pm.me</p>

                <h2>{c.representative}</h2>
                <p>Sebastian Lui</p>

                <h2>{c.vatId}</h2>
                <p>{c.vatInfo}</p>

                <h2>{c.dispute}</h2>
                <p>{c.disputeText}</p>
            </section>

            <Footer locale={locale} />
        </div>
    );
}

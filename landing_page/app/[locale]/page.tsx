"use client";

import { Footer, Header } from "@/components";
import { Locale, translations } from "@/lib/i18n";
import { useParams } from "next/navigation";

export default function LocaleHomePage() {
    const params = useParams();
    const locale = (params.locale as Locale) || "de";
    const t = translations[locale] || translations.de;

    return (
        <div className="container">
            <Header locale={locale} />

            <section className="hero">
                <h1>{t.home.title}</h1>
                <p className="subtitle">{t.home.subtitle}</p>
                <a href="#download" className="btn btn-primary">
                    {t.home.downloadBtn}
                </a>
            </section>

            <section id="features" className="features">
                <div className="card">
                    <span className="feature-icon">✨</span>
                    <h3>{t.features.organic.title}</h3>
                    <p>{t.features.organic.desc}</p>
                </div>
                <div className="card">
                    <span className="feature-icon">📳</span>
                    <h3>{t.features.haptic.title}</h3>
                    <p>{t.features.haptic.desc}</p>
                </div>
                <div className="card">
                    <span className="feature-icon">🤖</span>
                    <h3>{t.features.ai.title}</h3>
                    <p>{t.features.ai.desc}</p>
                </div>
            </section>

            <section id="download" className="hero" style={{ paddingTop: 0 }}>
                <h2>{t.home.startJourney}</h2>
                <p style={{ marginBottom: "1.5rem", color: "var(--text-muted)" }}>
                    🚀 {locale === "de"
                        ? "Die App befindet sich aktuell in der Beta-Phase. Werde Teil unserer Tester-Community!"
                        : "The app is currently in beta. Join our tester community!"}
                </p>
                <a href={`/${locale}/test`} className="btn btn-primary">
                    {locale === "de" ? "Beta-Tester werden →" : "Become a Beta Tester →"}
                </a>
            </section>

            <Footer locale={locale} />
        </div>
    );
}

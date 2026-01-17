"use client";

import { Footer, Header } from "@/components";
import { Locale, translations } from "@/lib/i18n";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useEffect, useState } from "react";

export default function LocaleHomePage() {
    const params = useParams();
    const locale = (params.locale as Locale) || "de";
    const t = translations[locale] || translations.de;
    const [demoProgress, setDemoProgress] = useState(0);

    // Animate demo progress
    useEffect(() => {
        const timer = setInterval(() => {
            setDemoProgress(prev => (prev + 1) % 101);
        }, 50);
        return () => clearInterval(timer);
    }, []);

    const content = {
        de: {
            howItWorks: "So funktioniert's",
            steps: [
                { icon: "📝", title: "Habits erstellen", desc: "Definiere deine täglichen Gewohnheiten mit Zielen und Kategorien" },
                { icon: "✅", title: "Tippen & Abhaken", desc: "Markiere Habits mit einem Tap als erledigt" },
                { icon: "📊", title: "Fortschritt verfolgen", desc: "Behalte deine Streaks und Statistiken im Blick" },
            ],
            tryDemo: "Probier es aus!",
            tryDemoDesc: "Teste die App direkt im Browser",
            openDemo: "Live Demo öffnen →",
            stats: {
                title: "Zahlen, die überzeugen",
                items: [
                    { value: "30+", label: "Sekunden zum Start" },
                    { value: "100%", label: "Offline nutzbar" },
                    { value: "0€", label: "Keine Kosten" },
                ],
            },
            moreFeatures: "Noch mehr Features",
            features2: [
                { icon: "🔒", title: "App Lock", desc: "Sperre ablenkendeApps bis du deine Habits erledigt hast" },
                { icon: "📈", title: "Statistiken", desc: "Detaillierte Einblicke in deine Gewohnheiten" },
                { icon: "🌙", title: "Dark Mode", desc: "Schont deine Augen bei Nacht" },
                { icon: "🔔", title: "Erinnerungen", desc: "Nie wieder einen Habit vergessen" },
            ],
            seo: {
                title: "Habiter App: Funktionen, Preis und Support",
                intro: "Die Habiter App ist ein moderner Habit Tracker, der dich bei Gewohnheiten, Routinen und Streaks unterstuetzt.",
                items: [
                    {
                        title: "Funktionen fuer nachhaltige Gewohnheiten",
                        desc: "Erstelle Habits, tracke Fortschritt, setze Erinnerungen und behalte deine Statistiken im Blick.",
                    },
                    {
                        title: "Preis & Verfuegbarkeit",
                        desc: "Die Habiter App ist in der Beta kostenlos und fuer Android verfuegbar.",
                    },
                    {
                        title: "Support & Datenschutz",
                        desc: "Schneller Support ueber Feedback, transparente Datenschutz- und AGB-Seiten.",
                    },
                    {
                        title: "Fuer wen ist die Habiter App?",
                        desc: "Fuer alle, die Gewohnheiten aufbauen, ihren Alltag strukturieren und Fokus gewinnen wollen.",
                    },
                ],
            },
        },
        en: {
            howItWorks: "How it works",
            steps: [
                { icon: "📝", title: "Create Habits", desc: "Define your daily habits with goals and categories" },
                { icon: "✅", title: "Tap & Check", desc: "Mark habits as completed with a tap" },
                { icon: "📊", title: "Track Progress", desc: "Keep an eye on your streaks and statistics" },
            ],
            tryDemo: "Try it out!",
            tryDemoDesc: "Test the app right in your browser",
            openDemo: "Open Live Demo →",
            stats: {
                title: "Numbers that convince",
                items: [
                    { value: "30+", label: "Seconds to start" },
                    { value: "100%", label: "Works offline" },
                    { value: "$0", label: "No cost" },
                ],
            },
            moreFeatures: "Even more features",
            features2: [
                { icon: "🔒", title: "App Lock", desc: "Lock distracting apps until you complete your habits" },
                { icon: "📈", title: "Statistics", desc: "Detailed insights into your habits" },
                { icon: "🌙", title: "Dark Mode", desc: "Easy on your eyes at night" },
                { icon: "🔔", title: "Reminders", desc: "Never forget a habit again" },
            ],
            seo: {
                title: "Habiter App: Features, Pricing, and Support",
                intro: "The Habiter App is a modern habit tracker that helps you build routines and maintain streaks.",
                items: [
                    {
                        title: "Features for lasting habits",
                        desc: "Create habits, track progress, set reminders, and monitor your statistics.",
                    },
                    {
                        title: "Pricing & availability",
                        desc: "The Habiter App is free during beta and available for Android.",
                    },
                    {
                        title: "Support & privacy",
                        desc: "Fast support via feedback, plus clear privacy and terms pages.",
                    },
                    {
                        title: "Who is the Habiter App for?",
                        desc: "For anyone who wants to build habits, structure their day, and stay focused.",
                    },
                ],
            },
        },
    };

    const c = content[locale] || content.de;

    return (
        <div className="container">
            <Header locale={locale} />

            {/* Hero Section */}
            <section className="hero">
                <h1>{t.home.title}</h1>
                <p className="subtitle">{t.home.subtitle}</p>
                <div className="hero-buttons">
                    <a href="#download" className="btn btn-primary">
                        {t.home.downloadBtn}
                    </a>
                    <Link href={`/${locale}/live`} className="btn btn-secondary">
                        {c.openDemo}
                    </Link>
                </div>
            </section>

            {/* Features */}
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

            {/* How It Works */}
            <section className="how-it-works">
                <h2>{c.howItWorks}</h2>
                <div className="steps">
                    {c.steps.map((step, i) => (
                        <div key={i} className="step">
                            <div className="step-number">{i + 1}</div>
                            <span className="step-icon">{step.icon}</span>
                            <h3>{step.title}</h3>
                            <p>{step.desc}</p>
                        </div>
                    ))}
                </div>
            </section>

            {/* Demo Preview */}
            <section className="demo-preview">
                <div className="demo-content">
                    <h2>{c.tryDemo}</h2>
                    <p>{c.tryDemoDesc}</p>
                    <Link href={`/${locale}/live`} className="btn btn-primary">
                        {c.openDemo}
                    </Link>
                </div>
                <div className="demo-phone">
                    <div className="demo-screen">
                        <div className="demo-header-bar">
                            <div className="demo-greeting">
                                {locale === "de" ? "Guten Tag" : "Good afternoon"}
                            </div>
                            <div className="demo-date">
                                {new Date().toLocaleDateString(locale === "de" ? "de-DE" : "en-US", { weekday: "short", day: "numeric", month: "short" })}
                            </div>
                        </div>
                        <div className="demo-progress-section">
                            <div className="demo-progress-bar">
                                <div
                                    className="demo-progress-fill"
                                    style={{ width: `${Math.min(demoProgress, 75)}%` }}
                                ></div>
                            </div>
                            <div className="demo-progress-text">{Math.min(demoProgress, 75)}%</div>
                        </div>
                        <div className="demo-habits">
                            <div className="demo-habit completed">
                                <span>🧘</span>
                                <span>Meditieren</span>
                                <span className="check">✓</span>
                            </div>
                            <div className="demo-habit completed">
                                <span>💧</span>
                                <span>Wasser trinken</span>
                                <span className="check">✓</span>
                            </div>
                            <div className="demo-habit">
                                <span>📚</span>
                                <span>Lesen</span>
                                <span className="arrow">→</span>
                            </div>
                        </div>
                    </div>
                </div>
            </section>

            {/* Stats */}
            <section className="stats-section">
                <h2>{c.stats.title}</h2>
                <div className="stats-grid">
                    {c.stats.items.map((stat, i) => (
                        <div key={i} className="stat-card">
                            <div className="stat-value">{stat.value}</div>
                            <div className="stat-label">{stat.label}</div>
                        </div>
                    ))}
                </div>
            </section>

            {/* More Features */}
            <section className="more-features">
                <h2>{c.moreFeatures}</h2>
                <div className="features-grid">
                    {c.features2.map((feature, i) => (
                        <div key={i} className="feature-item">
                            <span className="feature-icon">{feature.icon}</span>
                            <div>
                                <h4>{feature.title}</h4>
                                <p>{feature.desc}</p>
                            </div>
                        </div>
                    ))}
                </div>
            </section>

            {/* SEO Content */}
            <section id="habiter-app" className="seo-section">
                <h2>{c.seo.title}</h2>
                <p className="seo-intro">{c.seo.intro}</p>
                <div className="seo-grid">
                    {c.seo.items.map((item, i) => (
                        <div key={i} className="card seo-card">
                            <h3>{item.title}</h3>
                            <p>{item.desc}</p>
                        </div>
                    ))}
                </div>
                <p className="seo-support">
                    {locale === "de" ? (
                        <>
                            Fragen? Nutze das{" "}
                            <Link href={`/${locale}/feedback`}>Feedback-Formular</Link>{" "}
                            oder die Seiten fuer Datenschutz und AGB.
                        </>
                    ) : (
                        <>
                            Questions? Use the{" "}
                            <Link href={`/${locale}/feedback`}>feedback form</Link>{" "}
                            or visit the privacy and terms pages.
                        </>
                    )}
                </p>
            </section>

            {/* Download CTA */}
            <section id="download" className="hero cta-section">
                <h2>{t.home.startJourney}</h2>
                <p style={{ marginBottom: "1.5rem", color: "var(--text-muted)" }}>
                    🚀 {locale === "de"
                        ? "Die App befindet sich aktuell in der Beta-Phase. Werde Teil unserer Tester-Community!"
                        : "The app is currently in beta. Join our tester community!"}
                </p>
                <a href={`/${locale}/test`} className="btn btn-primary btn-large">
                    {locale === "de" ? "Beta-Tester werden →" : "Become a Beta Tester →"}
                </a>
            </section>

            <Footer locale={locale} />
        </div>
    );
}


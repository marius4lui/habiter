"use client";

import { getPriorityLabel, useLocale } from "@/lib/i18n";
import { BetaTest, supabase } from "@/lib/supabase";
import Image from "next/image";
import Link from "next/link";
import { useEffect, useState } from "react";
import styles from "./test.module.css";

export default function TestOverviewPage() {
    const { t, locale, setLocale } = useLocale();
    const [tests, setTests] = useState<BetaTest[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        loadTests();
    }, []);

    async function loadTests() {
        const { data, error } = await supabase
            .from("beta_tests")
            .select("*")
            .eq("is_active", true)
            .order("priority", { ascending: true }) // Stable (0) first
            .order("created_at", { ascending: false });

        setLoading(false);
        if (data) {
            setTests(data);
        }
        if (error) console.error("Error loading tests:", error);
    }

    const otherLocale = locale === "de" ? "en" : "de";

    const Header = () => (
        <header className={styles.header}>
            <Link href="/" className={styles.brand}>
                <Image src="/icon.png" alt="Habiter Logo" width={32} height={32} className={styles.brandLogo} />
                {t.common.habiter}
            </Link>
            <nav className={styles.navLinks}>
                <Link href="/en" className={styles.navLink}>{t.common.home}</Link>
                <button
                    onClick={() => setLocale(otherLocale)}
                    className={`${styles.navLink} ${styles.langSwitch}`}
                >
                    {t.nav.langSwitch}
                </button>
            </nav>
        </header>
    );

    const Footer = () => (
        <footer className={styles.footer}>
            <div className={styles.footerLinks}>
                <Link href="/en/privacy">{t.nav.privacy}</Link>
                <Link href="/en/terms">{t.nav.terms}</Link>
                <Link href="/en/imprint">{t.nav.imprint}</Link>
            </div>
            <p>{t.common.copyright}</p>
        </footer>
    );

    if (loading) {
        return (
            <div className={styles.container}>
                <Header />
                <div className={styles.loadingContainer}>
                    <p>{t.common.loading}</p>
                </div>
                <Footer />
            </div>
        );
    }

    return (
        <div className={styles.container}>
            <Header />

            <div className={styles.overviewPage}>
                <h1>{t.test.title}</h1>
                <p className={styles.intro}>{t.test.intro}</p>

                {tests.length === 0 ? (
                    <div className={styles.noTests}>
                        <p>{t.test.noTests}</p>
                    </div>
                ) : (
                    <div className={styles.testGrid}>
                        {tests.map((test) => (
                            <Link
                                key={test.id}
                                href={`/en/test/${test.id}`}
                                className={styles.testCard}
                            >
                                <div className={styles.testCardHeader}>
                                    <span className={`${styles.priorityBadge} ${styles[`priority${test.priority}`]}`}>
                                        {getPriorityLabel(test.priority, t)}
                                    </span>
                                    {test.priority === 0 && (
                                        <span className={styles.recommendedBadge}>⭐ Empfohlen</span>
                                    )}
                                </div>
                                <h2>{test.name}</h2>
                                {test.description && (
                                    <p className={styles.testCardDesc}>{test.description}</p>
                                )}
                                <div className={styles.testCardFooter}>
                                    <span className={styles.testCardMethod}>
                                        {test.tester_method === "google_groups" ? "🔗 Google Groups" : "📋 Email-Liste"}
                                    </span>
                                    <span className={styles.testCardArrow}>→</span>
                                </div>
                            </Link>
                        ))}
                    </div>
                )}

                {/* Demo Preview Column */}
                <div className={styles.demoSection}>
                    <div className={styles.demoCard}>
                        <h3>{t.test.demo.title}</h3>
                        <div className={styles.phoneFrame}>
                            <div className={styles.phoneScreen}>
                                <div className={styles.demoHeader}>
                                    <span className={styles.demoLogo}>🌱</span>
                                    <span>Habiter</span>
                                </div>
                                <div className={styles.demoContent}>
                                    {t.test.demo.habits.map((habit, i) => (
                                        <div key={i} className={styles.demoHabit}>
                                            <span>{i % 2 === 0 ? "✅" : "⬜"}</span> {habit}
                                        </div>
                                    ))}
                                </div>
                                <div className={styles.demoStats}>
                                    <div className={styles.demoStat}>
                                        <strong>7</strong>
                                        <span>{t.test.demo.streak}</span>
                                    </div>
                                    <div className={styles.demoStat}>
                                        <strong>85%</strong>
                                        <span>{t.test.demo.completed}</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <p className={styles.demoCaption}>{t.test.demo.caption}</p>
                    </div>
                </div>
            </div>

            <Footer />
        </div>
    );
}

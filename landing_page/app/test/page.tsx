"use client";

import { getPriorityLabel, useLocale } from "@/lib/i18n";
import { BetaTest, supabase } from "@/lib/supabase";
import Image from "next/image";
import Link from "next/link";
import { useEffect, useState } from "react";
import styles from "./test.module.css";

export default function TestPage() {
    const { t, locale, setLocale } = useLocale();
    const [tests, setTests] = useState<BetaTest[]>([]);
    const [selectedTest, setSelectedTest] = useState<string>("");
    const [formData, setFormData] = useState({
        firstName: "",
        lastName: "",
        email: "",
    });
    const [loading, setLoading] = useState(false);
    const [success, setSuccess] = useState(false);
    const [error, setError] = useState("");

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

        if (data) {
            setTests(data);
            if (data.length > 0) {
                setSelectedTest(data[0].id);
            }
        }
        if (error) console.error("Error loading tests:", error);
    }

    async function handleSubmit(e: React.FormEvent) {
        e.preventDefault();
        setLoading(true);
        setError("");

        const { error } = await supabase.from("beta_registrations").insert({
            test_id: selectedTest,
            first_name: formData.firstName,
            last_name: formData.lastName,
            email: formData.email,
            status: "pending",
        });

        setLoading(false);

        if (error) {
            setError(t.test.errorMsg);
            console.error(error);
        } else {
            setSuccess(true);
        }
    }

    const currentTest = tests.find((tt) => tt.id === selectedTest);
    const otherLocale = locale === "de" ? "en" : "de";

    // Header component inline
    const Header = () => (
        <header className={styles.header}>
            <Link href="/" className={styles.brand}>
                <Image src="/icon.png" alt="Habiter Logo" width={32} height={32} className={styles.brandLogo} />
                {t.common.habiter}
            </Link>
            <nav className={styles.navLinks}>
                <Link href="/" className={styles.navLink}>{t.common.home}</Link>
                <button
                    onClick={() => setLocale(otherLocale)}
                    className={`${styles.navLink} ${styles.langSwitch}`}
                >
                    {t.nav.langSwitch}
                </button>
            </nav>
        </header>
    );

    // Footer component inline
    const Footer = () => (
        <footer className={styles.footer}>
            <div className={styles.footerLinks}>
                <Link href="/privacy">{t.nav.privacy}</Link>
                <Link href="/terms">{t.nav.terms}</Link>
                <Link href="/imprint">{t.nav.imprint}</Link>
            </div>
            <p>{t.common.copyright}</p>
        </footer>
    );

    if (success && currentTest) {
        return (
            <div className={styles.container}>
                <Header />
                <div className={styles.successContainer}>
                    <div className={styles.successCard}>
                        <span className={styles.successIcon}>✅</span>
                        <h1>{t.test.success.title}</h1>
                        <p>{t.test.success.thanks}</p>

                        <div className={styles.nextSteps}>
                            <h2>{t.test.success.nextSteps}</h2>
                            <ol>
                                {currentTest.tester_method === "google_groups" && currentTest.google_groups_link && (
                                    <li>
                                        <strong>{t.test.success.joinGroup}</strong>
                                        <a href={currentTest.google_groups_link} target="_blank" rel="noopener noreferrer">
                                            {currentTest.google_groups_link}
                                        </a>
                                    </li>
                                )}
                                <li>
                                    <strong>{t.test.success.downloadApp}</strong>
                                    <a href={currentTest.playstore_link} target="_blank" rel="noopener noreferrer">
                                        {t.test.success.openStore}
                                    </a>
                                </li>
                            </ol>
                        </div>
                    </div>
                </div>
                <Footer />
            </div>
        );
    }

    return (
        <div className={styles.container}>
            <Header />

            <div className={styles.testPage}>
                {/* Left: Registration Form */}
                <div className={styles.formSection}>
                    <h1>{t.test.title}</h1>
                    <p className={styles.intro}>{t.test.intro}</p>

                    <div className={styles.infoBox}>
                        <h3>{t.test.dataInfo.title}</h3>
                        <ul>
                            {t.test.dataInfo.items.map((item, i) => (
                                <li key={i}>{item}</li>
                            ))}
                        </ul>
                    </div>

                    <div className={styles.infoBox}>
                        <h3>{t.test.howTo.title}</h3>
                        <ol>
                            {t.test.howTo.steps.map((step, i) => (
                                <li key={i}>{step}</li>
                            ))}
                        </ol>
                    </div>

                    {tests.length === 0 ? (
                        <div className={styles.noTests}>
                            <p>{t.test.noTests}</p>
                        </div>
                    ) : (
                        <form onSubmit={handleSubmit} className={styles.form}>
                            {/* Test Selection with Priority Badges */}
                            <div className={styles.testSelection}>
                                {tests.map((test) => (
                                    <button
                                        key={test.id}
                                        type="button"
                                        className={`${styles.testOption} ${selectedTest === test.id ? styles.selected : ""}`}
                                        onClick={() => setSelectedTest(test.id)}
                                    >
                                        <span className={`${styles.priorityBadge} ${styles[`priority${test.priority}`]}`}>
                                            {getPriorityLabel(test.priority, t)}
                                        </span>
                                        <span className={styles.testName}>{test.name}</span>
                                        {test.description && (
                                            <span className={styles.testDesc}>{test.description}</span>
                                        )}
                                    </button>
                                ))}
                            </div>

                            <div className={styles.formFields}>
                                <div className={styles.field}>
                                    <label>{t.test.form.firstName}</label>
                                    <input
                                        type="text"
                                        required
                                        placeholder={t.test.form.firstNamePlaceholder}
                                        value={formData.firstName}
                                        onChange={(e) => setFormData({ ...formData, firstName: e.target.value })}
                                    />
                                </div>

                                <div className={styles.field}>
                                    <label>{t.test.form.lastName}</label>
                                    <input
                                        type="text"
                                        required
                                        placeholder={t.test.form.lastNamePlaceholder}
                                        value={formData.lastName}
                                        onChange={(e) => setFormData({ ...formData, lastName: e.target.value })}
                                    />
                                </div>
                            </div>

                            <div className={styles.field}>
                                <label>{t.test.form.email}</label>
                                <input
                                    type="email"
                                    required
                                    placeholder={t.test.form.emailPlaceholder}
                                    value={formData.email}
                                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                                />
                                <small>{t.test.form.emailHint}</small>
                            </div>

                            {error && <p className={styles.error}>{error}</p>}

                            <button type="submit" className={styles.submitBtn} disabled={loading}>
                                {loading ? t.test.form.submitting : t.test.form.submit}
                            </button>
                        </form>
                    )}
                </div>

                {/* Right: Demo Preview */}
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

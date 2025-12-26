"use client";

import { getPriorityLabel, useLocale } from "@/lib/i18n";
import { BetaTest, supabase } from "@/lib/supabase";
import Image from "next/image";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useEffect, useState } from "react";
import styles from "../test.module.css";

export default function TestDetailPage() {
    const { t, locale, setLocale } = useLocale();
    const params = useParams();
    const testId = params.id as string;

    const [test, setTest] = useState<BetaTest | null>(null);
    const [loading, setLoading] = useState(true);
    const [notFound, setNotFound] = useState(false);
    const [formData, setFormData] = useState({
        firstName: "",
        lastName: "",
        email: "",
    });
    const [submitting, setSubmitting] = useState(false);
    const [success, setSuccess] = useState(false);
    const [error, setError] = useState("");

    useEffect(() => {
        loadTest();
    }, [testId]);

    async function loadTest() {
        const { data, error } = await supabase
            .from("beta_tests")
            .select("*")
            .eq("id", testId)
            .eq("is_active", true)
            .single();

        setLoading(false);

        if (error || !data) {
            setNotFound(true);
            return;
        }

        setTest(data);
    }

    async function handleSubmit(e: React.FormEvent) {
        e.preventDefault();
        setSubmitting(true);
        setError("");

        const { error } = await supabase.from("beta_registrations").insert({
            test_id: testId,
            first_name: formData.firstName,
            last_name: formData.lastName,
            email: formData.email,
            status: "pending",
        });

        setSubmitting(false);

        if (error) {
            setError(t.test.errorMsg);
            console.error(error);
        } else {
            setSuccess(true);
        }
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
                <Link href="/en/test" className={styles.navLink}>Tests</Link>
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

    if (notFound) {
        return (
            <div className={styles.container}>
                <Header />
                <div className={styles.notFoundContainer}>
                    <h1>404</h1>
                    <p>Test nicht gefunden oder nicht mehr aktiv.</p>
                    <Link href="/en/test" className={styles.backLink}>
                        ← Alle Tests anzeigen
                    </Link>
                </div>
                <Footer />
            </div>
        );
    }

    if (success && test) {
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
                                {test.tester_method === "google_groups" && test.google_groups_link && (
                                    <li>
                                        <strong>{t.test.success.joinGroup}</strong>
                                        <a href={test.google_groups_link} target="_blank" rel="noopener noreferrer">
                                            {test.google_groups_link}
                                        </a>
                                    </li>
                                )}
                                <li>
                                    <strong>{t.test.success.downloadApp}</strong>
                                    <a href={test.playstore_link} target="_blank" rel="noopener noreferrer">
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

            <div className={styles.testDetailPage}>
                {/* Test Info Card */}
                <div className={styles.testInfoCard}>
                    <div className={styles.testInfoHeader}>
                        <span className={`${styles.priorityBadge} ${styles[`priority${test?.priority}`]}`}>
                            {getPriorityLabel(test?.priority || 1, t)}
                        </span>
                        <h1>{test?.name}</h1>
                    </div>
                    {test?.description && (
                        <p className={styles.testInfoDesc}>{test.description}</p>
                    )}

                    <div className={styles.testInfoMeta}>
                        <div>
                            <strong>Methode:</strong>{" "}
                            {test?.tester_method === "google_groups" ? "Google Groups" : "CSV Export"}
                        </div>
                        <div>
                            <strong>Play Store:</strong>{" "}
                            <a href={test?.playstore_link} target="_blank" rel="noopener noreferrer">
                                Link öffnen
                            </a>
                        </div>
                    </div>
                </div>

                {/* Registration Section */}
                <div className={styles.formSection}>
                    <h2>{t.test.title}</h2>

                    {test?.tester_method === "google_groups" && test?.google_groups_link ? (
                        // Google Groups - Direct Link (no form needed)
                        <div className={styles.googleGroupsJoin}>
                            <div className={styles.infoBox}>
                                <h3>🔗 {t.test.googleGroups.title}</h3>
                                <p>{t.test.googleGroups.description}</p>
                                <ol>
                                    <li>{t.test.googleGroups.step1}</li>
                                    <li>{t.test.googleGroups.step2}</li>
                                    <li>{t.test.googleGroups.step3}</li>
                                </ol>
                            </div>

                            <a
                                href={test.google_groups_link}
                                target="_blank"
                                rel="noopener noreferrer"
                                className={styles.joinGroupBtn}
                            >
                                🔗 {t.test.googleGroups.joinBtn}
                            </a>

                            {test.playstore_link && (
                                <a
                                    href={test.playstore_link}
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    className={styles.playstoreBtn}
                                >
                                    📱 {t.test.googleGroups.downloadBtn}
                                </a>
                            )}
                        </div>
                    ) : (
                        // CSV Method - Show Registration Form
                        <>
                            <div className={styles.infoBox}>
                                <h3>{t.test.dataInfo.title}</h3>
                                <ul>
                                    {t.test.dataInfo.items.map((item, i) => (
                                        <li key={i}>{item}</li>
                                    ))}
                                </ul>
                            </div>

                            <form onSubmit={handleSubmit} className={styles.form}>
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

                                <button type="submit" className={styles.submitBtn} disabled={submitting}>
                                    {submitting ? t.test.form.submitting : t.test.form.submit}
                                </button>
                            </form>
                        </>
                    )}
                </div>
            </div>

            <Footer />
        </div>
    );
}

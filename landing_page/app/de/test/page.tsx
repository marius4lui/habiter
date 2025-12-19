"use client";

import { Footer, Header } from "@/components";
import { BetaTest, supabase } from "@/lib/supabase";
import { useEffect, useState } from "react";
import styles from "./test.module.css";

export default function TestPage() {
    const [tests, setTests] = useState<BetaTest[]>([]);
    const [selectedTest, setSelectedTest] = useState<string>("");
    const [formData, setFormData] = useState({
        name: "",
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
            name: formData.name,
            email: formData.email,
            status: "pending",
        });

        setLoading(false);

        if (error) {
            setError("Registrierung fehlgeschlagen. Bitte versuche es erneut.");
            console.error(error);
        } else {
            setSuccess(true);
        }
    }

    const currentTest = tests.find((t) => t.id === selectedTest);

    if (success && currentTest) {
        return (
            <div className="container">
                <Header locale="de" showFeatures={false} showDownload={false} />
                <div className={styles.successContainer}>
                    <div className={styles.successCard}>
                        <span className={styles.successIcon}>✅</span>
                        <h1>Registrierung erfolgreich!</h1>
                        <p>Vielen Dank für deine Anmeldung zum Beta-Test.</p>

                        <div className={styles.nextSteps}>
                            <h2>Nächste Schritte:</h2>
                            <ol>
                                <li>
                                    <strong>Google Group beitreten:</strong>
                                    <a href={currentTest.google_groups_link} target="_blank" rel="noopener noreferrer">
                                        {currentTest.google_groups_link}
                                    </a>
                                </li>
                                <li>
                                    <strong>App im Play Store herunterladen:</strong>
                                    <a href={currentTest.playstore_link} target="_blank" rel="noopener noreferrer">
                                        Play Store öffnen
                                    </a>
                                </li>
                            </ol>
                        </div>
                    </div>
                </div>
                <Footer locale="de" />
            </div>
        );
    }

    return (
        <div className="container">
            <Header locale="de" showFeatures={false} showDownload={false} />

            <div className={styles.testPage}>
                {/* Left: Registration Form */}
                <div className={styles.formSection}>
                    <h1>Beta-Tester werden</h1>
                    <p className={styles.intro}>
                        Werde Teil unserer exklusiven Beta-Tester-Community und teste neue Features
                        vor allen anderen!
                    </p>

                    <div className={styles.infoBox}>
                        <h3>📋 Was passiert mit deinen Daten?</h3>
                        <ul>
                            <li><strong>Name & E-Mail</strong> werden gespeichert, um dich für den Test freizuschalten</li>
                            <li>Du erhältst einen <strong>Link zum Google Play Store</strong> Test</li>
                            <li>Deine E-Mail muss mit deinem <strong>Google-Account</strong> verknüpft sein</li>
                        </ul>
                    </div>

                    <div className={styles.infoBox}>
                        <h3>📱 So bekommst du die App:</h3>
                        <ol>
                            <li>Registriere dich mit deinem Google-Account E-Mail</li>
                            <li>Tritt der Google Group bei (Link nach Registrierung)</li>
                            <li>Öffne den Play Store Link</li>
                            <li>Lade die Beta-Version herunter</li>
                        </ol>
                    </div>

                    {tests.length === 0 ? (
                        <div className={styles.noTests}>
                            <p>Aktuell sind keine Tests verfügbar.</p>
                        </div>
                    ) : (
                        <form onSubmit={handleSubmit} className={styles.form}>
                            {tests.length > 1 && (
                                <div className={styles.field}>
                                    <label>Test auswählen</label>
                                    <select
                                        value={selectedTest}
                                        onChange={(e) => setSelectedTest(e.target.value)}
                                    >
                                        {tests.map((test) => (
                                            <option key={test.id} value={test.id}>
                                                {test.name}
                                            </option>
                                        ))}
                                    </select>
                                </div>
                            )}

                            <div className={styles.field}>
                                <label>Vollständiger Name</label>
                                <input
                                    type="text"
                                    required
                                    placeholder="Max Mustermann"
                                    value={formData.name}
                                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                                />
                            </div>

                            <div className={styles.field}>
                                <label>E-Mail (Google Account)</label>
                                <input
                                    type="email"
                                    required
                                    placeholder="deine.email@gmail.com"
                                    value={formData.email}
                                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                                />
                                <small>Nutze die E-Mail deines Google Play Store Accounts</small>
                            </div>

                            {error && <p className={styles.error}>{error}</p>}

                            <button type="submit" className="btn btn-primary" disabled={loading}>
                                {loading ? "Wird gesendet..." : "Zum Beta-Test anmelden"}
                            </button>
                        </form>
                    )}
                </div>

                {/* Right: Demo Preview */}
                <div className={styles.demoSection}>
                    <div className={styles.demoCard}>
                        <h3>📱 App Vorschau</h3>
                        <div className={styles.phoneFrame}>
                            <div className={styles.phoneScreen}>
                                <div className={styles.demoHeader}>
                                    <span className={styles.demoLogo}>🌱</span>
                                    <span>Habiter</span>
                                </div>
                                <div className={styles.demoContent}>
                                    <div className={styles.demoHabit}>
                                        <span>✅</span> Meditieren
                                    </div>
                                    <div className={styles.demoHabit}>
                                        <span>⬜</span> Sport treiben
                                    </div>
                                    <div className={styles.demoHabit}>
                                        <span>✅</span> Wasser trinken
                                    </div>
                                    <div className={styles.demoHabit}>
                                        <span>⬜</span> Lesen
                                    </div>
                                </div>
                                <div className={styles.demoStats}>
                                    <div className={styles.demoStat}>
                                        <strong>7</strong>
                                        <span>Tage Streak</span>
                                    </div>
                                    <div className={styles.demoStat}>
                                        <strong>85%</strong>
                                        <span>Abgeschlossen</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <p className={styles.demoCaption}>
                            Glassmorphismus Design • Haptisches Feedback • KI-Insights
                        </p>
                    </div>
                </div>
            </div>

            <Footer locale="de" />
        </div>
    );
}

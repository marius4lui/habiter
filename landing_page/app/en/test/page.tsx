"use client";

import { Footer, Header } from "@/components";
import { BetaTest, supabase } from "@/lib/supabase";
import { useEffect, useState } from "react";
import styles from "./test.module.css";

export default function TestPageEN() {
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
            setError("Registration failed. Please try again.");
            console.error(error);
        } else {
            setSuccess(true);
        }
    }

    const currentTest = tests.find((t) => t.id === selectedTest);

    if (success && currentTest) {
        return (
            <div className="container">
                <Header locale="en" showFeatures={false} showDownload={false} />
                <div className={styles.successContainer}>
                    <div className={styles.successCard}>
                        <span className={styles.successIcon}>✅</span>
                        <h1>Registration Successful!</h1>
                        <p>Thank you for signing up for the beta test.</p>

                        <div className={styles.nextSteps}>
                            <h2>Next Steps:</h2>
                            <ol>
                                <li>
                                    <strong>Join Google Group:</strong>
                                    <a href={currentTest.google_groups_link} target="_blank" rel="noopener noreferrer">
                                        {currentTest.google_groups_link}
                                    </a>
                                </li>
                                <li>
                                    <strong>Download app from Play Store:</strong>
                                    <a href={currentTest.playstore_link} target="_blank" rel="noopener noreferrer">
                                        Open Play Store
                                    </a>
                                </li>
                            </ol>
                        </div>
                    </div>
                </div>
                <Footer locale="en" />
            </div>
        );
    }

    return (
        <div className="container">
            <Header locale="en" showFeatures={false} showDownload={false} />

            <div className={styles.testPage}>
                {/* Left: Registration Form */}
                <div className={styles.formSection}>
                    <h1>Become a Beta Tester</h1>
                    <p className={styles.intro}>
                        Join our exclusive beta testing community and try new features before anyone else!
                    </p>

                    <div className={styles.infoBox}>
                        <h3>📋 What happens with your data?</h3>
                        <ul>
                            <li><strong>Name & Email</strong> are stored to grant you test access</li>
                            <li>You will receive a <strong>Google Play Store test link</strong></li>
                            <li>Your email must be linked to your <strong>Google Account</strong></li>
                        </ul>
                    </div>

                    <div className={styles.infoBox}>
                        <h3>📱 How to get the app:</h3>
                        <ol>
                            <li>Register with your Google Account email</li>
                            <li>Join the Google Group (link after registration)</li>
                            <li>Open the Play Store link</li>
                            <li>Download the beta version</li>
                        </ol>
                    </div>

                    {tests.length === 0 ? (
                        <div className={styles.noTests}>
                            <p>No tests are currently available.</p>
                        </div>
                    ) : (
                        <form onSubmit={handleSubmit} className={styles.form}>
                            {tests.length > 1 && (
                                <div className={styles.field}>
                                    <label>Select Test</label>
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
                                <label>Full Name</label>
                                <input
                                    type="text"
                                    required
                                    placeholder="John Doe"
                                    value={formData.name}
                                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                                />
                            </div>

                            <div className={styles.field}>
                                <label>Email (Google Account)</label>
                                <input
                                    type="email"
                                    required
                                    placeholder="your.email@gmail.com"
                                    value={formData.email}
                                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                                />
                                <small>Use the email of your Google Play Store account</small>
                            </div>

                            {error && <p className={styles.error}>{error}</p>}

                            <button type="submit" className="btn btn-primary" disabled={loading}>
                                {loading ? "Submitting..." : "Sign Up for Beta Test"}
                            </button>
                        </form>
                    )}
                </div>

                {/* Right: Demo Preview */}
                <div className={styles.demoSection}>
                    <div className={styles.demoCard}>
                        <h3>📱 App Preview</h3>
                        <div className={styles.phoneFrame}>
                            <div className={styles.phoneScreen}>
                                <div className={styles.demoHeader}>
                                    <span className={styles.demoLogo}>🌱</span>
                                    <span>Habiter</span>
                                </div>
                                <div className={styles.demoContent}>
                                    <div className={styles.demoHabit}>
                                        <span>✅</span> Meditate
                                    </div>
                                    <div className={styles.demoHabit}>
                                        <span>⬜</span> Exercise
                                    </div>
                                    <div className={styles.demoHabit}>
                                        <span>✅</span> Drink water
                                    </div>
                                    <div className={styles.demoHabit}>
                                        <span>⬜</span> Read
                                    </div>
                                </div>
                                <div className={styles.demoStats}>
                                    <div className={styles.demoStat}>
                                        <strong>7</strong>
                                        <span>Day Streak</span>
                                    </div>
                                    <div className={styles.demoStat}>
                                        <strong>85%</strong>
                                        <span>Completed</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <p className={styles.demoCaption}>
                            Glassmorphism Design • Haptic Feedback • AI Insights
                        </p>
                    </div>
                </div>
            </div>

            <Footer locale="en" />
        </div>
    );
}

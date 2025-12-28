"use client";

import { getPriorityLabel, useLocale } from "@/lib/i18n";
import { BetaRegistration, BetaTest, Feedback, supabase } from "@/lib/supabase";
import { User } from "@supabase/supabase-js";
import { useEffect, useState } from "react";
import styles from "./admin.module.css";

// Pre-defined templates for quick test creation
const TEMPLATES = {
    stable: {
        name: "Habiter Stable",
        description: "Stabile, getestete Version für alle Benutzer.",
        priority: 0,
        tester_method: "csv" as const,
    },
    beta: {
        name: "Habiter Beta",
        description: "Neue Features testen bevor sie live gehen.",
        priority: 1,
        tester_method: "google_groups" as const,
    },
    alpha: {
        name: "Habiter Alpha",
        description: "Frühe Entwicklungsversion - kann Bugs enthalten.",
        priority: 2,
        tester_method: "google_groups" as const,
    },
    nightly: {
        name: "Habiter Nightly",
        description: "Tägliche Builds mit neuesten Änderungen - experimentell!",
        priority: 3,
        tester_method: "csv" as const,
    },
};

export default function AdminPage() {
    const { t, locale, setLocale } = useLocale();
    const [user, setUser] = useState<User | null>(null);
    const [loading, setLoading] = useState(true);
    const [tests, setTests] = useState<BetaTest[]>([]);
    const [registrations, setRegistrations] = useState<Record<string, BetaRegistration[]>>({});
    const [feedback, setFeedback] = useState<Feedback[]>([]);
    const [showForm, setShowForm] = useState(false);
    const [editingTest, setEditingTest] = useState<BetaTest | null>(null);
    const [formData, setFormData] = useState({
        name: "",
        description: "",
        tester_method: "google_groups" as "google_groups" | "csv",
        google_groups_link: "",
        playstore_link: "",
        optin_link: "",
        priority: 1,
        is_active: true,
        requires_optin: false,
    });

    useEffect(() => {
        checkAuth();
    }, []);

    async function checkAuth() {
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) {
            window.location.href = "/admin/login";
            return;
        }

        // Check if user is in admins table
        const { data: adminData, error: adminError } = await supabase
            .from("admins")
            .select("id")
            .eq("email", user.email)
            .single();

        if (adminError || !adminData) {
            // User is not an admin - sign out and redirect
            await supabase.auth.signOut();
            window.location.href = "/admin/login?error=unauthorized";
            return;
        }

        setUser(user);
        setLoading(false);
        loadTests();
        loadFeedback();
    }

    async function handleLogout() {
        await supabase.auth.signOut();
        window.location.href = "/admin/login";
    }

    async function loadTests() {
        const { data: testsData } = await supabase
            .from("beta_tests")
            .select("*")
            .order("priority", { ascending: true })
            .order("created_at", { ascending: false });

        if (testsData) {
            setTests(testsData);

            const regs: Record<string, BetaRegistration[]> = {};
            for (const test of testsData) {
                const { data: regData } = await supabase
                    .from("beta_registrations")
                    .select("*")
                    .eq("test_id", test.id)
                    .order("created_at", { ascending: false });
                if (regData) {
                    regs[test.id] = regData;
                }
            }
            setRegistrations(regs);
        }
    }

    async function loadFeedback() {
        const { data } = await supabase
            .from("feedback")
            .select("*")
            .order("created_at", { ascending: false });
        if (data) {
            setFeedback(data);
        }
    }

    async function deleteFeedback(id: string) {
        if (confirm("Feedback löschen?")) {
            await supabase.from("feedback").delete().eq("id", id);
            loadFeedback();
        }
    }

    async function handleSubmit(e: React.FormEvent) {
        e.preventDefault();

        let result;
        if (editingTest) {
            result = await supabase
                .from("beta_tests")
                .update(formData)
                .eq("id", editingTest.id);
        } else {
            result = await supabase.from("beta_tests").insert(formData);
        }

        if (result.error) {
            console.error("Supabase error:", result.error);
            alert(`Fehler: ${result.error.message}\n\nDetails: ${result.error.details || result.error.hint || "Keine weiteren Details"}`);
            return;
        }

        resetForm();
        loadTests();
    }

    async function handleDelete(id: string) {
        if (confirm(t.admin.deleteConfirm)) {
            await supabase.from("beta_registrations").delete().eq("test_id", id);
            await supabase.from("beta_tests").delete().eq("id", id);
            loadTests();
        }
    }

    function startEdit(test: BetaTest) {
        setEditingTest(test);
        setFormData({
            name: test.name,
            description: test.description,
            tester_method: test.tester_method || "google_groups",
            google_groups_link: test.google_groups_link || "",
            playstore_link: test.playstore_link,
            optin_link: test.optin_link || "",
            priority: test.priority,
            is_active: test.is_active,
            requires_optin: test.requires_optin || false,
        });
        setShowForm(true);
    }

    function resetForm() {
        setFormData({
            name: "",
            description: "",
            tester_method: "google_groups",
            google_groups_link: "",
            playstore_link: "",
            optin_link: "",
            priority: 1,
            is_active: true,
            requires_optin: false,
        });
        setEditingTest(null);
        setShowForm(false);
    }

    function exportCSV(testId: string, testName: string) {
        const regs = registrations[testId] || [];
        const headers = [t.test.form.firstName, t.test.form.lastName, t.test.form.email, t.admin.status, t.admin.date];
        const rows = regs.map((r) => [
            r.first_name,
            r.last_name,
            r.email,
            r.status,
            new Date(r.created_at).toLocaleDateString(locale === "de" ? "de-DE" : "en-US"),
        ]);

        const csv = [headers, ...rows].map((row) => row.join(";")).join("\n");
        const blob = new Blob(["\uFEFF" + csv], { type: "text/csv;charset=utf-8;" });
        const url = URL.createObjectURL(blob);
        const link = document.createElement("a");
        link.href = url;
        link.download = `${testName.replace(/\s+/g, "_")}_registrations.csv`;
        link.click();
    }

    const otherLocale = locale === "de" ? "en" : "de";

    if (loading) {
        return (
            <div className={styles.loadingContainer}>
                <p>{t.common.loading}</p>
            </div>
        );
    }

    return (
        <div className={styles.adminContainer}>
            <header className={styles.header}>
                <div>
                    <h1>🛠️ {t.admin.title}</h1>
                    <p>{t.admin.subtitle}</p>
                </div>
                <div className={styles.headerActions}>
                    <button onClick={() => setLocale(otherLocale)} className={styles.langBtn}>
                        {locale.toUpperCase()} → {otherLocale.toUpperCase()}
                    </button>
                    <button onClick={handleLogout} className={styles.logoutBtn}>
                        {t.admin.logout}
                    </button>
                </div>
            </header>

            <main className={styles.main}>
                <div className={styles.actions}>
                    <button
                        className={styles.createBtn}
                        onClick={() => setShowForm(!showForm)}
                    >
                        {showForm ? t.common.cancel : t.admin.createTest}
                    </button>
                </div>

                {showForm && (
                    <form onSubmit={handleSubmit} className={styles.form}>
                        <h2>{editingTest ? t.admin.editTest : t.admin.createTest}</h2>

                        {/* Template Selector */}
                        {!editingTest && (
                            <div className={styles.templateSection}>
                                <label>📋 Schnellstart-Template:</label>
                                <div className={styles.templateButtons}>
                                    {Object.entries(TEMPLATES).map(([key, tmpl]) => (
                                        <button
                                            key={key}
                                            type="button"
                                            className={styles.templateBtn}
                                            onClick={() => setFormData({
                                                ...formData,
                                                name: tmpl.name,
                                                description: tmpl.description,
                                                priority: tmpl.priority,
                                                tester_method: tmpl.tester_method,
                                            })}
                                        >
                                            <span className={`${styles.priorityBadge} ${styles[`priority${tmpl.priority}`]}`}>
                                                {getPriorityLabel(tmpl.priority, t)}
                                            </span>
                                            {tmpl.name.replace("Habiter ", "")}
                                        </button>
                                    ))}
                                </div>
                            </div>
                        )}

                        <div className={styles.field}>
                            <label>{t.admin.testName}</label>
                            <input
                                type="text"
                                required
                                placeholder={t.admin.testNamePlaceholder}
                                value={formData.name}
                                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                            />
                        </div>

                        <div className={styles.field}>
                            <label>{t.admin.description}</label>
                            <textarea
                                placeholder={t.admin.descPlaceholder}
                                value={formData.description}
                                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                            />
                        </div>

                        <div className={styles.field}>
                            <label>{t.admin.priority}</label>
                            <select
                                value={formData.priority}
                                onChange={(e) => setFormData({ ...formData, priority: parseInt(e.target.value) })}
                            >
                                <option value={0}>{t.test.priority.stable}</option>
                                <option value={1}>{t.test.priority.beta}</option>
                                <option value={2}>{t.test.priority.alpha}</option>
                                <option value={3}>{t.test.priority.nightly}</option>
                            </select>
                        </div>

                        <div className={styles.field}>
                            <label>Tester Methode</label>
                            <div className={styles.radioGroup}>
                                <label className={styles.radioLabel}>
                                    <input
                                        type="radio"
                                        name="tester_method"
                                        value="google_groups"
                                        checked={formData.tester_method === "google_groups"}
                                        onChange={() => setFormData({ ...formData, tester_method: "google_groups" })}
                                    />
                                    Google Groups (automatisch)
                                </label>
                                <label className={styles.radioLabel}>
                                    <input
                                        type="radio"
                                        name="tester_method"
                                        value="csv"
                                        checked={formData.tester_method === "csv"}
                                        onChange={() => setFormData({ ...formData, tester_method: "csv" })}
                                    />
                                    CSV Export (manuell)
                                </label>
                            </div>
                        </div>

                        {formData.tester_method === "google_groups" && (
                            <div className={styles.field}>
                                <label>{t.admin.googleGroups}</label>
                                <input
                                    type="url"
                                    required
                                    placeholder="https://groups.google.com/g/..."
                                    value={formData.google_groups_link}
                                    onChange={(e) => setFormData({ ...formData, google_groups_link: e.target.value })}
                                />
                                <small>{t.admin.googleGroupsHint}</small>
                            </div>
                        )}

                        <div className={styles.field}>
                            <label>{t.admin.playStore}</label>
                            <input
                                type="url"
                                required
                                placeholder="https://play.google.com/apps/testing/..."
                                value={formData.playstore_link}
                                onChange={(e) => setFormData({ ...formData, playstore_link: e.target.value })}
                            />
                            <small>{t.admin.playStoreHint}</small>
                        </div>

                        <div className={styles.checkbox}>
                            <input
                                type="checkbox"
                                id="is_active"
                                checked={formData.is_active}
                                onChange={(e) => setFormData({ ...formData, is_active: e.target.checked })}
                            />
                            <label htmlFor="is_active">{t.admin.isActive}</label>
                        </div>

                        <div className={styles.checkbox}>
                            <input
                                type="checkbox"
                                id="requires_optin"
                                checked={formData.requires_optin}
                                onChange={(e) => setFormData({ ...formData, requires_optin: e.target.checked })}
                            />
                            <label htmlFor="requires_optin">{t.admin.requiresOptin}</label>
                        </div>

                        {formData.requires_optin && (
                            <div className={styles.field}>
                                <label>{t.admin.optinLink}</label>
                                <input
                                    type="url"
                                    required
                                    placeholder="https://play.google.com/apps/testing/..."
                                    value={formData.optin_link}
                                    onChange={(e) => setFormData({ ...formData, optin_link: e.target.value })}
                                />
                                <small>{t.admin.optinLinkHint}</small>
                            </div>
                        )}

                        <div className={styles.formActions}>
                            <button type="submit" className={styles.submitBtn}>
                                {editingTest ? t.common.save : t.common.submit}
                            </button>
                            <button type="button" className={styles.cancelBtn} onClick={resetForm}>
                                {t.common.cancel}
                            </button>
                        </div>
                    </form>
                )}

                <div className={styles.testsList}>
                    {tests.length === 0 ? (
                        <div className={styles.empty}>
                            <p>{t.admin.noTests}</p>
                            <p>{t.admin.createFirst}</p>
                        </div>
                    ) : (
                        tests.map((test) => (
                            <div key={test.id} className={styles.testCard}>
                                <div className={styles.testHeader}>
                                    <h3>
                                        <span className={`${styles.priorityBadge} ${styles[`priority${test.priority}`]}`}>
                                            {getPriorityLabel(test.priority, t)}
                                        </span>
                                        {test.name}
                                        <span className={test.is_active ? styles.active : styles.inactive}>
                                            {test.is_active ? "●" : "○"}
                                        </span>
                                    </h3>
                                    <div className={styles.testActions}>
                                        <button onClick={() => startEdit(test)}>✏️</button>
                                        <button onClick={() => handleDelete(test.id)}>🗑️</button>
                                    </div>
                                </div>

                                {test.description && (
                                    <p className={styles.testDescription}>{test.description}</p>
                                )}

                                <div className={styles.testLinks}>
                                    <div>
                                        <strong>Methode:</strong>{" "}
                                        {test.tester_method === "google_groups" ? "Google Groups" : "CSV"}
                                    </div>
                                    {test.tester_method === "google_groups" && test.google_groups_link && (
                                        <div>
                                            <strong>{t.admin.googleGroups}:</strong>{" "}
                                            <a href={test.google_groups_link} target="_blank" rel="noopener noreferrer">
                                                {test.google_groups_link}
                                            </a>
                                        </div>
                                    )}
                                    <div>
                                        <strong>{t.admin.playStore}:</strong>{" "}
                                        <a href={test.playstore_link} target="_blank" rel="noopener noreferrer">
                                            {test.playstore_link}
                                        </a>
                                    </div>
                                </div>

                                <div className={styles.registrations}>
                                    <div className={styles.regHeader}>
                                        <h4>
                                            {t.admin.registrations} ({(registrations[test.id] || []).length})
                                        </h4>
                                        {(registrations[test.id] || []).length > 0 && (
                                            <button
                                                className={styles.exportBtn}
                                                onClick={() => exportCSV(test.id, test.name)}
                                            >
                                                {t.admin.csvExport}
                                            </button>
                                        )}
                                    </div>

                                    {(registrations[test.id] || []).length === 0 ? (
                                        <p className={styles.noRegs}>{t.admin.noRegistrations}</p>
                                    ) : (
                                        <table className={styles.regTable}>
                                            <thead>
                                                <tr>
                                                    <th>{t.test.form.firstName}</th>
                                                    <th>{t.test.form.lastName}</th>
                                                    <th>{t.test.form.email}</th>
                                                    <th>{t.admin.status}</th>
                                                    <th>{t.admin.date}</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                {(registrations[test.id] || []).map((reg) => (
                                                    <tr key={reg.id}>
                                                        <td>{reg.first_name}</td>
                                                        <td>{reg.last_name}</td>
                                                        <td>{reg.email}</td>
                                                        <td>
                                                            <span className={styles[reg.status]}>
                                                                {reg.status}
                                                            </span>
                                                        </td>
                                                        <td>
                                                            {new Date(reg.created_at).toLocaleDateString(locale === "de" ? "de-DE" : "en-US")}
                                                        </td>
                                                    </tr>
                                                ))}
                                            </tbody>
                                        </table>
                                    )}
                                </div>
                            </div>
                        ))
                    )}
                </div>

                {/* Feedback Section */}
                <div className={styles.feedbackSection}>
                    <h2>💬 Feedback ({feedback.length})</h2>
                    {feedback.length === 0 ? (
                        <p className={styles.noRegs}>Noch kein Feedback erhalten.</p>
                    ) : (
                        <div className={styles.feedbackList}>
                            {feedback.map((item) => (
                                <div key={item.id} className={styles.feedbackCard}>
                                    <div className={styles.feedbackHeader}>
                                        <span className={styles.feedbackType}>
                                            {item.type === "suggestion" && "💡"}
                                            {item.type === "bug" && "🐛"}
                                            {item.type === "praise" && "⭐"}
                                            {item.type === "question" && "❓"}
                                            {item.type === "other" && "📝"}
                                            {" "}{item.type}
                                        </span>
                                        <span className={styles.feedbackDate}>
                                            {new Date(item.created_at).toLocaleDateString(locale === "de" ? "de-DE" : "en-US")}
                                        </span>
                                        <button
                                            className={styles.deleteFeedbackBtn}
                                            onClick={() => deleteFeedback(item.id)}
                                        >
                                            🗑️
                                        </button>
                                    </div>
                                    <p className={styles.feedbackMessage}>{item.message}</p>
                                    {(item.name || item.email) && (
                                        <div className={styles.feedbackMeta}>
                                            {item.name && <span>👤 {item.name}</span>}
                                            {item.email && <span>✉️ {item.email}</span>}
                                            <span>🌐 {item.locale.toUpperCase()}</span>
                                        </div>
                                    )}
                                </div>
                            ))}
                        </div>
                    )}
                </div>
            </main>
        </div>
    );
}

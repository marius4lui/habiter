"use client";

import { BetaRegistration, BetaTest, supabase } from "@/lib/supabase";
import { useEffect, useState } from "react";
import styles from "./admin.module.css";

export default function AdminPage() {
    const [tests, setTests] = useState<BetaTest[]>([]);
    const [registrations, setRegistrations] = useState<Record<string, BetaRegistration[]>>({});
    const [showForm, setShowForm] = useState(false);
    const [editingTest, setEditingTest] = useState<BetaTest | null>(null);
    const [formData, setFormData] = useState({
        name: "",
        description: "",
        google_groups_link: "",
        playstore_link: "",
        is_active: true,
    });

    useEffect(() => {
        loadTests();
    }, []);

    async function loadTests() {
        const { data: testsData } = await supabase
            .from("beta_tests")
            .select("*")
            .order("created_at", { ascending: false });

        if (testsData) {
            setTests(testsData);

            // Load registrations for each test
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

    async function handleSubmit(e: React.FormEvent) {
        e.preventDefault();

        if (editingTest) {
            await supabase
                .from("beta_tests")
                .update(formData)
                .eq("id", editingTest.id);
        } else {
            await supabase.from("beta_tests").insert(formData);
        }

        resetForm();
        loadTests();
    }

    async function handleDelete(id: string) {
        if (confirm("Diesen Test wirklich löschen?")) {
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
            google_groups_link: test.google_groups_link,
            playstore_link: test.playstore_link,
            is_active: test.is_active,
        });
        setShowForm(true);
    }

    function resetForm() {
        setFormData({
            name: "",
            description: "",
            google_groups_link: "",
            playstore_link: "",
            is_active: true,
        });
        setEditingTest(null);
        setShowForm(false);
    }

    function exportCSV(testId: string, testName: string) {
        const regs = registrations[testId] || [];
        const headers = ["Name", "Email", "Status", "Datum"];
        const rows = regs.map((r) => [
            r.name,
            r.email,
            r.status,
            new Date(r.created_at).toLocaleDateString("de-DE"),
        ]);

        const csv = [headers, ...rows].map((row) => row.join(";")).join("\n");
        const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
        const url = URL.createObjectURL(blob);
        const link = document.createElement("a");
        link.href = url;
        link.download = `${testName.replace(/\s+/g, "_")}_registrations.csv`;
        link.click();
    }

    return (
        <div className={styles.adminContainer}>
            <header className={styles.header}>
                <h1>🛠️ Admin Panel</h1>
                <p>Beta-Test Verwaltung</p>
            </header>

            <main className={styles.main}>
                <div className={styles.actions}>
                    <button
                        className={`btn btn-primary ${styles.createBtn}`}
                        onClick={() => setShowForm(!showForm)}
                    >
                        {showForm ? "Abbrechen" : "+ Neuen Test erstellen"}
                    </button>
                </div>

                {showForm && (
                    <form onSubmit={handleSubmit} className={styles.form}>
                        <h2>{editingTest ? "Test bearbeiten" : "Neuen Test erstellen"}</h2>

                        <div className={styles.field}>
                            <label>Test Name</label>
                            <input
                                type="text"
                                required
                                placeholder="z.B. Habiter v1.0 Beta"
                                value={formData.name}
                                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                            />
                        </div>

                        <div className={styles.field}>
                            <label>Beschreibung</label>
                            <textarea
                                placeholder="Kurze Beschreibung des Tests..."
                                value={formData.description}
                                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                            />
                        </div>

                        <div className={styles.field}>
                            <label>Google Groups Link</label>
                            <input
                                type="url"
                                required
                                placeholder="https://groups.google.com/g/..."
                                value={formData.google_groups_link}
                                onChange={(e) => setFormData({ ...formData, google_groups_link: e.target.value })}
                            />
                            <small>Link zur Google Group für interne Tester</small>
                        </div>

                        <div className={styles.field}>
                            <label>Play Store Test Link</label>
                            <input
                                type="url"
                                required
                                placeholder="https://play.google.com/apps/testing/..."
                                value={formData.playstore_link}
                                onChange={(e) => setFormData({ ...formData, playstore_link: e.target.value })}
                            />
                            <small>Link zum Play Store Test Opt-in</small>
                        </div>

                        <div className={styles.checkbox}>
                            <input
                                type="checkbox"
                                id="is_active"
                                checked={formData.is_active}
                                onChange={(e) => setFormData({ ...formData, is_active: e.target.checked })}
                            />
                            <label htmlFor="is_active">Test ist aktiv (akzeptiert Registrierungen)</label>
                        </div>

                        <div className={styles.formActions}>
                            <button type="submit" className="btn btn-primary">
                                {editingTest ? "Speichern" : "Test erstellen"}
                            </button>
                            <button type="button" className={styles.cancelBtn} onClick={resetForm}>
                                Abbrechen
                            </button>
                        </div>
                    </form>
                )}

                <div className={styles.testsList}>
                    {tests.length === 0 ? (
                        <div className={styles.empty}>
                            <p>Noch keine Tests erstellt.</p>
                            <p>Erstelle deinen ersten Beta-Test!</p>
                        </div>
                    ) : (
                        tests.map((test) => (
                            <div key={test.id} className={styles.testCard}>
                                <div className={styles.testHeader}>
                                    <h3>
                                        {test.name}
                                        <span className={test.is_active ? styles.active : styles.inactive}>
                                            {test.is_active ? "Aktiv" : "Inaktiv"}
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
                                        <strong>Google Groups:</strong>{" "}
                                        <a href={test.google_groups_link} target="_blank" rel="noopener noreferrer">
                                            {test.google_groups_link}
                                        </a>
                                    </div>
                                    <div>
                                        <strong>Play Store:</strong>{" "}
                                        <a href={test.playstore_link} target="_blank" rel="noopener noreferrer">
                                            {test.playstore_link}
                                        </a>
                                    </div>
                                </div>

                                <div className={styles.registrations}>
                                    <div className={styles.regHeader}>
                                        <h4>
                                            Registrierungen ({(registrations[test.id] || []).length})
                                        </h4>
                                        {(registrations[test.id] || []).length > 0 && (
                                            <button
                                                className={styles.exportBtn}
                                                onClick={() => exportCSV(test.id, test.name)}
                                            >
                                                📥 CSV Export
                                            </button>
                                        )}
                                    </div>

                                    {(registrations[test.id] || []).length === 0 ? (
                                        <p className={styles.noRegs}>Noch keine Registrierungen.</p>
                                    ) : (
                                        <table className={styles.regTable}>
                                            <thead>
                                                <tr>
                                                    <th>Name</th>
                                                    <th>Email</th>
                                                    <th>Status</th>
                                                    <th>Datum</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                {(registrations[test.id] || []).map((reg) => (
                                                    <tr key={reg.id}>
                                                        <td>{reg.name}</td>
                                                        <td>{reg.email}</td>
                                                        <td>
                                                            <span className={styles[reg.status]}>
                                                                {reg.status}
                                                            </span>
                                                        </td>
                                                        <td>
                                                            {new Date(reg.created_at).toLocaleDateString("de-DE")}
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
            </main>
        </div>
    );
}

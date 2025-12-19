"use client";

import { useLocale } from "@/lib/i18n";
import { supabase } from "@/lib/supabase";
import { useState } from "react";
import styles from "../admin.module.css";

export default function AdminLoginPage() {
    const { t } = useLocale();
    const [email, setEmail] = useState("");
    const [password, setPassword] = useState("");
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState("");

    async function handleLogin(e: React.FormEvent) {
        e.preventDefault();
        setLoading(true);
        setError("");

        const { error } = await supabase.auth.signInWithPassword({
            email,
            password,
        });

        setLoading(false);

        if (error) {
            setError(t.admin.login.error);
        } else {
            window.location.href = "/admin";
        }
    }

    return (
        <div className={styles.loginContainer}>
            <div className={styles.loginCard}>
                <h1>{t.admin.login.title}</h1>

                <form onSubmit={handleLogin} className={styles.loginForm}>
                    <div className={styles.field}>
                        <label>{t.admin.login.email}</label>
                        <input
                            type="email"
                            required
                            value={email}
                            onChange={(e) => setEmail(e.target.value)}
                        />
                    </div>

                    <div className={styles.field}>
                        <label>{t.admin.login.password}</label>
                        <input
                            type="password"
                            required
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                        />
                    </div>

                    {error && <p className={styles.error}>{error}</p>}

                    <button type="submit" className={styles.loginBtn} disabled={loading}>
                        {loading ? t.common.loading : t.admin.login.submit}
                    </button>
                </form>
            </div>
        </div>
    );
}

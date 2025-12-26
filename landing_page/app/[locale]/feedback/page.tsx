"use client";

import { Footer, Header } from "@/components";
import { Locale, translations } from "@/lib/i18n";
import { supabase } from "@/lib/supabase";
import { useParams } from "next/navigation";
import { useState } from "react";
import styles from "./feedback.module.css";

export default function FeedbackPage() {
    const params = useParams();
    const locale = (params.locale as Locale) || "de";
    const t = translations[locale] || translations.de;

    const [formData, setFormData] = useState({
        name: "",
        email: "",
        type: "suggestion",
        message: "",
    });
    const [submitting, setSubmitting] = useState(false);
    const [success, setSuccess] = useState(false);
    const [error, setError] = useState("");

    const content = {
        de: {
            title: "Feedback",
            subtitle: "Wir freuen uns über dein Feedback! Deine Meinung hilft uns, Habiter noch besser zu machen.",
            form: {
                name: "Name (optional)",
                namePlaceholder: "Dein Name",
                email: "E-Mail (optional)",
                emailPlaceholder: "deine@email.de",
                emailHint: "Nur wenn du eine Antwort erhalten möchtest",
                type: "Art des Feedbacks",
                types: {
                    suggestion: "💡 Vorschlag",
                    bug: "🐛 Bug-Report",
                    praise: "⭐ Lob",
                    question: "❓ Frage",
                    other: "📝 Sonstiges",
                },
                message: "Deine Nachricht",
                messagePlaceholder: "Was möchtest du uns mitteilen?",
                submit: "Feedback absenden",
                submitting: "Wird gesendet...",
            },
            success: {
                title: "Vielen Dank! 🎉",
                message: "Dein Feedback wurde erfolgreich übermittelt. Wir schätzen deine Meinung sehr!",
                back: "← Zurück zur Startseite",
            },
            error: "Beim Senden ist ein Fehler aufgetreten. Bitte versuche es später erneut.",
        },
        en: {
            title: "Feedback",
            subtitle: "We love hearing from you! Your feedback helps us make Habiter even better.",
            form: {
                name: "Name (optional)",
                namePlaceholder: "Your name",
                email: "Email (optional)",
                emailPlaceholder: "your@email.com",
                emailHint: "Only if you want a response",
                type: "Feedback Type",
                types: {
                    suggestion: "💡 Suggestion",
                    bug: "🐛 Bug Report",
                    praise: "⭐ Praise",
                    question: "❓ Question",
                    other: "📝 Other",
                },
                message: "Your Message",
                messagePlaceholder: "What would you like to tell us?",
                submit: "Send Feedback",
                submitting: "Sending...",
            },
            success: {
                title: "Thank You! 🎉",
                message: "Your feedback has been submitted successfully. We really appreciate your input!",
                back: "← Back to Home",
            },
            error: "An error occurred while sending. Please try again later.",
        },
    };

    const c = content[locale] || content.de;

    async function handleSubmit(e: React.FormEvent) {
        e.preventDefault();
        setSubmitting(true);
        setError("");

        const { error } = await supabase.from("feedback").insert({
            name: formData.name || null,
            email: formData.email || null,
            type: formData.type,
            message: formData.message,
            locale: locale,
        });

        setSubmitting(false);

        if (error) {
            setError(c.error);
            console.error(error);
        } else {
            setSuccess(true);
        }
    }

    if (success) {
        return (
            <div className="container">
                <Header locale={locale} showFeatures={false} showDownload={false} />
                <div className={styles.successContainer}>
                    <div className={styles.successCard}>
                        <span className={styles.successIcon}>✉️</span>
                        <h1>{c.success.title}</h1>
                        <p>{c.success.message}</p>
                        <a href={`/${locale}`} className={styles.backLink}>
                            {c.success.back}
                        </a>
                    </div>
                </div>
                <Footer locale={locale} />
            </div>
        );
    }

    return (
        <div className="container">
            <Header locale={locale} showFeatures={false} showDownload={false} />

            <div className={styles.feedbackPage}>
                <div className={styles.header}>
                    <h1>{c.title}</h1>
                    <p>{c.subtitle}</p>
                </div>

                <form onSubmit={handleSubmit} className={styles.form}>
                    <div className={styles.formRow}>
                        <div className={styles.field}>
                            <label>{c.form.name}</label>
                            <input
                                type="text"
                                placeholder={c.form.namePlaceholder}
                                value={formData.name}
                                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                            />
                        </div>

                        <div className={styles.field}>
                            <label>{c.form.email}</label>
                            <input
                                type="email"
                                placeholder={c.form.emailPlaceholder}
                                value={formData.email}
                                onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                            />
                            <small>{c.form.emailHint}</small>
                        </div>
                    </div>

                    <div className={styles.field}>
                        <label>{c.form.type}</label>
                        <div className={styles.typeSelector}>
                            {Object.entries(c.form.types).map(([key, label]) => (
                                <button
                                    key={key}
                                    type="button"
                                    className={`${styles.typeOption} ${formData.type === key ? styles.selected : ""}`}
                                    onClick={() => setFormData({ ...formData, type: key })}
                                >
                                    {label}
                                </button>
                            ))}
                        </div>
                    </div>

                    <div className={styles.field}>
                        <label>{c.form.message} *</label>
                        <textarea
                            required
                            rows={6}
                            placeholder={c.form.messagePlaceholder}
                            value={formData.message}
                            onChange={(e) => setFormData({ ...formData, message: e.target.value })}
                        />
                    </div>

                    {error && <p className={styles.error}>{error}</p>}

                    <button type="submit" className={styles.submitBtn} disabled={submitting}>
                        {submitting ? c.form.submitting : c.form.submit}
                    </button>
                </form>
            </div>

            <Footer locale={locale} />
        </div>
    );
}

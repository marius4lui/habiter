"use client";

import { createContext, ReactNode, useContext, useEffect, useState } from "react";

export type Locale = "de" | "en";

// All translations
export const translations = {
    de: {
        // Common
        common: {
            habiter: "Habiter",
            download: "Download",
            features: "Funktionen",
            home: "Home",
            copyright: "© 2025 Habiter. Alle Rechte vorbehalten.",
            submit: "Absenden",
            cancel: "Abbrechen",
            save: "Speichern",
            delete: "Löschen",
            edit: "Bearbeiten",
            loading: "Lädt...",
            error: "Fehler",
            success: "Erfolg",
        },
        // Navigation
        nav: {
            privacy: "Datenschutz",
            terms: "AGB",
            imprint: "Impressum",
            langSwitch: "EN",
        },
        // Home page
        home: {
            title: "Gewohnheiten, die bleiben.",
            subtitle: "Erlebe eine moderne, organische Art, deine täglichen Routinen zu verfolgen. Wunderschön gestaltet mit haptischem Feedback und flüssigen Animationen.",
            downloadBtn: "App herunterladen",
            startJourney: "Starte deine Reise noch heute.",
            availableFor: "Verfügbar für Android.",
        },
        // Features
        features: {
            organic: {
                title: "Organisches Design",
                desc: "Eine Benutzeroberfläche, die sich lebendig anfühlt. Glassmorphismus, unscharfe Hintergründe und weiche Übergänge machen das Tracking zum Vergnügen.",
            },
            haptic: {
                title: "Haptisches Feedback",
                desc: "Spüre deinen Fortschritt. Befriedigendes haptisches Feedback belohnt dich für jede abgeschlossene Gewohnheit.",
            },
            ai: {
                title: "KI-Insights",
                desc: "Smarte Empfehlungen und Analysen deiner Gewohnheiten helfen dir, am Ball zu bleiben und dich zu verbessern.",
            },
        },
        // Test page
        test: {
            title: "Beta-Tester werden",
            intro: "Werde Teil unserer exklusiven Beta-Tester-Community und teste neue Features vor allen anderen!",
            dataInfo: {
                title: "📋 Was passiert mit deinen Daten?",
                items: [
                    "Dein Name und E-Mail werden gespeichert, um dich für den Test freizuschalten",
                    "Du erhältst einen personalisierten Link zum Google Play Store Test",
                    "Deine E-Mail muss mit deinem Google-Account verknüpft sein",
                ],
            },
            howTo: {
                title: "📱 So bekommst du die App:",
                steps: [
                    "Registriere dich mit deinem Google-Account E-Mail",
                    "Tritt der Google Group bei (Link nach Registrierung)",
                    "Öffne den Play Store Link",
                    "Lade die Beta-Version herunter",
                ],
            },
            form: {
                firstName: "Vorname",
                firstNamePlaceholder: "Max",
                lastName: "Nachname",
                lastNamePlaceholder: "Mustermann",
                email: "E-Mail (Google Account)",
                emailPlaceholder: "deine.email@gmail.com",
                emailHint: "Nutze die E-Mail deines Google Play Store Accounts",
                submit: "Zum Beta-Test anmelden",
                submitting: "Wird gesendet...",
                selectTest: "Test auswählen",
            },
            success: {
                title: "Registrierung erfolgreich!",
                thanks: "Vielen Dank für deine Anmeldung zum Beta-Test.",
                nextSteps: "Nächste Schritte:",
                joinGroup: "Google Group beitreten:",
                downloadApp: "App im Play Store herunterladen:",
                openStore: "Play Store öffnen",
            },
            noTests: "Aktuell sind keine Tests verfügbar.",
            errorMsg: "Registrierung fehlgeschlagen. Bitte versuche es erneut.",
            demo: {
                title: "📱 App Vorschau",
                caption: "Glassmorphismus Design • Haptisches Feedback • KI-Insights",
                habits: ["Meditieren", "Sport treiben", "Wasser trinken", "Lesen"],
                streak: "Tage Streak",
                completed: "Abgeschlossen",
            },
            priority: {
                stable: "Stabil",
                beta: "Beta",
                alpha: "Alpha",
                nightly: "Nightly",
            },
            googleGroups: {
                title: "So wirst du Beta-Tester",
                description: "Um die Beta-Version zu testen, tritt einfach unserer Google Group bei. Das ist alles, was du tun musst!",
                step1: "Klicke auf den Button unten, um der Google Group beizutreten",
                step2: "Bestätige deine Mitgliedschaft mit deinem Google-Account",
                step3: "Lade die App im Play Store herunter (Link unten)",
                joinBtn: "Google Group beitreten",
                downloadBtn: "App im Play Store herunterladen",
            },
            optin: {
                title: "Opt-in erforderlich",
                description: "Bevor du die App herunterladen kannst, musst du dich zuerst für den Beta-Test anmelden.",
                button: "Zum Beta Opt-in",
            },
        },
        // Admin
        admin: {
            title: "Admin Panel",
            subtitle: "Beta-Test Verwaltung",
            createTest: "+ Neuen Test erstellen",
            editTest: "Test bearbeiten",
            testName: "Test Name",
            testNamePlaceholder: "z.B. Habiter v1.0 Beta",
            description: "Beschreibung",
            descPlaceholder: "Kurze Beschreibung des Tests...",
            googleGroups: "Google Groups Link",
            googleGroupsHint: "Link zur Google Group für interne Tester",
            playStore: "Play Store Test Link",
            playStoreHint: "Link zum Play Store Test Opt-in",
            priority: "Priorität",
            isActive: "Test ist aktiv (akzeptiert Registrierungen)",
            requiresOptin: "Opt-in Bestätigung erforderlich",
            optinLink: "Opt-in Link",
            optinLinkHint: "Externer Link den Nutzer bestätigen müssen (z.B. Play Store Beta Opt-in)",
            noTests: "Noch keine Tests erstellt.",
            createFirst: "Erstelle deinen ersten Beta-Test!",
            registrations: "Registrierungen",
            csvExport: "📥 CSV Export",
            noRegistrations: "Noch keine Registrierungen.",
            deleteConfirm: "Diesen Test wirklich löschen?",
            login: {
                title: "Admin Login",
                email: "E-Mail",
                password: "Passwort",
                submit: "Anmelden",
                error: "Login fehlgeschlagen. Bitte überprüfe deine Zugangsdaten.",
            },
            logout: "Abmelden",
            date: "Datum",
            status: "Status",
        },
    },
    en: {
        common: {
            habiter: "Habiter",
            download: "Download",
            features: "Features",
            home: "Home",
            copyright: "© 2025 Habiter. All rights reserved.",
            submit: "Submit",
            cancel: "Cancel",
            save: "Save",
            delete: "Delete",
            edit: "Edit",
            loading: "Loading...",
            error: "Error",
            success: "Success",
        },
        nav: {
            privacy: "Privacy Policy",
            terms: "Terms of Service",
            imprint: "Imprint",
            langSwitch: "DE",
        },
        home: {
            title: "Build habits that stick.",
            subtitle: "Experience a modern, organic way to track your daily routines. Beautifully designed with haptic feedback and fluid animations.",
            downloadBtn: "Download App",
            startJourney: "Start your journey today.",
            availableFor: "Available for Android.",
        },
        features: {
            organic: {
                title: "Organic Design",
                desc: "A user interface that feels alive. Glassmorphism, blurred backgrounds, and smooth transitions make tracking a delight.",
            },
            haptic: {
                title: "Haptic Feedback",
                desc: "Feel your progress. Satisfying haptic feedback rewards you for every completed habit.",
            },
            ai: {
                title: "AI Insights",
                desc: "Smart recommendations and analysis of your habits to help you stay on track and improve.",
            },
        },
        test: {
            title: "Become a Beta Tester",
            intro: "Join our exclusive beta testing community and try new features before anyone else!",
            dataInfo: {
                title: "📋 What happens with your data?",
                items: [
                    "Your name and email are stored to grant you test access",
                    "You will receive a personalized Google Play Store test link",
                    "Your email must be linked to your Google Account",
                ],
            },
            howTo: {
                title: "📱 How to get the app:",
                steps: [
                    "Register with your Google Account email",
                    "Join the Google Group (link after registration)",
                    "Open the Play Store link",
                    "Download the beta version",
                ],
            },
            form: {
                firstName: "First Name",
                firstNamePlaceholder: "John",
                lastName: "Last Name",
                lastNamePlaceholder: "Doe",
                email: "Email (Google Account)",
                emailPlaceholder: "your.email@gmail.com",
                emailHint: "Use the email of your Google Play Store account",
                submit: "Sign Up for Beta Test",
                submitting: "Submitting...",
                selectTest: "Select Test",
            },
            success: {
                title: "Registration Successful!",
                thanks: "Thank you for signing up for the beta test.",
                nextSteps: "Next Steps:",
                joinGroup: "Join Google Group:",
                downloadApp: "Download app from Play Store:",
                openStore: "Open Play Store",
            },
            noTests: "No tests are currently available.",
            errorMsg: "Registration failed. Please try again.",
            demo: {
                title: "📱 App Preview",
                caption: "Glassmorphism Design • Haptic Feedback • AI Insights",
                habits: ["Meditate", "Exercise", "Drink water", "Read"],
                streak: "Day Streak",
                completed: "Completed",
            },
            priority: {
                stable: "Stable",
                beta: "Beta",
                alpha: "Alpha",
                nightly: "Nightly",
            },
            googleGroups: {
                title: "How to become a Beta Tester",
                description: "To test the beta version, simply join our Google Group. That's all you need to do!",
                step1: "Click the button below to join the Google Group",
                step2: "Confirm your membership with your Google Account",
                step3: "Download the app from Play Store (link below)",
                joinBtn: "Join Google Group",
                downloadBtn: "Download App from Play Store",
            },
            optin: {
                title: "Opt-in Required",
                description: "Before you can download the app, you need to sign up for the beta test first.",
                button: "Go to Beta Opt-in",
            },
        },
        admin: {
            title: "Admin Panel",
            subtitle: "Beta Test Management",
            createTest: "+ Create New Test",
            editTest: "Edit Test",
            testName: "Test Name",
            testNamePlaceholder: "e.g. Habiter v1.0 Beta",
            description: "Description",
            descPlaceholder: "Short description of the test...",
            googleGroups: "Google Groups Link",
            googleGroupsHint: "Link to Google Group for internal testers",
            playStore: "Play Store Test Link",
            playStoreHint: "Link to Play Store test opt-in",
            priority: "Priority",
            isActive: "Test is active (accepting registrations)",
            requiresOptin: "Opt-in confirmation required",
            optinLink: "Opt-in Link",
            optinLinkHint: "External link users must confirm (e.g. Play Store Beta Opt-in)",
            noTests: "No tests created yet.",
            createFirst: "Create your first beta test!",
            registrations: "Registrations",
            csvExport: "📥 CSV Export",
            noRegistrations: "No registrations yet.",
            deleteConfirm: "Really delete this test?",
            login: {
                title: "Admin Login",
                email: "Email",
                password: "Password",
                submit: "Sign In",
                error: "Login failed. Please check your credentials.",
            },
            logout: "Sign Out",
            date: "Date",
            status: "Status",
        },
    },
} as const;

type TranslationsMap = typeof translations;
type TranslationType = TranslationsMap[Locale];

const LocaleContext = createContext<{
    locale: Locale;
    setLocale: (locale: Locale) => void;
    t: TranslationType;
}>({
    locale: "de",
    setLocale: () => { },
    t: translations.de,
});

export function LocaleProvider({ children }: { children: ReactNode }) {
    const [locale, setLocale] = useState<Locale>("de");

    useEffect(() => {
        // Auto-detect from browser
        const browserLang = navigator.language.toLowerCase();
        if (browserLang.startsWith("de")) {
            setLocale("de");
        } else {
            setLocale("en");
        }

        // Check localStorage for saved preference
        const saved = localStorage.getItem("locale") as Locale;
        if (saved && (saved === "de" || saved === "en")) {
            setLocale(saved);
        }
    }, []);

    const handleSetLocale = (newLocale: Locale) => {
        setLocale(newLocale);
        localStorage.setItem("locale", newLocale);
    };

    return (
        <LocaleContext.Provider
            value={{
                locale,
                setLocale: handleSetLocale,
                t: translations[locale],
            }}
        >
            {children}
        </LocaleContext.Provider>
    );
}

export function useLocale() {
    return useContext(LocaleContext);
}

// Helper for priority labels
export function getPriorityLabel(priority: number, t: TranslationType): string {
    switch (priority) {
        case 0:
            return t.test.priority.stable;
        case 1:
            return t.test.priority.beta;
        case 2:
            return t.test.priority.alpha;
        case 3:
            return t.test.priority.nightly;
        default:
            return t.test.priority.beta;
    }
}

export const locales = ["de", "en"] as const;
export type Locale = (typeof locales)[number];

const dictionaries = {
  de: {
    nav: { features: "Funktionen", demo: "Lokale Demo", language: "English" },
    hero: {
      eyebrow: "Routinen ohne Schuldgefühl",
      title: "Kleine Schritte. Ein ruhigerer Rhythmus.",
      body: "Habiter hilft dir, Gewohnheiten lokal zu planen, abzuhaken und nach Pausen freundlich wieder aufzunehmen.",
      cta: "Demo ausprobieren",
      note: "Lokale Web-Demo · keine Anmeldung",
    },
    features: [
      ["Heute im Blick", "Fällige Routinen, Fortschritt und ein klarer nächster Schritt."],
      ["Pausen gehören dazu", "Pausieren, archivieren und zurückkehren, ohne Verlauf zu verlieren."],
      ["Daten unter deiner Kontrolle", "Lokale Speicherung sowie expliziter Export und Import."],
    ],
    privacy: "Habit-Daten bleiben standardmäßig auf deinem Gerät. Erinnerungen und optionale Integrationen werden erst nach deiner Entscheidung aktiv.",
    platform: "Die native App wird für Android entwickelt. App Lock ist Android-spezifisch; die Website-Demo simuliert nur den Habit-Flow.",
  },
  en: {
    nav: { features: "Features", demo: "Local demo", language: "Deutsch" },
    hero: {
      eyebrow: "Routines without guilt",
      title: "Small steps. A calmer rhythm.",
      body: "Habiter helps you plan and complete habits locally, then return gently after a break.",
      cta: "Try the demo",
      note: "Local web demo · no account",
    },
    features: [
      ["Today at a glance", "Due routines, progress, and one clear next step."],
      ["Breaks belong", "Pause, archive, and return without losing history."],
      ["Your data, your control", "Local storage with explicit export and import."],
    ],
    privacy: "Habit data stays on your device by default. Reminders and optional integrations activate only after your choice.",
    platform: "The native app is developed for Android. App Lock is Android-specific; the website demo only simulates the habit flow.",
  },
} as const;

export function isLocale(value: string): value is Locale {
  return locales.includes(value as Locale);
}

export function getDictionary(locale: Locale) {
  return dictionaries[locale];
}

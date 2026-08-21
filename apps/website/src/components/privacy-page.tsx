import Link from "next/link";

import styles from "./deep-dive-pages.module.css";
import { SiteShell } from "./site-shell";

const localCategories = [
  { icon: "✓", title: "Gewohnheiten & Verlauf", copy: "Zeitpläne, Lifecycle-Status und Abschlussgeschichte." },
  { icon: "⌁", title: "Reminder & Lernen", copy: "Pläne, lokale Signale und Verfügbarkeitsprofile." },
  { icon: "◇", title: "App Lock", copy: "Konfiguration und die minimale Android-Service-Projektion." },
  { icon: "○", title: "Einstellungen", copy: "Darstellung, Sprache, Onboarding und Update-Präferenzen." },
] as const;

const boundaries = [
  {
    label: "Bewusster Export",
    title: "Backup in deiner Hand",
    copy: "Ein versioniertes JSON-Backup wird erst auf deine Aktion in die Zwischenablage kopiert.",
    direction: "Gerät → deine Ablage",
  },
  {
    label: "Optionale Integration",
    title: "Nur wenn du verbindest",
    copy: "Classly-kompatible Synchronisation spricht mit dem HTTPS-Dienst, den du selbst konfigurierst.",
    direction: "Gerät ↔ dein Dienst",
  },
  {
    label: "Experimentelle AI",
    title: "Provider unter deiner Kontrolle",
    copy: "Remote-AI sendet nur für die ausgewählte Anfrage Daten an den von dir konfigurierten Provider.",
    direction: "Nur nach Aktivierung",
  },
  {
    label: "Release-Prüfung",
    title: "Updates ohne Habit-Payload",
    copy: "Habiter lädt signierte Release-Metadaten und Plattforminformationen, aber keine Gewohnheitsdaten hoch.",
    direction: "Nur öffentliche Metadaten",
  },
] as const;

export function PrivacyPage() {
  return (
    <SiteShell>
      <main className={styles.main} id="content">
        <section className={styles.privacyHero}>
          <div className={`site-container ${styles.heroGrid}`}>
            <div className={styles.heroCopy}>
              <span className="eyebrow">Local-first by design</span>
              <h1>
                Deine Gewohnheiten.
                <span>Deine Geschichte. Dein Gerät.</span>
              </h1>
              <p>
                Core Tracking braucht kein Habiter-Konto und keinen Habiter-Cloud-Sync. Persönliche
                Routinen, Verlauf und lokale Insights bleiben dort, wo sie entstehen.
              </p>
              <div className={styles.heroActions}>
                <a className="button button-primary" href="https://docs.habiter.dev/guide/data-and-privacy">
                  Technische Dokumentation <span aria-hidden="true">↗</span>
                </a>
                <a className="button button-secondary" href="#data-map">
                  Datenfluss ansehen <span aria-hidden="true">↓</span>
                </a>
              </div>
              <div className={styles.privacyFacts}>
                <span><b>Kein</b> Konto für Core Tracking</span>
                <span><b>Kein</b> Habiter Cloud-Sync</span>
                <span><b>MIT</b> Open Source</span>
              </div>
            </div>
            <div className={styles.localDevice} aria-label="Lokaler Habiter-Datenfluss">
              <div className={styles.localDeviceHead}>
                <span /> <span /> <span />
                <strong>habiter · local state</strong>
              </div>
              <div className={styles.localCore}>
                <span className={styles.localShield}>✓</span>
                <small>Auf diesem Gerät gespeichert</small>
                <h2>Dein digitales Habitat</h2>
                <p>Gewohnheiten, Einträge, Rhythmus und Coaching bleiben lokal.</p>
              </div>
              <div className={styles.localNodes}>
                <div><span>01</span><strong>Habit</strong><small>Wasser trinken</small></div>
                <i>→</i>
                <div><span>02</span><strong>Eintrag</strong><small>Heute · erledigt</small></div>
                <i>→</i>
                <div><span>03</span><strong>Insight</strong><small>lokal berechnet</small></div>
              </div>
              <div className={styles.localDeviceFoot}>✓ Kein Remote-Konto notwendig</div>
            </div>
          </div>
        </section>

        <section className={styles.privacyPrinciple}>
          <div className={`site-container ${styles.privacyPrincipleInner}`}>
            <span aria-hidden="true">⌂</span>
            <h2>
              Local-first ist kein Badge.
              <strong>Es ist die Architektur des Kernprodukts.</strong>
            </h2>
            <p>Netzwerkgrenzen entstehen nur dort, wo du eine optionale Funktion bewusst wählst.</p>
          </div>
        </section>

        <section className={`site-container ${styles.dataMap}`} id="data-map">
          <div className={styles.sectionIntro}>
            <span className="eyebrow">Was lokal bleibt</span>
            <h2>Die Daten, die dein Verhalten beschreiben, leben auf deinem Gerät.</h2>
            <p>
              Native Widgets und Android-Services erhalten nur die minimale Projektion, die ihre
              Funktion benötigt. Die kanonische App-Datenhaltung bleibt die Quelle der Wahrheit.
            </p>
          </div>
          <div className={styles.localCategoryGrid}>
            {localCategories.map((category) => (
              <article key={category.title}>
                <span aria-hidden="true">{category.icon}</span>
                <h3>{category.title}</h3>
                <p>{category.copy}</p>
                <strong><i /> Lokal gespeichert</strong>
              </article>
            ))}
          </div>
        </section>

        <section className={styles.boundarySection}>
          <div className={`site-container ${styles.boundaryGrid}`}>
            <div className={styles.boundaryIntro}>
              <span className="eyebrow">Klare Netzwerkgrenzen</span>
              <h2>Wenn Daten das Gerät verlassen können, ist der Auslöser sichtbar.</h2>
              <p>
                Kerntracking bleibt offline-fähig. Export, Integrationen und experimentelle Remote-AI
                sind bewusste, getrennte Entscheidungen mit eigenen Bedingungen.
              </p>
            </div>
            <div className={styles.boundaryCards}>
              {boundaries.map((boundary, index) => (
                <article key={boundary.title}>
                  <div><span>{String(index + 1).padStart(2, "0")}</span><strong>{boundary.label}</strong></div>
                  <h3>{boundary.title}</h3>
                  <p>{boundary.copy}</p>
                  <small>{boundary.direction} <b aria-hidden="true">→</b></small>
                </article>
              ))}
            </div>
          </div>
        </section>

        <section className={`site-container ${styles.backupSection}`}>
          <div className={styles.backupFlow}>
            <div className={styles.backupHead}>
              <div><span>Versioniertes JSON-Backup</span><strong>Import mit Vorschau und Recovery</strong></div>
              <b>v1</b>
            </div>
            <div className={styles.backupSteps}>
              <div><span>01</span><strong>Validieren</strong><small>Noch keine Änderung</small></div>
              <b>→</b>
              <div><span>02</span><strong>Vorschau</strong><small>Counts &amp; Konflikte</small></div>
              <b>→</b>
              <div><span>03</span><strong>Importieren</strong><small>Bestehendes bleibt</small></div>
              <b>→</b>
              <div><span>04</span><strong>Absichern</strong><small>Recovery-Backup</small></div>
            </div>
            <div className={styles.backupFoot}>✓ Ungültige oder inkompatible Daten werden vor jeder Mutation abgelehnt.</div>
          </div>
          <div className={styles.backupCopy}>
            <span className="eyebrow">Portabel ohne Cloud-Zwang</span>
            <h2>Deine Daten können gehen, ohne dir zu entgleiten.</h2>
            <p>
              Exportierte Backups gehören in einen sicheren Speicher deiner Wahl. Beim Import zeigt
              Habiter erst eine Vorschau, behält bestehende ID-Kollisionen und erstellt nach Erfolg
              ein Recovery-Backup des vorherigen Zustands.
            </p>
            <a className={styles.inlineLink} href="https://docs.habiter.dev/api/backup-format">
              Backup-Format ansehen <span aria-hidden="true">↗</span>
            </a>
          </div>
        </section>

        <section className={styles.controlSection}>
          <div className={`site-container ${styles.controlGrid}`}>
            <article>
              <span>Credentials</span>
              <h3>Secrets gehören in sicheren Plattform-Speicher.</h3>
              <p>
                OAuth-Tokens und experimentelle AI-Keys werden, wo verfügbar, im Secure Storage der
                Plattform gehalten — nicht in normalen Preferences, Backups oder Logs.
              </p>
            </article>
            <article>
              <span>Kontrolle</span>
              <h3>So schmal löschen wie möglich.</h3>
              <p>
                Reminder-Lernen, Update-Downloads, Integrationen und einzelne Habits lassen sich
                getrennt zurücksetzen, ohne automatisch alles andere zu entfernen.
              </p>
            </article>
            <article>
              <span>Diagnostics</span>
              <h3>Status statt persönlicher Inhalte.</h3>
              <p>
                Diagnoseflächen sind auf Kategorien und sichere Identifikatoren ausgelegt. Vor dem
                Teilen bleibt eine eigene Sichtprüfung trotzdem wichtig.
              </p>
            </article>
          </div>
        </section>

        <section className={`site-container ${styles.privacyCta}`}>
          <span className="eyebrow">Build better habits. Keep your data yours.</span>
          <h2>Ein Habit Tracker sollte dein Leben unterstützen — nicht sammeln.</h2>
          <p>Core Tracking funktioniert ohne Habiter-Konto und ohne Habiter-Cloud-Sync.</p>
          <div>
            <a className="button button-primary" href="https://get-the.habiter.dev/">
              Habiter herunterladen <span aria-hidden="true">↗</span>
            </a>
            <Link className="button button-secondary" href="/product/">
              Produkt Experience <span aria-hidden="true">→</span>
            </Link>
          </div>
        </section>
      </main>
    </SiteShell>
  );
}

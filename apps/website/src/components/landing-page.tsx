import Link from "next/link";

import { HabitProductDemo } from "./habit-product-demo";
import styles from "./landing-page.module.css";
import { SiteShell } from "./site-shell";

const principles = [
  {
    number: "01",
    title: "Heute statt irgendwann",
    copy: "Die App bringt genau die Wiederholung nach vorn, die jetzt zählt — mit einer kleinen Version für volle Tage.",
    signal: "Eine klare nächste Aktion",
  },
  {
    number: "02",
    title: "Rhythmus statt Schuld",
    copy: "Pausen bleiben Teil deiner Geschichte. Habiter zeigt Muster und Rückkehr, ohne einen schlechten Tag rot auszumalen.",
    signal: "Fortschritt ohne Perfektionsdruck",
  },
  {
    number: "03",
    title: "Fokus statt Willenskraft",
    copy: "Bewusste Reibung schützt dein wichtigstes Ritual vor den Apps, die sonst zuerst nach Aufmerksamkeit fragen.",
    signal: "Deine Absicht bekommt Vorsprung",
  },
] as const;

const platforms = ["Android", "Windows", "macOS", "Linux"] as const;

export function LandingPage() {
  return (
    <SiteShell>
      <main className={styles.main} id="content">
        <section className={styles.hero}>
          <div className={styles.heroAura} aria-hidden="true" />
          <div className={`site-container ${styles.heroGrid}`}>
            <div className={styles.heroCopy}>
              <span className="eyebrow">Habit Tracking, das dich nicht bewertet</span>
              <h1>
                Nicht härter versuchen.
                <span>Leichter zurückkommen.</span>
              </h1>
              <p>
                Habiter zeigt dir eine machbare Wiederholung, schützt sie vor Ablenkung und macht
                Fortschritt sichtbar — ohne dich für Pausen zu bestrafen.
              </p>
              <div className={styles.heroActions}>
                <a className="button button-primary" href="https://get-the.habiter.dev/">
                  Habiter herunterladen <span aria-hidden="true">↗</span>
                </a>
                <Link className="button button-secondary" href="/product/">
                  Die Experience ansehen <span aria-hidden="true">→</span>
                </Link>
              </div>
              <div className={styles.heroMeta} aria-label="Produktvorteile">
                <span>
                  <i aria-hidden="true">✓</i> Kein Konto für die Kernfunktionen
                </span>
                <span>
                  <i aria-hidden="true">✓</i> Lokale Gewohnheitsdaten
                </span>
              </div>
            </div>
            <div className={styles.demoWrap}>
              <span className={`${styles.orbitLabel} ${styles.orbitOne}`}>5 von 7 diese Woche</span>
              <span className={`${styles.orbitLabel} ${styles.orbitTwo}`}>+14% Rhythmus</span>
              <HabitProductDemo />
            </div>
          </div>
        </section>

        <section className={styles.trustStrip} aria-label="Habiter Eigenschaften">
          <div className={`site-container ${styles.trustInner}`}>
            <strong>Für echte Routinen gebaut</strong>
            <div>
              <span>Local-first</span>
              <span>Open Source</span>
              <span>Deutsch &amp; Englisch</span>
              <span>Mobile &amp; Desktop</span>
            </div>
          </div>
        </section>

        <section className={`site-container ${styles.problemSection}`}>
          <div className={styles.sectionIntro}>
            <span className="eyebrow">Der Unterschied</span>
            <h2>
              Ein Tracker zählt die Vergangenheit.
              <span>Habiter hilft bei der nächsten Entscheidung.</span>
            </h2>
            <p>
              Gute Systeme sind nicht dann wertvoll, wenn alles läuft. Sondern wenn sie dich nach
              einem vollen Tag freundlich zurück in Bewegung bringen.
            </p>
          </div>
          <div className={styles.principleGrid}>
            {principles.map((principle) => (
              <article className={styles.principleCard} key={principle.number}>
                <span className={styles.principleNumber}>{principle.number}</span>
                <h3>{principle.title}</h3>
                <p>{principle.copy}</p>
                <strong>
                  <span aria-hidden="true">↗</span> {principle.signal}
                </strong>
              </article>
            ))}
          </div>
        </section>

        <section className={styles.experienceSection}>
          <div className={`site-container ${styles.experienceGrid}`}>
            <div className={styles.experienceCopy}>
              <span className="eyebrow">Ein ruhiger Daily Flow</span>
              <h2>Öffnen. Verstehen. Handeln.</h2>
              <p>
                Die App hält den Moment klein: eine relevante Gewohnheit, ein klarer Status und ein
                Abschluss, der sich gut anfühlt.
              </p>
              <Link className={styles.textLink} href="/product/">
                Den gesamten Produktflow entdecken <span aria-hidden="true">→</span>
              </Link>
            </div>
            <div className={styles.flowStage}>
              <div className={styles.flowTop}>
                <span>Deine letzte Gewohnheit</span>
                <strong>🌿</strong>
                <h3>10 Minuten bewegen</h3>
              </div>
              <div className={styles.flowStatus}>
                <span>
                  <i /> Heute noch offen
                </span>
                <b>✓</b>
              </div>
              <div className={styles.flowWheel}>
                <span>Heute</span>
                <span>Rhythmus</span>
                <span>Insights</span>
              </div>
            </div>
          </div>
        </section>

        <section className={`site-container ${styles.bentoSection}`}>
          <div className={`${styles.bentoCard} ${styles.rhythmCard}`}>
            <div className={styles.cardCopy}>
              <span>Rhythmus</span>
              <h3>Sieh die Form deiner Woche — nicht nur eine Serie.</h3>
              <p>
                Wochenziele, Completion Rate und echte Pausen ergeben ein Bild, mit dem du etwas
                anfangen kannst.
              </p>
            </div>
            <div className={styles.miniWeek} aria-hidden="true">
              {["M", "D", "M", "D", "F", "S", "S"].map((day, index) => (
                <span className={index === 2 || index === 6 ? "" : styles.miniDayDone} key={`${day}-${index}`}>
                  <i>{index === 2 || index === 6 ? "" : "✓"}</i>
                  {day}
                </span>
              ))}
            </div>
          </div>

          <div className={`${styles.bentoCard} ${styles.insightCard}`}>
            <div className={styles.sparkIcon} aria-hidden="true">✦</div>
            <div className={styles.cardCopy}>
              <span>Lokale Insights</span>
              <h3>Ein Muster ist erst wertvoll, wenn es verständlich wird.</h3>
              <p>
                Habiter übersetzt deinen Verlauf in einen konkreten Hinweis — statt dir noch ein
                Dashboard zu geben, das du selbst deuten musst.
              </p>
            </div>
            <div className={styles.insightQuote}>
              <span>Dein stärkstes Zeitfenster</span>
              <strong>Bewegung vor 09:00 Uhr</strong>
              <em>+23% weitere Abschlüsse</em>
            </div>
          </div>

          <Link className={`${styles.bentoCard} ${styles.focusCard}`} href="/focus/">
            <div className={styles.focusVisual} aria-hidden="true">
              <span className={styles.focusRing} />
              <strong>◇</strong>
              <i>Social wartet</i>
              <i>Games wartet</i>
            </div>
            <div className={styles.cardCopy}>
              <span>Focus Shield</span>
              <h3>Manchmal braucht eine gute Absicht eine geschlossene Tür.</h3>
              <p>Schütze dein Kernritual mit bewusst gesetzter digitaler Reibung.</p>
              <b>Focus kennenlernen →</b>
            </div>
          </Link>
        </section>

        <section className={styles.returnSection}>
          <div className={`site-container ${styles.returnInner}`}>
            <span className={styles.returnMark} aria-hidden="true">↗</span>
            <blockquote>
              Nicht die perfekte Woche verändert dein Leben.
              <strong>Sondern die Fähigkeit, morgen wiederzukommen.</strong>
            </blockquote>
            <p>Habiter optimiert auf Wiederholung, Rückkehr und eine Identität, die langsam wächst.</p>
          </div>
        </section>

        <section className={`site-container ${styles.productLinks}`}>
          <div className={styles.sectionIntro}>
            <span className="eyebrow">Mehr als ein Häkchen</span>
            <h2>
              Ein kleines System.
              <span>Mit Tiefe an den richtigen Stellen.</span>
            </h2>
          </div>
          <div className={styles.linkGrid}>
            <Link href="/product/">
              <span>01 · Produkt</span>
              <h3>Today, Rhythmus &amp; Insights</h3>
              <p>Sieh, wie Habiter aus einem Vorsatz einen realistischen Daily Flow macht.</p>
              <b aria-hidden="true">→</b>
            </Link>
            <Link href="/focus/">
              <span>02 · Focus</span>
              <h3>Aufmerksamkeit schützen</h3>
              <p>Verstehe die Regeln hinter bewusster Reibung und App Lock.</p>
              <b aria-hidden="true">→</b>
            </Link>
            <Link href="/privacy/">
              <span>03 · Privacy</span>
              <h3>Deine Geschichte bleibt deine</h3>
              <p>Erfahre, welche Daten lokal bleiben und warum der Kern ohne Konto funktioniert.</p>
              <b aria-hidden="true">→</b>
            </Link>
          </div>
        </section>

        <section className={styles.openSection}>
          <div className={`site-container ${styles.openGrid}`}>
            <div>
              <span className="eyebrow">Offen gebaut</span>
              <h2>Vertrauen braucht keine Blackbox.</h2>
              <p>
                Habiter ist MIT-lizenziert. Die App, ihre lokalen Datenflüsse und der Release-Prozess
                können öffentlich nachvollzogen werden.
              </p>
              <div className={styles.openActions}>
                <a className="button button-secondary" href="https://github.com/marius4lui/habiter">
                  Quellcode ansehen <span aria-hidden="true">↗</span>
                </a>
                <Link className={styles.textLink} href="/privacy/">
                  Privacy im Detail →
                </Link>
              </div>
            </div>
            <div className={styles.codeCard} aria-label="Lokaler Habiter Datenfluss">
              <div className={styles.codeHead}>
                <span /> <span /> <span />
                <strong>habiter / local-first</strong>
              </div>
              <div className={styles.codeFlow}>
                <span>01</span>
                <div><strong>Deine Gewohnheit</strong><small>auf deinem Gerät</small></div>
                <b>→</b>
                <span>02</span>
                <div><strong>Dein Fortschritt</strong><small>lokal ausgewertet</small></div>
              </div>
              <div className={styles.codeFooter}>✓ Kein Konto für das Kern-Erlebnis</div>
            </div>
          </div>
        </section>

        <section className={`site-container ${styles.ctaSection}`}>
          <div className={styles.ctaGlow} aria-hidden="true" />
          <span className="eyebrow">Dein nächster kleiner Schritt</span>
          <h2>Baue etwas, zu dem du zurückkommen willst.</h2>
          <p>Habiter ist für Android und Desktop verfügbar.</p>
          <div className={styles.ctaActions}>
            <a className="button button-primary" href="https://get-the.habiter.dev/">
              Smart Download starten <span aria-hidden="true">↗</span>
            </a>
            <div className={styles.platforms} aria-label="Verfügbare Plattformen">
              {platforms.map((platform) => <span key={platform}>{platform}</span>)}
            </div>
          </div>
        </section>
      </main>
    </SiteShell>
  );
}

import Link from "next/link";

import { HabitProductDemo } from "./habit-product-demo";
import styles from "./product-page.module.css";
import { SiteShell } from "./site-shell";

const lifecycle = [
  {
    number: "01",
    label: "Start",
    title: "Mach aus einem Wunsch eine konkrete Wiederholung.",
    copy: "Wähle täglich, bestimmte Wochentage oder ein flexibles Wochenziel. Habiter gibt deiner Absicht eine Form, die in echte Kalender passt.",
  },
  {
    number: "02",
    label: "Heute",
    title: "Sieh genau das, was jetzt wirklich zählt.",
    copy: "Die jüngste aktive Gewohnheit steht im Mittelpunkt. Status, kleinste Version und Abschluss bleiben in Reichweite — ohne Informationswand.",
  },
  {
    number: "03",
    label: "Verstehen",
    title: "Lies deinen Rhythmus, nicht nur deine Serie.",
    copy: "Wochenansicht, Completion Rate und lokale Coaching-Hinweise machen aus Verlauf eine verständliche nächste Entscheidung.",
  },
  {
    number: "04",
    label: "Zurückkehren",
    title: "Pausiere das System, nicht deine Geschichte.",
    copy: "Gewohnheiten lassen sich pausieren, fortsetzen, archivieren und wiederherstellen. Die Historie bleibt Teil deines Weges.",
  },
] as const;

const scheduleOptions = [
  { icon: "○", title: "Jeden Tag", copy: "Für Rituale, die ihren festen Platz brauchen." },
  { icon: "⌁", title: "Bestimmte Tage", copy: "Für Routinen, die deinem Wochenplan folgen." },
  { icon: "↗", title: "Mal pro Woche", copy: "Für Flexibilität ohne beliebig zu werden." },
] as const;

export function ProductPage() {
  return (
    <SiteShell>
      <main className={styles.main} id="content">
        <section className={styles.hero}>
          <div className={styles.heroGradient} aria-hidden="true" />
          <div className={`site-container ${styles.heroGrid}`}>
            <div className={styles.heroCopy}>
              <span className="eyebrow">Die Habiter Experience</span>
              <h1>
                Das Wichtigste zuerst.
                <span>Den Rest, wenn du bereit bist.</span>
              </h1>
              <p>
                Habiter verbindet Tagesfokus, flexible Rhythmen und verständliche Insights zu einem
                System, das leicht beginnt und mit dir wächst.
              </p>
              <div className={styles.heroActions}>
                <a className="button button-primary" href="https://get-the.habiter.dev/">
                  Habiter herunterladen <span aria-hidden="true">↗</span>
                </a>
                <a className="button button-secondary" href="#flow">
                  So funktioniert es <span aria-hidden="true">↓</span>
                </a>
              </div>
              <div className={styles.heroFacts}>
                <span><b>3</b> flexible Rhythmusarten</span>
                <span><b>0</b> Kontozwang im Kern</span>
                <span><b>2</b> Sprachen</span>
              </div>
            </div>
            <div className={styles.demoStage}>
              <HabitProductDemo initialView="rhythm" compact />
            </div>
          </div>
        </section>

        <section className={styles.lifecycle} id="flow">
          <div className={`site-container ${styles.lifecycleGrid}`}>
            <div className={styles.lifecycleIntro}>
              <span className="eyebrow">Ein vollständiger Kreislauf</span>
              <h2>Von der Absicht bis zur Rückkehr.</h2>
              <p>
                Die Experience ist nicht um eine endlose Feature-Liste gebaut, sondern um vier
                Momente, die eine Gewohnheit wirklich tragen.
              </p>
            </div>
            <div className={styles.lifecycleSteps}>
              {lifecycle.map((step) => (
                <article key={step.number}>
                  <div>
                    <span>{step.number}</span>
                    <strong>{step.label}</strong>
                  </div>
                  <h3>{step.title}</h3>
                  <p>{step.copy}</p>
                </article>
              ))}
            </div>
          </div>
        </section>

        <section className={`site-container ${styles.scheduleSection}`}>
          <div className={styles.scheduleCopy}>
            <span className="eyebrow">Rhythmen, die zum Leben passen</span>
            <h2>Die richtige Struktur ist die, die du wiederholen kannst.</h2>
            <p>
              Nicht jede Gewohnheit gehört an jeden Tag. Habiter trennt Ziel und Termin so, dass
              Regelmäßigkeit präzise bleibt — ohne starr zu werden.
            </p>
          </div>
          <div className={styles.scheduleVisual}>
            <div className={styles.scheduleHeader}>
              <div>
                <span>Neue Gewohnheit</span>
                <strong>Wann möchtest du lesen?</strong>
              </div>
              <b>2 / 3</b>
            </div>
            <div className={styles.scheduleOptions}>
              {scheduleOptions.map((option, index) => (
                <div className={index === 1 ? styles.scheduleActive : ""} key={option.title}>
                  <span aria-hidden="true">{option.icon}</span>
                  <div>
                    <strong>{option.title}</strong>
                    <small>{option.copy}</small>
                  </div>
                  <b aria-hidden="true">{index === 1 ? "✓" : ""}</b>
                </div>
              ))}
            </div>
            <div className={styles.weekdays} aria-label="Montag, Mittwoch und Freitag ausgewählt">
              {[
                ["M", true], ["D", false], ["M", true], ["D", false], ["F", true], ["S", false], ["S", false],
              ].map(([day, active], index) => (
                <span className={active ? styles.weekdayActive : ""} key={`${day}-${index}`}>{day}</span>
              ))}
            </div>
          </div>
        </section>

        <section className={styles.todaySection}>
          <div className={`site-container ${styles.todayGrid}`}>
            <div className={styles.todayVisual}>
              <div className={styles.todayTop}>
                <span>Deine letzte Gewohnheit</span>
                <strong aria-hidden="true">💧</strong>
                <h3>Ein Glas Wasser</h3>
              </div>
              <div className={styles.todayControls}>
                <span><i /> Heute noch offen</span>
                <b>✓</b>
              </div>
              <div className={styles.smallVersion}>
                <span>Kleine Version</span>
                <strong>Nur ein Glas. Der Rhythmus zählt.</strong>
              </div>
            </div>
            <div className={styles.todayCopy}>
              <span className="eyebrow">Today</span>
              <h2>Eine Oberfläche, die deinen Blick nicht zerstreut.</h2>
              <p>
                Anstatt jede Gewohnheit gleich laut zu machen, stellt Habiter eine relevante Aktion
                in den Mittelpunkt. Alles Weitere bleibt über das App-Wheel nah, aber ruhig.
              </p>
              <ul>
                <li><span>✓</span> Klarer Tagesstatus</li>
                <li><span>✓</span> Ein-Tap-Abschluss mit Undo</li>
                <li><span>✓</span> Kleine Version für schwere Tage</li>
                <li><span>✓</span> Pausierte und archivierte Routinen bleiben erreichbar</li>
              </ul>
            </div>
          </div>
        </section>

        <section className={`site-container ${styles.insightsSection}`}>
          <div className={styles.insightsIntro}>
            <span className="eyebrow">Fortschritt, den du lesen kannst</span>
            <h2>Zahlen werden erst dann wertvoll, wenn sie etwas erklären.</h2>
          </div>
          <div className={styles.insightsGrid}>
            <article className={styles.weekCard}>
              <div className={styles.cardHeader}>
                <div><span>Diese Woche</span><strong>5 von 7 Einheiten</strong></div>
                <b>71%</b>
              </div>
              <div className={styles.weekLine}>
                {[true, true, false, true, true, true, false].map((done, index) => (
                  <span className={done ? styles.weekDone : ""} key={index}>{done ? "✓" : ""}</span>
                ))}
              </div>
              <p>Du liegst im Ziel — ohne dass ein freier Sonntag wie ein Fehler aussieht.</p>
            </article>

            <article className={styles.metricCard}>
              <span>Konsistenz · 30 Tage</span>
              <strong>84%</strong>
              <div className={styles.bars} aria-hidden="true">
                {[42, 58, 46, 72, 68, 86, 92, 78, 88, 96].map((height, index) => (
                  <i key={index} style={{ "--bar-height": `${height}%` } as React.CSSProperties} />
                ))}
              </div>
              <em>+12% gegenüber dem vorherigen Zeitraum</em>
            </article>

            <article className={styles.coachingCard}>
              <span className={styles.coachingIcon} aria-hidden="true">↗</span>
              <div>
                <span>Recovery Support</span>
                <h3>Gestern war ruhig. Dein System ist noch da.</h3>
                <p>Beginne heute mit der kleinsten Version und lass den Rhythmus wieder greifen.</p>
              </div>
            </article>
          </div>
        </section>

        <section className={styles.returnSection}>
          <div className={`site-container ${styles.returnGrid}`}>
            <div className={styles.returnCopy}>
              <span className="eyebrow">Lifecycle statt Löschen</span>
              <h2>Das Leben ändert sich. Deine Geschichte muss nicht verschwinden.</h2>
              <p>
                Urlaubswochen, Krankheit, neue Prioritäten: Habiter behandelt Unterbrechungen als
                normalen Teil eines Systems und schützt die bereits aufgebaute Historie.
              </p>
            </div>
            <div className={styles.returnFlow}>
              <div className={styles.returnHabit}>
                <span aria-hidden="true">📚</span>
                <div><strong>20 Minuten lesen</strong><small>Seit 18 Wochen</small></div>
                <b>•••</b>
              </div>
              <div className={styles.returnStates}>
                <div><span>01</span><strong>Aktiv</strong><small>Teil deines aktuellen Rhythmus</small></div>
                <b>→</b>
                <div><span>02</span><strong>Pausiert</strong><small>Historie bleibt erhalten</small></div>
                <b>→</b>
                <div><span>03</span><strong>Fortgesetzt</strong><small>Zurück, wenn es wieder passt</small></div>
              </div>
            </div>
          </div>
        </section>

        <section className={`site-container ${styles.cta}`}>
          <span className="eyebrow">Bereit für deinen Rhythmus?</span>
          <h2>Öffne Habiter. Sieh den nächsten Schritt. Fang klein an.</h2>
          <p>Die Kern-Experience funktioniert ohne Konto und hält deine Gewohnheitsdaten lokal.</p>
          <div>
            <a className="button button-primary" href="https://get-the.habiter.dev/">
              Smart Download <span aria-hidden="true">↗</span>
            </a>
            <Link className="button button-secondary" href="/privacy/">
              Privacy verstehen <span aria-hidden="true">→</span>
            </Link>
          </div>
        </section>
      </main>
    </SiteShell>
  );
}

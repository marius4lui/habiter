import Link from "next/link";

import styles from "./deep-dive-pages.module.css";
import { SiteShell } from "./site-shell";

const setupSteps = [
  {
    number: "01",
    title: "Ablenkungen auswählen",
    copy: "Habiter schlägt auf Basis der jüngsten Nutzung mögliche Ablenkungen direkt auf dem Gerät vor. Ausgewählt wird nichts ohne dich.",
  },
  {
    number: "02",
    title: "Eine Regel verbinden",
    copy: "Schütze alle heutigen Gewohnheiten oder verknüpfe eine App mit genau dem Ritual, das zuerst passieren soll.",
  },
  {
    number: "03",
    title: "Bewusst freigeben",
    copy: "Sobald die relevante Wiederholung erledigt ist, fällt die Sperre. Dein Verhalten öffnet den Weg — nicht ein willkürlicher Timer.",
  },
] as const;

export function FocusPage() {
  return (
    <SiteShell>
      <main className={styles.main} id="content">
        <section className={styles.focusHero}>
          <div className={`site-container ${styles.heroGrid}`}>
            <div className={styles.heroCopy}>
              <span className={styles.platformBadge}>Android · App Lock</span>
              <span className="eyebrow">Focus Shield</span>
              <h1>
                Weniger Willenskraft.
                <span>Mehr bewusst gesetzte Reibung.</span>
              </h1>
              <p>
                Halte ausgewählte Apps zurück, bis deine heutige Gewohnheit erledigt ist. Nicht als
                Strafe — als ruhiger Vorsprung für das, was dir wichtig ist.
              </p>
              <div className={styles.heroActions}>
                <a className="button button-primary" href="https://get-the.habiter.dev/">
                  Habiter für Android <span aria-hidden="true">↗</span>
                </a>
                <a className="button button-secondary" href="#setup">
                  Setup verstehen <span aria-hidden="true">↓</span>
                </a>
              </div>
              <small className={styles.heroNote}>
                Du entscheidest über Apps, Regeln und Berechtigungen. App Lock lässt sich jederzeit
                ausschalten.
              </small>
            </div>
            <div className={styles.focusDevice} aria-label="Vorschau von Habiter App Lock">
              <div className={styles.deviceTop}>
                <span>Focus Shield</span>
                <b>Aktiv</b>
              </div>
              <div className={styles.shieldCore}>
                <span aria-hidden="true">◇</span>
                <i />
                <i />
                <i />
              </div>
              <h2>Dein Morgen bleibt bei dir.</h2>
              <p>Erledige „10 Minuten bewegen“, um deine ausgewählten Apps freizugeben.</p>
              <div className={styles.focusApps}>
                <div><span>◎</span><strong>Social</strong><small>wartet</small></div>
                <div><span>▷</span><strong>Shorts</strong><small>wartet</small></div>
                <div><span>◇</span><strong>Games</strong><small>wartet</small></div>
              </div>
              <div className={styles.unlockRule}>
                <span><i /> Kerngewohnheit</span>
                <strong>Erledigen → entsperren</strong>
              </div>
            </div>
          </div>
        </section>

        <section className={styles.focusThesis}>
          <div className={`site-container ${styles.thesisInner}`}>
            <span aria-hidden="true">⌁</span>
            <h2>
              Aufmerksamkeit ist leichter zu schützen,
              <strong>bevor die Ablenkung geöffnet ist.</strong>
            </h2>
            <p>
              Focus Shield verlagert die Entscheidung aus dem schwächsten Moment in einen ruhigen
              Setup-Moment davor.
            </p>
          </div>
        </section>

        <section className={`site-container ${styles.setupSection}`} id="setup">
          <div className={styles.sectionIntro}>
            <span className="eyebrow">Geführt statt technisch</span>
            <h2>Ein Setup, das jede Entscheidung erklärt.</h2>
            <p>
              Der geführte Flow trennt Erkennung, Auswahl, Regel und Berechtigungen. So ist jederzeit
              klar, was Habiter sieht und warum es gebraucht wird.
            </p>
          </div>
          <div className={styles.setupGrid}>
            {setupSteps.map((step) => (
              <article key={step.number}>
                <span>{step.number}</span>
                <h3>{step.title}</h3>
                <p>{step.copy}</p>
              </article>
            ))}
          </div>
        </section>

        <section className={styles.ruleSection}>
          <div className={`site-container ${styles.ruleGrid}`}>
            <div className={styles.ruleBuilder}>
              <div className={styles.ruleHeader}>
                <div><span>Neue App-Block-Regel</span><strong>Was soll zuerst passieren?</strong></div>
                <b>2 / 3</b>
              </div>
              <div className={styles.ruleChoice}>
                <div>
                  <span aria-hidden="true">✓</span>
                  <div><strong>Alle heutigen Gewohnheiten</strong><small>Freigabe, wenn dein Daily Flow komplett ist</small></div>
                  <b />
                </div>
                <div className={styles.ruleSelected}>
                  <span aria-hidden="true">🌿</span>
                  <div><strong>Eine bestimmte Gewohnheit</strong><small>10 Minuten bewegen</small></div>
                  <b>✓</b>
                </div>
              </div>
              <div className={styles.rulePreview}>
                <span>Regelvorschau</span>
                <strong>Social wartet auf „10 Minuten bewegen“</strong>
                <small>Nur wenn die Gewohnheit heute geplant und noch offen ist.</small>
              </div>
            </div>
            <div className={styles.ruleCopy}>
              <span className="eyebrow">Regeln, die deinen Rhythmus verstehen</span>
              <h2>Nicht jeder Tag muss gleich aussehen.</h2>
              <p>
                Habiter berücksichtigt tägliche, wochentagsbasierte und flexible Wochenziele. Ist
                eine Gewohnheit heute nicht fällig, erzeugt sie auch keine künstliche Sperre.
              </p>
              <ul>
                <li><span>✓</span> Tagesplan bleibt maßgeblich</li>
                <li><span>✓</span> Abschluss hebt die passende Sperre auf</li>
                <li><span>✓</span> Pausierte Gewohnheiten blockieren nicht</li>
                <li><span>✓</span> Regeln können einzeln deaktiviert werden</li>
              </ul>
            </div>
          </div>
        </section>

        <section className={`site-container ${styles.permissionsSection}`}>
          <div className={styles.permissionsCopy}>
            <span className="eyebrow">Explizite Android-Berechtigungen</span>
            <h2>Kein stiller Zugriff. Kein Versteckspiel.</h2>
            <p>
              App Lock erklärt beide notwendigen Systemzugriffe vor dem Öffnen der Android-Einstellung.
              Du kannst sie dort jederzeit wieder entziehen.
            </p>
          </div>
          <div className={styles.permissionConsole}>
            <div className={styles.permissionStatus}>
              <span aria-hidden="true">◇</span>
              <div><small>App Lock Status</small><strong>Berechtigungen bereit</strong></div>
              <b>AKTIV</b>
            </div>
            <div className={styles.permissionRows}>
              <div>
                <span>01</span>
                <div><strong>Nutzungszugriff</strong><small>Erkennt, welche App gerade im Vordergrund ist.</small></div>
                <b>✓</b>
              </div>
              <div>
                <span>02</span>
                <div><strong>Über anderen Apps anzeigen</strong><small>Zeigt den Habiter-Sperrbildschirm für eine aktive Regel.</small></div>
                <b>✓</b>
              </div>
            </div>
            <div className={styles.failSafe}>
              <span aria-hidden="true">✓</span>
              <div>
                <strong>Fail-safe statt Festhalten</strong>
                <small>Fehlt ein erforderlicher Zugriff, schaltet Habiter App Lock sicher aus.</small>
              </div>
            </div>
          </div>
        </section>

        <section className={styles.focusCta}>
          <div className={`site-container ${styles.focusCtaInner}`}>
            <span className="eyebrow">Erst du. Dann die Ablenkung.</span>
            <h2>Gib deiner wichtigsten Wiederholung einen Vorsprung.</h2>
            <p>Focus Shield ist die Android-App-Lock-Experience von Habiter.</p>
            <div>
              <a className="button button-primary" href="https://get-the.habiter.dev/">
                Smart Download <span aria-hidden="true">↗</span>
              </a>
              <Link className="button button-secondary" href="/privacy/">
                Privacy &amp; Berechtigungen <span aria-hidden="true">→</span>
              </Link>
            </div>
          </div>
        </section>
      </main>
    </SiteShell>
  );
}

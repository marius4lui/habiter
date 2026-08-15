import { SiteInteractions } from "./site-interactions";
import { BrandLogo } from "./brand-logo";
import { ThemeToggle } from "./theme-toggle";

export function LandingPage() {
  return (
<div>
  <SiteInteractions />
  <canvas id="ambientCanvas" aria-hidden="true" />
  <div className="cursor-glow" id="cursorGlow" aria-hidden="true" />
  <div className="noise" aria-hidden="true" />
  {/* NAV */}
  <div className="nav-wrap">
    <nav className="nav" id="nav" aria-label="Hauptnavigation">
      <a href="#top" className="brand">
        <BrandLogo />
        <span>
          Habiter
        </span>
      </a>
      <div className="nav-links">
        <a href="#why">
          Warum Habiter
        </a>
        <a href="#experience">
          Experience
        </a>
        <a href="#focus">
          Focus
        </a>
        <a href="#privacy">
          Privacy
        </a>
      </div>
      <div className="nav-cta">
        <ThemeToggle />
        <a href="#download" className="mini-cta">
          Beta testen
        </a>
      </div>
    </nav>
  </div>
  <main id="top">
    {/* HERO */}
    <section className="hero">
      <div className="container hero-content">
        <div className="beta-pill" data-reveal>
          Habiter Beta · Android
        </div>
        <h1 data-reveal>
          <span className="quiet">
            Nicht mehr
          </span>
          anfangen.
          <br />
          <span className="alive">
            Dranbleiben.
          </span>
        </h1>
        <p className="hero-sub" data-reveal>
          Habiter ist kein weiterer Habit Tracker,
          der dich mit roten Kreuzen daran erinnert,
          was du nicht geschafft hast.
          Habiter macht Fortschritt sichtbar,
          Fokus fühlbar und kleine Wiederholungen
          zu etwas, zu dem du zurückkommen willst.
        </p>
        <div className="hero-actions" data-reveal>
          <a className="button-primary" href="#download">
            Habiter testen
            <span aria-hidden="true">
              →
            </span>
          </a>
          <a className="button-secondary" href="#experience">
            Die Experience ansehen
          </a>
        </div>
        <div className="hero-note" data-reveal>
          Kostenlos in der Beta · lokal gedacht · kein kompliziertes Setup
        </div>
        {/* PRODUCT STAGE */}
        <div className="product-stage" id="productStage">
          <div className="stage-halo" aria-hidden="true" />
          <div className="float-card one" data-float>
            <small>
              Momentum
            </small>
            <strong>
              12 Tage Rhythmus
            </strong>
          </div>
          <div className="float-card two" data-float>
            <small>
              Heute
            </small>
            <strong>
              3 kleine Siege
            </strong>
          </div>
          <div className="float-card three" data-float>
            <small>
              Konsistenz
            </small>
            <strong>
              88% diesen Monat
            </strong>
          </div>
          <div className="float-card four" data-float>
            <small>
              Focus Shield
            </small>
            <div className="mini-lock">
              <span className="lock-dot" />
              <strong>
                Ablenkung blockiert
              </strong>
            </div>
          </div>
          <div className="phone" id="heroPhone">
            <div className="phone-screen">
              <div className="dynamic-island" aria-hidden="true" />
              <div className="screen-glow" aria-hidden="true" />
              <div className="app-ui">
                <div className="app-header">
                  <div>
                    <div className="app-date">
                      Samstag · 15. August
                    </div>
                    <div className="app-greeting">
                      Guten Morgen.
                    </div>
                  </div>
                  <div className="app-avatar">
                    🌱
                  </div>
                </div>
                <div className="week-row">
                  <div className="week-day">
                    M
                  </div>
                  <div className="week-day">
                    D
                  </div>
                  <div className="week-day">
                    M
                  </div>
                  <div className="week-day">
                    D
                  </div>
                  <div className="week-day">
                    F
                  </div>
                  <div className="week-day active">
                    S
                  </div>
                  <div className="week-day">
                    S
                  </div>
                </div>
                <div className="daily-flow">
                  <div className="daily-label">
                    Dein Daily Flow
                  </div>
                  <div className="daily-title">
                    Du baust gerade deine stärkste Version auf.
                  </div>
                  <div className="progress-ring" id="heroProgress">
                    <strong id="heroPercent">
                      67%
                    </strong>
                  </div>
                  <div className="flow-message">
                    Kleine Wiederholungen.
                    <br />
                    Echtes Momentum.
                  </div>
                </div>
                <div className="habit-demo-list">
                  <div className="demo-habit done" data-demo-habit>
                    <div className="habit-emoji">
                      💧
                    </div>
                    <div>
                      <strong>
                        Wasser trinken
                      </strong>
                      <span>
                        Health · 12 Tage
                      </span>
                    </div>
                    <div className="demo-check">
                      ✓
                    </div>
                  </div>
                  <div className="demo-habit done" data-demo-habit>
                    <div className="habit-emoji">
                      🌿
                    </div>
                    <div>
                      <strong>
                        10 Minuten bewegen
                      </strong>
                      <span>
                        Fitness · 9 Tage
                      </span>
                    </div>
                    <div className="demo-check">
                      ✓
                    </div>
                  </div>
                  <div className="demo-habit" data-demo-habit>
                    <div className="habit-emoji">
                      📚
                    </div>
                    <div>
                      <strong>
                        Lesen
                      </strong>
                      <span>
                        Learning · kleine Version
                      </span>
                    </div>
                    <div className="demo-check">
                      ✓
                    </div>
                  </div>
                </div>
                <div className="app-bottom">
                  <div className="selected">
                    ◉
                  </div>
                  <div>
                    ◌
                  </div>
                  <div>
                    ⚙
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div className="scroll-hint">
          Scroll
        </div>
      </div>
    </section>
    {/* MARQUEE */}
    <section className="signal-bar" aria-label="Habiter Vorteile">
      <div className="marquee">
        <div className="marquee-group">
          <div className="marquee-item">
            Organisches Design
          </div>
          <div className="marquee-item">
            AI Insights
          </div>
          <div className="marquee-item">
            App Lock
          </div>
          <div className="marquee-item">
            Haptisches Feedback
          </div>
          <div className="marquee-item">
            Lokale Daten
          </div>
          <div className="marquee-item">
            Analytics
          </div>
          <div className="marquee-item">
            Dark Mode
          </div>
        </div>
        <div className="marquee-group" aria-hidden="true">
          <div className="marquee-item">
            Organisches Design
          </div>
          <div className="marquee-item">
            AI Insights
          </div>
          <div className="marquee-item">
            App Lock
          </div>
          <div className="marquee-item">
            Haptisches Feedback
          </div>
          <div className="marquee-item">
            Lokale Daten
          </div>
          <div className="marquee-item">
            Analytics
          </div>
          <div className="marquee-item">
            Dark Mode
          </div>
        </div>
      </div>
    </section>
    {/* PHILOSOPHY */}
    <section className="section philosophy" id="why">
      <div className="container philosophy-grid">
        <div className="philosophy-sticky">
          <div className="section-kicker" data-reveal>
            Die Idee
          </div>
          <h2 className="section-title" data-reveal>
            Gewohnheiten brauchen
            <span className="muted">
              keine Schuldgefühle.
            </span>
          </h2>
          <p className="section-copy" data-reveal>
            Die meisten Tracker behandeln Verhalten
            wie eine Checkliste.
            Habiter behandelt es wie etwas Lebendiges:
            Identität, Energie, Rhythmus und Rückkehr.
          </p>
        </div>
        <div className="philosophy-side">
          <article className="principle active" data-principle data-symbol="✓">
            <div className="principle-number">
              01
            </div>
            <div>
              <h3>
                Kleine Siege müssen sich groß anfühlen.
              </h3>
              <p>
                Completion ist nicht nur ein Häkchen.
                Sie ist sichtbare Bestätigung:
                „Ich bin jemand, der das tut.“
              </p>
              <div className="principle-word">
                Self efficacy
              </div>
            </div>
          </article>
          <article className="principle principle-recovery" data-principle data-symbol="↗">
            <div className="principle-number">
              02
            </div>
            <div>
              <h3>
                Ein schlechter Tag zerstört kein gutes System.
              </h3>
              <p>
                Kein aggressives Rot.
                Keine zerstörte Serie,
                die dich dazu bringt komplett aufzuhören.
                Habiter optimiert auf Rückkehr.
              </p>
              <div className="principle-word">
                Compassionate consistency
              </div>
              <div className="recovery-visual" aria-hidden="true">
                <span className="recovery-day complete" />
                <span className="recovery-day complete" />
                <span className="recovery-day pause" />
                <span className="recovery-day return" />
                <span className="recovery-day complete" />
                <span className="recovery-day complete" />
                <strong>Rückkehr &gt; Perfektion</strong>
              </div>
            </div>
          </article>
          <article className="principle" data-principle data-symbol="→">
            <div className="principle-number">
              03
            </div>
            <div>
              <h3>
                Motivation wird leichter,
                wenn Reibung verschwindet.
              </h3>
              <p>
                Öffnen. Verstehen. Handeln.
                Kein Dashboard voller Zahlen.
                Kein zehnstufiger Workflow.
              </p>
              <div className="principle-word">
                Zero-friction ritual
              </div>
            </div>
          </article>
          <article className="principle" data-principle data-symbol="◌">
            <div className="principle-number">
              04
            </div>
            <div>
              <h3>
                Fokus bedeutet manchmal:
                Dinge nicht öffnen zu können.
              </h3>
              <p>
                Mit Focus Shield können ablenkende Apps warten,
                bis dein wichtigstes Ritual abgeschlossen ist.
              </p>
              <div className="principle-word">
                Intentional friction
              </div>
            </div>
          </article>
        </div>
      </div>
    </section>
    {/* EXPERIENCE */}
    <section className="story" id="experience">
      <div className="container">
        <div className="story-intro">
          <div className="section-kicker" data-reveal>
            Die Experience
          </div>
          <h2 className="section-title" data-reveal>
            Eine App,
            die sich deinem Leben anpasst.
            <span className="muted">
              Nicht andersherum.
            </span>
          </h2>
          <p className="section-copy" data-reveal>
            Habiter konzentriert jede Ansicht
            auf eine einzige Frage:
            Was hilft dir jetzt wirklich weiter?
          </p>
        </div>
        <div className="story-grid">
          <div className="story-visual-wrap">
            <div className="story-sticky">
              <div className="story-phone">
                <div className="story-screen">
                  {/* SCENE 0 */}
                  <div className="screen-scene active" data-scene={0}>
                    <div className="scene-label">
                      Heute
                    </div>
                    <div className="scene-title">
                      Was heute wirklich zählt.
                    </div>
                    <div className="scene-habit-list">
                      <div className="scene-habit">
                        <div>
                          💧
                        </div>
                        <div>
                          <strong>
                            Wasser trinken
                          </strong>
                          <span>
                            Kleine Version: 1 Glas
                          </span>
                        </div>
                      </div>
                      <div className="scene-habit">
                        <div>
                          🌿
                        </div>
                        <div>
                          <strong>
                            Bewegen
                          </strong>
                          <span>
                            Heute reichen 10 Minuten
                          </span>
                        </div>
                      </div>
                      <div className="scene-habit">
                        <div>
                          📚
                        </div>
                        <div>
                          <strong>
                            Lesen
                          </strong>
                          <span>
                            Zwei Seiten halten die Identität lebendig
                          </span>
                        </div>
                      </div>
                    </div>
                    <div className="insight-card">
                      <div className="scene-label">
                        Sanfter Impuls
                      </div>
                      <h4>
                        Du bist bereits in Bewegung.
                      </h4>
                      <p>
                        Die nächste kleine Wiederholung reicht.
                        Du musst heute nichts beweisen.
                      </p>
                    </div>
                  </div>
                  {/* SCENE 1 */}
                  <div className="screen-scene" data-scene={1}>
                    <div className="scene-label">
                      Focus Shield
                    </div>
                    <div className="scene-title">
                      Erst du.
                      Dann die Ablenkung.
                    </div>
                    <div className="focus-orb">
                      <span>
                        🛡️
                      </span>
                    </div>
                    <div className="locked-apps">
                      <div className="locked-app">
                        Social Media
                        <span className="lock-state">
                          geschützt
                        </span>
                      </div>
                      <div className="locked-app">
                        Short Video
                        <span className="lock-state">
                          geschützt
                        </span>
                      </div>
                      <div className="locked-app">
                        Games
                        <span className="lock-state">
                          geschützt
                        </span>
                      </div>
                    </div>
                  </div>
                  {/* SCENE 2 */}
                  <div className="screen-scene" data-scene={2}>
                    <div className="scene-label">
                      AI Insight
                    </div>
                    <div className="scene-title">
                      Weniger Daten.
                      Mehr Bedeutung.
                    </div>
                    <div className="insight-card">
                      <div className="insight-icon">
                        ✦
                      </div>
                      <h4>
                        Schütze deine Morgenroutine.
                      </h4>
                      <p>
                        Deine stärksten Tage beginnen häufig
                        mit Wasser und Bewegung.
                        Versuche morgen nur diese beiden Gewohnheiten
                        vor 09:00 Uhr zu erledigen.
                      </p>
                      <div className="confidence">
                        <span>
                          Musterstärke
                        </span>
                        <div className="confidence-line">
                          <span />
                        </div>
                      </div>
                    </div>
                    <div className="insight-card">
                      <div className="scene-label">
                        Nicht perfekt
                      </div>
                      <h4>
                        Gestern war ruhig.
                        Dein Trend nicht.
                      </h4>
                      <p>
                        Ein einzelner Tag definiert nicht,
                        wer du wirst.
                      </p>
                    </div>
                  </div>
                  {/* SCENE 3 */}
                  <div className="screen-scene" data-scene={3}>
                    <div className="scene-label">
                      Wachstum
                    </div>
                    <div className="scene-title">
                      Sieh Muster.
                      Nicht Fehler.
                    </div>
                    <div className="chart-card">
                      <div className="chart-header">
                        <strong>
                          Konsistenz
                        </strong>
                        <span>
                          +14%
                        </span>
                      </div>
                      <div className="line-chart">
                        <svg viewBox="0 0 300 150" preserveAspectRatio="none">
                          <defs>
                            <linearGradient id="lineGradient" x1={0} y1={0} x2={1} y2={0}>
                              <stop offset="0%" stopColor="#90b280" />
                              <stop offset="100%" stopColor="#4ecdc4" />
                            </linearGradient>
                            <linearGradient id="fillGradient" x1={0} y1={0} x2={0} y2={1}>
                              <stop offset="0%" stopColor="#90b280" stopOpacity=".18" />
                              <stop offset="100%" stopColor="#90b280" stopOpacity={0} />
                            </linearGradient>
                          </defs>
                          <path d="M0,122 C28,112 37,90 66,95 C96,100 102,68 133,78 C162,87 173,47 202,56 C232,65 248,31 300,27 L300,150 L0,150 Z" fill="url(#fillGradient)" />
                          <path d="M0,122 C28,112 37,90 66,95 C96,100 102,68 133,78 C162,87 173,47 202,56 C232,65 248,31 300,27" fill="none" stroke="url(#lineGradient)" strokeWidth={3} strokeLinecap="round" />
                        </svg>
                      </div>
                    </div>
                    <div className="stat-row">
                      <div className="tiny-stat">
                        <strong>
                          88%
                        </strong>
                        <span>
                          Konsistenz
                        </span>
                      </div>
                      <div className="tiny-stat">
                        <strong>
                          12d
                        </strong>
                        <span>
                          Rhythmus
                        </span>
                      </div>
                      <div className="tiny-stat">
                        <strong>
                          31
                        </strong>
                        <span>
                          Siege
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div className="story-steps">
            <article className="story-step active" data-step={0}>
              <div className="story-step-number">
                01 · Ritual
              </div>
              <h3>
                Öffnen und sofort wissen:
                Das ist heute wichtig.
              </h3>
              <p>
                Keine Informationswand.
                Habiter zeigt deine relevanten Rituale,
                ihre kleinste machbare Version
                und einen ruhigen Weg nach vorne.
              </p>
            </article>
            <article className="story-step" data-step={1}>
              <div className="story-step-number">
                02 · Focus Shield
              </div>
              <h3>
                Gib deiner Aufmerksamkeit
                einen Vorsprung.
              </h3>
              <p>
                Bestimmte Apps dürfen warten,
                bis deine wichtigsten Gewohnheiten erledigt sind.
                Nicht als Strafe.
                Als bewusst gesetzte Reibung.
              </p>
            </article>
            <article className="story-step" data-step={2}>
              <div className="story-step-number">
                03 · Insight
              </div>
              <h3>
                Zahlen sagen was passiert.
                Habiter sagt dir warum.
              </h3>
              <p>
                AI Insights übersetzen dein Verhalten
                in verständliche Hinweise.
                Weniger Diagramme interpretieren.
                Mehr gute Entscheidungen treffen.
              </p>
            </article>
            <article className="story-step" data-step={3}>
              <div className="story-step-number">
                04 · Growth
              </div>
              <h3>
                Fortschritt,
                der sich wie Wachstum anfühlt.
              </h3>
              <p>
                Trends, Streaks und Completion Rates
                bleiben sichtbar —
                aber nie wichtiger als das Verhalten,
                das sie erzeugt.
              </p>
            </article>
          </div>
        </div>
      </div>
    </section>
    {/* LIVING PROGRESS */}
    <section className="growth-section">
      <div className="container">
        <div className="growth-card" data-reveal>
          <canvas id="growthCanvas" aria-hidden="true" />
          <div className="growth-copy">
            <div className="section-kicker">
              Living progress
            </div>
            <h2 className="section-title">
              Dein Fortschritt soll
              <span className="muted">
                leben.
              </span>
            </h2>
            <p className="section-copy">
              Streaks, Konsistenz und abgeschlossene Rituale
              formen eine organische Progress-Welt.
              Nicht als Punktestand.
              Als sichtbare Erinnerung daran,
              was du bereits aufgebaut hast.
            </p>
          </div>
          <div className="growth-caption">
            <strong>
              Dein digitales Habitat
            </strong>
            Jede Linie steht für Wiederholung.
            Jeder neue Zweig für Stabilität.
            Pausen zerstören nichts —
            Wachstum setzt sich fort.
          </div>
        </div>
      </div>
    </section>
    {/* FOCUS + PRIVACY */}
    <section className="focus-section" id="focus">
      <div className="container focus-grid">
        <article className="feature-large teal" data-reveal>
          <div className="feature-tag">
            Focus Shield
          </div>
          <h3>
            Manchmal ist Fokus
            eine geschlossene Tür.
          </h3>
          <p>
            Entscheide bewusst,
            welche Apps erst dann verfügbar werden,
            wenn deine Kerngewohnheiten erledigt sind.
          </p>
          <div className="feature-visual">
            <div className="shield-ui">
              <div className="shield-rings" aria-hidden="true" />
              <div className="shield-center">
                <svg viewBox="0 0 48 48" aria-hidden="true"><path d="M24 5 39 11v11c0 10-6.4 17.5-15 21-8.6-3.5-15-11-15-21V11l15-6Z" /><path d="M24 11v25c5.5-3 9-8 9-14.5v-6.3L24 11Z" /></svg>
              </div>
              <div className="shield-apps">
                <div className="shield-chip a"><span>◎</span><strong>Social</strong><em>wartet</em></div>
                <div className="shield-chip b"><span>◇</span><strong>Games</strong><em>wartet</em></div>
              </div>
              <div className="shield-unlock">
                <span className="unlock-check">✓</span>
                <div><small>Kerngewohnheit</small><strong>Erledigen → entsperren</strong></div>
              </div>
            </div>
          </div>
        </article>
        <article className="feature-large sage" id="privacy" data-reveal>
          <div className="feature-tag">
            Privacy first
          </div>
          <h3>
            Deine Gewohnheiten
            gehören dir.
          </h3>
          <p>
            Habiter wurde mit lokaler Datenhaltung
            und einer möglichst privaten Nutzung
            im Zentrum gedacht.
          </p>
          <div className="feature-visual">
            <div className="privacy-visual">
              <div className="privacy-console">
                <div className="privacy-head">
                  <div className="privacy-seal">✓</div>
                  <div><small>Private by design</small><strong>Nur auf deinem Gerät</strong></div>
                  <span className="privacy-status">GESCHÜTZT</span>
                </div>
                <div className="privacy-flow">
                  <div className="privacy-node"><span>01</span><strong>Gewohnheiten</strong><small>lokal gespeichert</small></div>
                  <div className="privacy-connector"><span /></div>
                  <div className="privacy-node"><span>02</span><strong>Fortschritt</strong><small>bleibt bei dir</small></div>
                </div>
                <div className="privacy-foot">
                  <span>Kein Tracking-Profil</span><span>Kein Datenverkauf</span>
                </div>
              </div>
            </div>
          </div>
        </article>
      </div>
    </section>
    {/* STATEMENT */}
    <section className="statement">
      <div className="container">
        <div className="statement-text" data-reveal>
          Nicht die perfekte Woche
          verändert dein Leben.
          <span className="low">
            Sondern die Fähigkeit,
          </span>
          morgen wiederzukommen.
        </div>
        <div className="statement-small" data-reveal>
          Habiter · build better habits, one day at a time.
        </div>
      </div>
    </section>
    {/* DOWNLOAD */}
    <section className="download" id="download">
      <div className="container">
        <div className="download-card" data-reveal>
          <BrandLogo large />
          <h2>
            Werde jemand,
            der zurückkommt.
          </h2>
          <p>
            Teste Habiter und baue Gewohnheiten
            mit weniger Druck,
            mehr Fokus
            und einer Experience,
            die du tatsächlich jeden Tag öffnen willst.
          </p>
          <div className="download-actions">
            <a className="button-primary" href="https://get.habiter.dev/download">
              Beta-Tester werden
              <span>
                →
              </span>
            </a>
            <a className="button-secondary" href="#top">
              Nochmal ansehen
            </a>
          </div>
          <div className="android-pill">
            Aktuell als Android Beta verfügbar
          </div>
        </div>
      </div>
    </section>
  </main>
  {/* FOOTER */}
  <footer>
    <div className="container footer-grid">
      <div className="footer-brand">
        <BrandLogo />
        Habiter
      </div>
      <div className="footer-links">
        <a href="#privacy">
          Datenschutz
        </a>
        <a href="#focus">
          Focus
        </a>
        <a href="#experience">
          Experience
        </a>
        <a href="#top">
          Nach oben
        </a>
      </div>
    </div>
  </footer>
</div>

  );
}

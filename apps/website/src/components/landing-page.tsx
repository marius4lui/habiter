import Link from "next/link";

import { SiteShell } from "./site-shell";

export function LandingPage() {
  return (
    <SiteShell>
      <main className="foundation-main" id="content">
        <section className="site-container foundation-hero">
          <div>
            <span className="eyebrow">Aktueller Stable-Release</span>
            <h1>Gewohnheiten, die sich nach dir richten.</h1>
            <p>
              Habiter bringt deine wichtigste Wiederholung nach vorn, schützt deinen Fokus und
              zeigt Fortschritt ohne Druck.
            </p>
            <div className="foundation-actions">
              <a className="button button-primary" href="https://get-the.habiter.dev/">
                Habiter herunterladen <span aria-hidden="true">↗</span>
              </a>
              <Link className="button button-secondary" href="/product/">
                Produkt ansehen <span aria-hidden="true">→</span>
              </Link>
            </div>
          </div>
          <div className="foundation-preview" aria-label="Vorschau der Habiter App">
            <div className="foundation-preview-inner">
              <small>Deine letzte Gewohnheit</small>
              <span aria-hidden="true">🌿</span>
              <strong>10 Minuten bewegen</strong>
              <em>● Heute noch offen</em>
            </div>
          </div>
        </section>
      </main>
    </SiteShell>
  );
}

import Link from "next/link";

import { BrandLogo } from "@/components/brand-logo";
import { SiteShell } from "@/components/site-shell";

import styles from "./not-found.module.css";

export default function NotFound() {
  return (
    <SiteShell>
      <main className={styles.main} id="content">
        <div className={styles.glow} aria-hidden="true" />
        <BrandLogo large />
        <span>404 · Diese Seite macht gerade Pause</span>
        <h1>Der nächste kleine Schritt liegt woanders.</h1>
        <p>Zurück zur Habiter Experience — deine Route ist nur einen Klick entfernt.</p>
        <div>
          <Link className="button button-primary" href="/">
            Zur Startseite <span aria-hidden="true">→</span>
          </Link>
          <Link className="button button-secondary" href="/product/">
            Produkt ansehen
          </Link>
        </div>
      </main>
    </SiteShell>
  );
}

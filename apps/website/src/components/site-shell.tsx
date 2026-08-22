import Link from "next/link";
import type { ReactNode } from "react";

import { BrandLogo } from "./brand-logo";
import styles from "./site-shell.module.css";
import { ThemeToggle } from "./theme-toggle";

const navigation = [
  { href: "/product/", label: "Produkt" },
  { href: "/focus/", label: "Focus" },
  { href: "/privacy/", label: "Privacy" },
] as const;

function NavigationLinks({ mobile = false }: { mobile?: boolean }) {
  return (
    <div className={mobile ? styles.mobileLinks : styles.links}>
      {navigation.map((item) => (
        <Link href={item.href} key={item.href}>
          {item.label}
        </Link>
      ))}
      <a href="https://docs.habiter.dev/">Docs</a>
    </div>
  );
}

export function SiteHeader() {
  return (
    <header className={styles.header}>
      <div className={`site-container ${styles.headerInner}`}>
        <Link className={styles.brand} href="/" aria-label="Habiter Startseite">
          <BrandLogo />
          <span>Habiter</span>
        </Link>

        <nav className={styles.desktopNav} aria-label="Hauptnavigation">
          <NavigationLinks />
        </nav>

        <div className={styles.actions}>
          <ThemeToggle />
          <a className="button button-primary button-compact" href="https://get-the.habiter.dev/">
            Download
          </a>
          <details className={styles.menu}>
            <summary aria-label="Navigation öffnen">
              <span />
              <span />
            </summary>
            <div className={styles.menuPanel}>
              <NavigationLinks mobile />
              <a className="button button-primary" href="https://get-the.habiter.dev/">
                Habiter laden
              </a>
            </div>
          </details>
        </div>
      </div>
    </header>
  );
}

export function SiteFooter() {
  return (
    <footer className={styles.footer}>
      <div className={`site-container ${styles.footerGrid}`}>
        <div className={styles.footerBrand}>
          <Link className={styles.brand} href="/">
            <BrandLogo />
            <span>Habiter</span>
          </Link>
          <p>Weniger Druck. Mehr Rhythmus. Jeden Tag ein kleines Stück.</p>
        </div>
        <div className={styles.footerNav}>
          <div>
            <strong>Produkt</strong>
            <Link href="/product/">Experience</Link>
            <Link href="/focus/">Focus Shield</Link>
            <Link href="/privacy/">Privacy</Link>
          </div>
          <div>
            <strong>Mehr</strong>
            <a href="https://docs.habiter.dev/">Dokumentation</a>
            <a href="https://get-the.habiter.dev/">Download</a>
            <a href="https://github.com/marius4lui/habiter">GitHub</a>
          </div>
        </div>
      </div>
      <div className={`site-container ${styles.legal}`}>
        <span>© {new Date().getFullYear()} Habiter</span>
        <span>Lokal gedacht. Mit Sorgfalt gebaut.</span>
      </div>
    </footer>
  );
}

export function SiteShell({ children }: { children: ReactNode }) {
  return (
    <div className={styles.shell}>
      <SiteHeader />
      {children}
      <SiteFooter />
    </div>
  );
}

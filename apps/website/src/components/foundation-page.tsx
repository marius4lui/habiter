import { SiteShell } from "./site-shell";

type FoundationPageProps = {
  eyebrow: string;
  title: string;
  copy: string;
};

export function FoundationPage({ eyebrow, title, copy }: FoundationPageProps) {
  return (
    <SiteShell>
      <main className="foundation-main" id="content">
        <section className="site-container foundation-detail">
          <span className="eyebrow">{eyebrow}</span>
          <h1>{title}</h1>
          <p>{copy}</p>
          <a className="button button-primary" href="https://get-the.habiter.dev/">
            Habiter herunterladen <span aria-hidden="true">↗</span>
          </a>
        </section>
      </main>
    </SiteShell>
  );
}

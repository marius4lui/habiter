import { Footer, Header } from "@/components";
import { getDictionary, isLocale } from "@/lib/dictionaries";
import Link from "next/link";
import { notFound } from "next/navigation";

export default async function LocaleHomePage({ params }: { params: Promise<{ locale: string }> }) {
  const { locale: candidate } = await params;
  if (!isLocale(candidate)) notFound();
  const locale = candidate;
  const t = getDictionary(locale);
  return <>
    <div className="shell"><Header locale={locale} /></div>
    <main>
      <section className="hero shell">
        <div>
          <p className="eyebrow">{t.hero.eyebrow}</p>
          <h1>{t.hero.title}</h1>
          <p className="lede">{t.hero.body}</p>
          <Link className="primary-cta" href={`/${locale}/live`}>{t.hero.cta}</Link>
          <small>{t.hero.note}</small>
        </div>
        <div className="habit-preview" aria-label={locale === "de" ? "Beispiel für heutige Routinen" : "Example of today's routines"}>
          <span className="preview-date">14 AUG</span>
          <h2>{locale === "de" ? "Heute" : "Today"}</h2>
          <div className="preview-progress"><span /></div>
          <p>2 / 3</p>
          <article><b>✓</b><span>{locale === "de" ? "Wasser trinken" : "Drink water"}</span></article>
          <article><b>✓</b><span>{locale === "de" ? "Zehn Minuten lesen" : "Read for ten minutes"}</span></article>
          <article><b>→</b><span>{locale === "de" ? "Abendspaziergang" : "Evening walk"}</span></article>
        </div>
      </section>
      <section className="feature-section shell" id="features">
        {t.features.map(([title, body]) => <article key={title}><h2>{title}</h2><p>{body}</p></article>)}
      </section>
      <section className="privacy-story shell"><p className="eyebrow">Local first</p><h2>{t.privacy}</h2><p>{t.platform}</p></section>
    </main>
    <div className="shell"><Footer locale={locale} /></div>
  </>;
}

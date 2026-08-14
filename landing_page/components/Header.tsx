import Image from "next/image";
import Link from "next/link";
import type { Locale } from "@/lib/dictionaries";
import { getDictionary } from "@/lib/dictionaries";

export function Header({ locale }: { locale: Locale; showFeatures?: boolean; showDownload?: boolean }) {
  const t = getDictionary(locale).nav;
  const other = locale === "de" ? "en" : "de";
  return <header className="site-header">
    <Link href={`/${locale}`} className="brand"><Image src="/icon.png" alt="" width={36} height={36} />Habiter</Link>
    <nav aria-label="Primary navigation">
      <Link href={`/${locale}#features`}>{t.features}</Link>
      <Link href={`/${locale}/live`}>{t.demo}</Link>
      <Link href={`/${other}`} hrefLang={other}>{t.language}</Link>
    </nav>
  </header>;
}

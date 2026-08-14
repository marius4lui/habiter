import { Footer, Header } from "@/components";
import { isLocale } from "@/lib/dictionaries";
import { notFound } from "next/navigation";
import { DemoIsland } from "./DemoIsland";

export default async function LiveDemoPage({ params }: { params: Promise<{ locale: string }> }) {
  const { locale } = await params;
  if (!isLocale(locale)) notFound();
  return <div className="shell"><Header locale={locale} /><main className="demoPage">
    <p className="eyebrow">Interactive local demo</p>
    <h1>{locale === "de" ? "Ein Habit-Flow, direkt im Browser" : "A habit flow, right in your browser"}</h1>
    <p>{locale === "de" ? "Diese Demo speichert nichts und bildet nicht alle nativen Funktionen ab." : "This demo stores nothing and does not represent every native feature."}</p>
    <DemoIsland locale={locale} />
  </main><Footer locale={locale} /></div>;
}

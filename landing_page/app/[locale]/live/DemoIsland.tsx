"use client";

import { useState } from "react";
import type { Locale } from "@/lib/dictionaries";
import styles from "./demo-island.module.css";

const habits = { de: ["Wasser trinken", "Zehn Minuten lesen", "Spazieren"], en: ["Drink water", "Read for ten minutes", "Take a walk"] } as const;

export function DemoIsland({ locale }: { locale: Locale }) {
  const [done, setDone] = useState<Set<number>>(() => new Set());
  const toggle = (index: number) => setDone((current) => {
    const next = new Set(current);
    if (next.has(index)) next.delete(index); else next.add(index);
    return next;
  });
  return <section className={styles.card} aria-live="polite">
    <div><b>{done.size} / {habits[locale].length}</b><span>{locale === "de" ? " heute erledigt" : " completed today"}</span></div>
    <progress max={habits[locale].length} value={done.size} />
    {habits[locale].map((habit, index) => <button key={habit} aria-pressed={done.has(index)} onClick={() => toggle(index)}>
      <span>{done.has(index) ? "✓" : "○"}</span>{habit}
    </button>)}
    <button className={styles.reset} onClick={() => setDone(new Set())}>{locale === "de" ? "Zurücksetzen" : "Reset"}</button>
  </section>;
}

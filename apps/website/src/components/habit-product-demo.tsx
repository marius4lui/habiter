"use client";

import { useId, useState } from "react";

import styles from "./habit-product-demo.module.css";

type DemoView = "today" | "rhythm" | "insight" | "focus";

type HabitProductDemoProps = {
  initialView?: DemoView;
  compact?: boolean;
};

const views: Array<{ id: DemoView; icon: string; label: string }> = [
  { id: "today", icon: "✓", label: "Heute" },
  { id: "rhythm", icon: "⌁", label: "Rhythmus" },
  { id: "insight", icon: "✦", label: "Insights" },
  { id: "focus", icon: "◇", label: "Focus" },
];

const week = [
  { day: "M", done: true },
  { day: "D", done: true },
  { day: "M", done: false },
  { day: "D", done: true },
  { day: "F", done: true },
  { day: "S", done: true },
  { day: "S", done: false },
];

function TodayView({ complete, onComplete }: { complete: boolean; onComplete: () => void }) {
  return (
    <div className={`${styles.view} ${styles.todayView}`}>
      <span className={styles.viewLabel}>Deine letzte Gewohnheit</span>
      <span className={styles.habitEmoji} aria-hidden="true">
        🌿
      </span>
      <h3>10 Minuten bewegen</h3>
      <div className={styles.completeRow}>
        <span className={`${styles.statusPill} ${complete ? styles.statusComplete : ""}`}>
          <i /> {complete ? "Für heute erledigt" : "Heute noch offen"}
        </span>
        <button
          className={`${styles.completeButton} ${complete ? styles.completeButtonDone : ""}`}
          type="button"
          aria-pressed={complete}
          aria-label={complete ? "Abschluss zurücknehmen" : "Gewohnheit als erledigt markieren"}
          onClick={onComplete}
        >
          {complete ? "↺" : "✓"}
        </button>
      </div>
      <p className={styles.microcopy} aria-live="polite">
        {complete ? "Kleiner Schritt. Echter Fortschritt." : "Die kleine Version zählt."}
      </p>
    </div>
  );
}

function RhythmView() {
  return (
    <div className={`${styles.view} ${styles.rhythmView}`}>
      <span className={styles.viewLabel}>Dein Rhythmus</span>
      <div className={styles.rhythmHeadline}>
        <div>
          <span>Diese Woche</span>
          <strong>5 von 7</strong>
        </div>
        <b>71%</b>
      </div>
      <div className={styles.week} aria-label="Fünf von sieben Tagen abgeschlossen">
        {week.map((item, index) => (
          <div className={styles.day} key={`${item.day}-${index}`}>
            <span className={item.done ? styles.dayDone : ""}>{item.done ? "✓" : ""}</span>
            <small>{item.day}</small>
          </div>
        ))}
      </div>
      <div className={styles.rhythmCard}>
        <div>
          <span>Stabiler als letzte Woche</span>
          <strong>+14%</strong>
        </div>
        <svg viewBox="0 0 220 74" role="img" aria-label="Sanft steigender Fortschrittsverlauf">
          <defs>
            <linearGradient id="demo-area" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0" stopColor="#356859" stopOpacity=".32" />
              <stop offset="1" stopColor="#356859" stopOpacity="0" />
            </linearGradient>
          </defs>
          <path className={styles.area} d="M1 69C25 58 38 62 58 50s30-2 50-18 34 4 55-10 33-9 56-18v70H1Z" />
          <path className={styles.line} d="M1 69C25 58 38 62 58 50s30-2 50-18 34 4 55-10 33-9 56-18" />
        </svg>
      </div>
    </div>
  );
}

function InsightView() {
  return (
    <div className={`${styles.view} ${styles.insightView}`}>
      <span className={styles.viewLabel}>Insight · diese Woche</span>
      <span className={styles.spark} aria-hidden="true">
        ✦
      </span>
      <h3>Dein Morgen trägt den ganzen Tag.</h3>
      <p>
        An Tagen mit Bewegung vor 09:00 Uhr schließt du deine übrigen Gewohnheiten deutlich
        häufiger ab.
      </p>
      <div className={styles.insightSignal}>
        <span>
          <i /> Starkes Muster
        </span>
        <strong>+23%</strong>
      </div>
      <div className={styles.insightAction}>
        <span>Morgen ausprobieren</span>
        <strong>10 Min. Bewegung · 08:30</strong>
      </div>
    </div>
  );
}

function FocusView() {
  return (
    <div className={`${styles.view} ${styles.focusView}`}>
      <span className={styles.viewLabel}>Focus Shield</span>
      <div className={styles.shield} aria-hidden="true">
        <span>◇</span>
      </div>
      <h3>Dein Morgen bleibt bei dir.</h3>
      <p>Bis „10 Minuten bewegen“ erledigt ist, warten drei ausgewählte Ablenkungen.</p>
      <div className={styles.blockedApps}>
        <span>Social <b>wartet</b></span>
        <span>Shorts <b>wartet</b></span>
        <span>Games <b>wartet</b></span>
      </div>
      <div className={styles.focusRule}>
        <span>Freigabe</span>
        <strong>Nach deinem Ritual</strong>
      </div>
    </div>
  );
}

export function HabitProductDemo({ initialView = "today", compact = false }: HabitProductDemoProps) {
  const [activeView, setActiveView] = useState<DemoView>(initialView);
  const [complete, setComplete] = useState(false);
  const panelId = useId();

  return (
    <div className={`${styles.frame} ${compact ? styles.compact : ""}`}>
      <div className={styles.glass}>
        <div className={styles.statusBar} aria-hidden="true">
          <span>9:41</span>
          <span>● ◒ ▰</span>
        </div>
        <div className={styles.appActions}>
          <span className={styles.roundAction} aria-hidden="true">◇</span>
          <span className={styles.demoBrand}>habiter</span>
          <span className={styles.roundAction} aria-hidden="true">○</span>
        </div>

        <div className={styles.panel} id={panelId} role="tabpanel">
          {activeView === "today" ? (
            <TodayView complete={complete} onComplete={() => setComplete((value) => !value)} />
          ) : null}
          {activeView === "rhythm" ? <RhythmView /> : null}
          {activeView === "insight" ? <InsightView /> : null}
          {activeView === "focus" ? <FocusView /> : null}
        </div>

        <div className={styles.wheel}>
          <span className={styles.wheelHint}>Bereich wählen</span>
          <div className={styles.wheelCards} role="tablist" aria-label="App-Bereiche">
            {views.map((view) => (
              <button
                className={`${styles.wheelCard} ${activeView === view.id ? styles.wheelCardActive : ""}`}
                key={view.id}
                type="button"
                role="tab"
                aria-controls={panelId}
                aria-selected={activeView === view.id}
                onClick={() => setActiveView(view.id)}
              >
                <span aria-hidden="true">{view.icon}</span>
                <strong>{view.label}</strong>
              </button>
            ))}
          </div>
        </div>
      </div>
      <span className={styles.demoNote}>Interaktive Produktvorschau · probier sie aus</span>
    </div>
  );
}

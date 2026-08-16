"use client";

import { useEffect, useState } from "react";

type Theme = "light" | "dark";

export function ThemeToggle() {
  const [theme, setTheme] = useState<Theme | null>(null);

  useEffect(() => {
    const root = document.documentElement;
    const system = window.matchMedia("(prefers-color-scheme: light)");
    const sync = () => setTheme(root.dataset.theme === "light" ? "light" : "dark");
    const followSystem = () => {
      if (localStorage.getItem("habiter-theme")) return;
      const next: Theme = system.matches ? "light" : "dark";
      root.dataset.theme = next;
      root.style.colorScheme = next;
      sync();
    };
    sync();
    system.addEventListener("change", followSystem);
    return () => system.removeEventListener("change", followSystem);
  }, []);

  const toggle = () => {
    const root = document.documentElement;
    const nextTheme: Theme = root.dataset.theme === "light" ? "dark" : "light";
    root.dataset.theme = nextTheme;
    root.style.colorScheme = nextTheme;
    localStorage.setItem("habiter-theme", nextTheme);
    setTheme(nextTheme);
  };

  return (
    <button
      className="theme-toggle"
      data-ready={theme ? "true" : "false"}
      type="button"
      onClick={toggle}
      aria-pressed={theme === "dark"}
      aria-label={theme === "dark" ? "Hellen Modus aktivieren" : "Dunklen Modus aktivieren"}
      title={theme === "dark" ? "Heller Modus" : "Dunkler Modus"}
    >
      <span className="theme-toggle-track" aria-hidden="true">
        {theme === "dark" ? (
          <svg className="theme-icon sun" viewBox="0 0 24 24"><circle cx="12" cy="12" r="4" /><path d="M12 2v2M12 20v2M4.93 4.93l1.42 1.42M17.66 17.66l1.41 1.41M2 12h2M20 12h2M4.93 19.07l1.42-1.42M17.66 6.34l1.41-1.41" /></svg>
        ) : (
          <svg className="theme-icon moon" viewBox="0 0 24 24"><path d="M20.6 15.1A8.5 8.5 0 0 1 8.9 3.4 8.5 8.5 0 1 0 20.6 15.1Z" /></svg>
        )}
      </span>
    </button>
  );
}

"use client";

import { useEffect, useState } from "react";

type Theme = "light" | "dark";

export function ThemeToggle() {
  const [theme, setTheme] = useState<Theme>("dark");

  useEffect(() => {
    setTheme(document.documentElement.dataset.theme === "light" ? "light" : "dark");
  }, []);

  const toggle = () => {
    const nextTheme: Theme = theme === "dark" ? "light" : "dark";
    document.documentElement.dataset.theme = nextTheme;
    document.documentElement.style.colorScheme = nextTheme;
    localStorage.setItem("habiter-theme", nextTheme);
    setTheme(nextTheme);
  };

  return (
    <button
      className="theme-toggle"
      type="button"
      onClick={toggle}
      aria-label={theme === "dark" ? "Hellen Modus aktivieren" : "Dunklen Modus aktivieren"}
      title={theme === "dark" ? "Heller Modus" : "Dunkler Modus"}
    >
      <span aria-hidden="true">{theme === "dark" ? "☀" : "☾"}</span>
    </button>
  );
}

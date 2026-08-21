import type { Metadata } from "next";

import { FoundationPage } from "@/components/foundation-page";

export const metadata: Metadata = {
  title: "Focus Shield",
  description: "Schütze wichtige Gewohnheiten vor digitalen Ablenkungen.",
  alternates: { canonical: "/focus/" },
};

export default function FocusPage() {
  return (
    <FoundationPage
      eyebrow="Focus Shield"
      title="Erst dein Ritual. Dann der Feed."
      copy="Habiter setzt bewusste Reibung zwischen dich und die Apps, die deine Aufmerksamkeit sonst zuerst bekommen."
    />
  );
}

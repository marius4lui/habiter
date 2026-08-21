import type { Metadata } from "next";

import { FoundationPage } from "@/components/foundation-page";

export const metadata: Metadata = {
  title: "Privacy",
  description: "Habiter denkt persönliche Gewohnheitsdaten lokal und transparent.",
  alternates: { canonical: "/privacy/" },
};

export default function PrivacyPage() {
  return (
    <FoundationPage
      eyebrow="Privacy by design"
      title="Dein Verhalten ist kein Werbeprofil."
      copy="Gewohnheiten erzählen viel über dich. Deshalb beginnt Habiter bei lokaler Datenhaltung und klaren, nachvollziehbaren Grenzen."
    />
  );
}

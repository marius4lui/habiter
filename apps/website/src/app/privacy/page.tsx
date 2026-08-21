import type { Metadata } from "next";

import { PrivacyPage as PrivacyExperiencePage } from "@/components/privacy-page";

export const metadata: Metadata = {
  title: "Privacy",
  description: "Habiter denkt persönliche Gewohnheitsdaten lokal und transparent.",
  alternates: { canonical: "/privacy/" },
};

export default function PrivacyPage() {
  return <PrivacyExperiencePage />;
}

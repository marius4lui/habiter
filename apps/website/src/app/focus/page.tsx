import type { Metadata } from "next";

import { FocusPage as FocusExperiencePage } from "@/components/focus-page";

export const metadata: Metadata = {
  title: "Focus Shield",
  description: "Schütze wichtige Gewohnheiten vor digitalen Ablenkungen.",
  alternates: { canonical: "/focus/" },
};

export default function FocusPage() {
  return <FocusExperiencePage />;
}

import type { Metadata } from "next";

import { FoundationPage } from "@/components/foundation-page";

export const metadata: Metadata = {
  title: "Produkt",
  description: "Entdecke den Tagesfokus, Rhythmus und die Insights von Habiter.",
  alternates: { canonical: "/product/" },
};

export default function ProductPage() {
  return (
    <FoundationPage
      eyebrow="Die Experience"
      title="Ein System für den nächsten kleinen Schritt."
      copy="Habiter reduziert einen vollen Tag auf das, was jetzt machbar ist — und macht Rückkehr wertvoller als Perfektion."
    />
  );
}

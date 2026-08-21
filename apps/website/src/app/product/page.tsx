import type { Metadata } from "next";

import { ProductPage as ProductExperiencePage } from "@/components/product-page";

export const metadata: Metadata = {
  title: "Produkt",
  description: "Entdecke den Tagesfokus, Rhythmus und die Insights von Habiter.",
  alternates: { canonical: "/product/" },
};

export default function ProductPage() {
  return <ProductExperiencePage />;
}

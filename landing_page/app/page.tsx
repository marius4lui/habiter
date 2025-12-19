import { headers } from "next/headers";
import { redirect } from "next/navigation";

export default async function RootPage() {
  const headersList = await headers();
  const acceptLanguage = headersList.get("accept-language") || "";

  // Check if German is preferred
  const isGerman = acceptLanguage.toLowerCase().startsWith("de");

  redirect(isGerman ? "/de" : "/en");
}

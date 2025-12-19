import Link from "next/link";

type FooterProps = {
    locale: "de" | "en";
};

const translations = {
    de: {
        privacy: "Datenschutz",
        terms: "AGB",
        imprint: "Impressum",
        copyright: "© 2025 Habiter. Alle Rechte vorbehalten.",
    },
    en: {
        privacy: "Privacy Policy",
        terms: "Terms of Service",
        imprint: "Imprint",
        copyright: "© 2025 Habiter. All rights reserved.",
    },
};

export function Footer({ locale }: FooterProps) {
    const t = translations[locale];
    const basePath = `/${locale}`;

    return (
        <footer>
            <div className="footer-links">
                <Link href={`${basePath}/privacy`}>{t.privacy}</Link>
                <Link href={`${basePath}/terms`}>{t.terms}</Link>
                <Link href={`${basePath}/imprint`}>{t.imprint}</Link>
            </div>
            <p>{t.copyright}</p>
        </footer>
    );
}

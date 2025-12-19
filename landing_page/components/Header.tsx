"use client";

import Image from "next/image";
import Link from "next/link";
import { usePathname } from "next/navigation";

type HeaderProps = {
    locale: "de" | "en";
    showFeatures?: boolean;
    showDownload?: boolean;
};

const translations = {
    de: {
        features: "Funktionen",
        download: "Download",
        home: "Home",
        langSwitch: "EN",
        langSwitchLocale: "en",
    },
    en: {
        features: "Features",
        download: "Download",
        home: "Home",
        langSwitch: "DE",
        langSwitchLocale: "de",
    },
};

export function Header({ locale, showFeatures = true, showDownload = true }: HeaderProps) {
    const t = translations[locale];
    const basePath = `/${locale}`;
    const pathname = usePathname();

    // Get the path without the locale prefix
    const pathWithoutLocale = pathname.replace(`/${locale}`, "") || "";
    const switchPath = `/${t.langSwitchLocale}${pathWithoutLocale}`;

    return (
        <header>
            <Link href={basePath} className="brand">
                <Image
                    src="/icon.png"
                    alt="Habiter Logo"
                    width={32}
                    height={32}
                    className="brand-logo"
                />
                Habiter
            </Link>
            <nav className="nav-links">
                {showFeatures && (
                    <Link href={`${basePath}#features`} className="nav-link">
                        {t.features}
                    </Link>
                )}
                {showDownload && (
                    <Link href={`${basePath}#download`} className="nav-link">
                        {t.download}
                    </Link>
                )}
                {!showFeatures && (
                    <Link href={basePath} className="nav-link">
                        {t.home}
                    </Link>
                )}
                <Link
                    href={switchPath}
                    className="nav-link lang-switch"
                >
                    {t.langSwitch}
                </Link>
            </nav>
        </header>
    );
}


import { MetadataRoute } from 'next';

export default function sitemap(): MetadataRoute.Sitemap {
    const baseUrl = 'https://habiter.qhrd.online';
    const locales = ['de', 'en'];
    const paths = ['', '/live', '/test', '/imprint', '/privacy', '/terms'];

    const routes = locales.flatMap((locale) =>
        paths.map((path) => ({
            url: `${baseUrl}/${locale}${path}`,
            lastModified: new Date(),
            changeFrequency: 'weekly' as const,
            priority: path === '' ? 1 : 0.8,
        }))
    );

    return routes;
}

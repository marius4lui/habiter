import { defineConfig } from 'vitepress'

export default defineConfig({
  lang: 'en-US',
  title: 'Habiter',
  description: 'Local-first habit tracking with reminders, analytics, widgets, and optional Android App Lock.',
  base: '/',
  cleanUrls: true,
  lastUpdated: true,
  sitemap: { hostname: 'https://docs.habiter.dev' },
  
  head: [
    ['link', { rel: 'icon', href: '/icon.png' }],
    ['meta', { name: 'theme-color', content: '#6750a4' }]
  ],

  themeConfig: {
    logo: '/icon.png',
    
    nav: [
      { text: 'Home', link: '/' },
      { text: 'User guide', link: '/guide/getting-started' },
      { text: 'Development', link: '/dev/architecture' },
      { text: 'Releases', link: '/release-operations' }
    ],

    sidebar: {
      '/guide/': [
        {
          text: 'User Guide',
          items: [
            { text: 'Getting Started', link: '/guide/getting-started' },
            { text: 'Features', link: '/guide/features' },
            { text: 'App Lock', link: '/guide/app-lock' },
            { text: 'Classly Sync', link: '/guide/classly-sync' }
          ]
        }
      ],
      '/dev/': [
        {
          text: 'Developer Guide',
          items: [
            { text: 'Architecture', link: '/dev/architecture' },
            { text: 'Branch Workflow', link: '/dev/branches' },
            { text: 'State Management', link: '/dev/state' },
            { text: 'Services', link: '/dev/services' },
            { text: 'Documentation', link: '/dev/documentation' }
          ]
        }
      ]
    },

    socialLinks: [
      { icon: 'github', link: 'https://github.com/marius4lui/habiter' }
    ],

    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Copyright © 2024–2026 Habiter'
    },

    search: { provider: 'local' },
    outline: { level: [2, 3], label: 'On this page' },
    editLink: {
      pattern: 'https://github.com/marius4lui/habiter/edit/main/docs/:path',
      text: 'Edit this page on GitHub'
    },
    lastUpdated: { text: 'Last updated' }
  }
})

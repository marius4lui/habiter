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
      { text: 'API', link: '/api/release-api' },
      { text: 'Development', link: '/dev/architecture' },
      { text: 'Operations', link: '/release-operations' }
    ],

    sidebar: {
      '/guide/': [
        {
          text: 'User Guide',
          items: [
            { text: 'Getting Started', link: '/guide/getting-started' },
            { text: 'Features', link: '/guide/features' },
            { text: 'Reminders', link: '/guide/reminders' },
            { text: 'Updates', link: '/guide/updates' },
            { text: 'Data and Privacy', link: '/guide/data-and-privacy' },
            { text: 'App Lock', link: '/guide/app-lock' },
            { text: 'Classly Sync', link: '/guide/classly-sync' }
          ]
        }
      ],
      '/api/': [
        {
          text: 'API Reference',
          items: [
            { text: 'Release API', link: '/api/release-api' },
            { text: 'Manifest and Signatures', link: '/api/release-manifest' }
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
            { text: 'Platform Channels', link: '/dev/platform-contracts' },
            { text: 'Testing and Quality', link: '/dev/testing' },
            { text: 'Android Widget QA', link: '/dev/widget-qa' },
            { text: 'Documentation', link: '/dev/documentation' }
          ]
        }
      ],
      '/': [
        {
          text: 'Operations',
          items: [
            { text: 'Release Operations', link: '/release-operations' },
            { text: 'Release Verification', link: '/release-candidate' },
            { text: 'Reminder QA', link: '/reminder-qa' },
            { text: 'App Lock QA', link: '/app-lock' },
            { text: 'Mobile UX System', link: '/mobile-ux-system' }
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

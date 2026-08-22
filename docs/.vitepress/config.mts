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
      { text: 'Installation', link: '/install/' },
      { text: 'API', link: '/api/release-api' },
      { text: 'Development', link: '/dev/architecture' },
      { text: 'Operations', link: '/release-operations' }
    ],

    sidebar: {
      '/install/': [
        {
          text: 'Installation',
          items: [
            { text: 'Overview', link: '/install/' },
            { text: 'Linux', link: '/install/linux/' },
            { text: 'Ubuntu', link: '/install/linux/ubuntu' },
            { text: 'Debian', link: '/install/linux/debian' },
            { text: 'Fedora', link: '/install/linux/fedora' },
            { text: 'Arch Linux', link: '/install/linux/arch' },
            { text: 'openSUSE', link: '/install/linux/opensuse' },
            { text: 'Generic Linux', link: '/install/linux/generic' },
            { text: 'Personal Sync Docker Beta', link: '/install/personal-sync-docker' },
            { text: 'Personal Sync Worker Beta', link: '/install/personal-sync-worker' },
            { text: 'Windows', link: '/install/windows' },
            { text: 'macOS', link: '/install/macos' }
          ]
        }
      ],
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
            { text: 'Manifest and Signatures', link: '/api/release-manifest' },
            { text: 'Classly Compatibility', link: '/api/classly-compatible' },
            { text: 'Backup JSON Format', link: '/api/backup-format' },
            { text: 'Personal Sync HTTP API', link: '/api/personal-sync-http' }
          ]
        }
      ],
      '/dev/': [
        {
          text: 'Developer Guide',
          items: [
            { text: 'Architecture', link: '/dev/architecture' },
            { text: 'Agent Workflows', link: '/dev/agent-workflows/' },
            { text: 'Agent Modes', link: '/dev/agent-workflows/modes' },
            { text: 'Issue Trigger', link: '/dev/agent-workflows/issue-trigger' },
            { text: 'Change Playbooks', link: '/dev/agent-workflows/playbooks' },
            { text: 'Execution Checklists', link: '/dev/agent-workflows/checklists' },
            { text: 'Handoffs and Evidence', link: '/dev/agent-workflows/handoffs' },
            { text: 'Branch Workflow', link: '/dev/branches' },
            { text: 'State Management', link: '/dev/state' },
            { text: 'Services', link: '/dev/services' },
            { text: 'Personal Sync Data Contract', link: '/dev/personal-sync-data-contract' },
            { text: 'Personal Sync Convergence', link: '/dev/personal-sync-convergence' },
            { text: 'Personal Sync SQLite Storage', link: '/dev/personal-sync-sqlite' },
            { text: 'Personal Sync D1 Storage', link: '/dev/personal-sync-d1' },
            { text: 'Personal Sync Authentication', link: '/dev/personal-sync-auth' },
            { text: 'Mobile Sync Handoff', link: '/dev/mobile-sync-handoff' },
            { text: 'Personal Sync E2E Evidence', link: '/dev/personal-sync-e2e' },
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

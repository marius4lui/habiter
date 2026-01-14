import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'Habiter',
  description: 'Build Habits. Break Limits.',
  base: '/habiter/',
  
  head: [
    ['link', { rel: 'icon', href: '/habiter/favicon.ico' }]
  ],

  themeConfig: {
    logo: '/icon.png',
    
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Guide', link: '/guide/getting-started' },
      { text: 'Development', link: '/dev/architecture' }
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
            { text: 'State Management', link: '/dev/state' },
            { text: 'Services', link: '/dev/services' }
          ]
        }
      ]
    },

    socialLinks: [
      { icon: 'github', link: 'https://github.com/marius4lui/habiter' }
    ],

    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Copyright © 2024 Habiter'
    }
  }
})

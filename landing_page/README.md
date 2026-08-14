# Habiter landing page

Server-first Next.js site for the German and English Habiter product story, legal pages, metadata, and a deliberately small local demo.

The demo stores nothing and does not claim to reproduce native notifications, haptics, or Android App Lock. There are no account, beta-registration, feedback, admin, or Supabase surfaces.

```bash
pnpm install --frozen-lockfile
pnpm lint
pnpm typecheck
pnpm test
pnpm build
```

Routes: `/de`, `/en`, locale `/live`, `/privacy`, `/terms`, and `/imprint`. Unknown locales and removed legacy routes return 404.

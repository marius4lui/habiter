# Documentation development

The documentation is a VitePress site published at [docs.habiter.dev](https://docs.habiter.dev). Source files live in `docs/`; generated `.vitepress/dist` output is ignored and must not be committed.

## Local development

```bash
cd docs
npm ci
npm run docs:dev
```

Open the local URL printed by VitePress. Before committing:

```bash
npm run docs:build
npm run docs:preview
```

Verify desktop and narrow layouts, light and dark appearance, navigation, search, code blocks, and internal links.

## Structure

- `.vitepress/config.mts` owns metadata, navigation, sidebars, search, and canonical base URL.
- `.vitepress/theme/` owns deliberate visual overrides on top of the default theme.
- `public/` contains root assets and the custom-domain `CNAME`.
- `guide/` is user-facing and avoids implementation assumptions.
- `dev/` explains architecture and contribution workflows.
- Root operational pages document release, QA, and platform-specific contracts.

Use root-relative internal links such as `/guide/features`. Use absolute HTTPS URLs for external services. Add every durable developer page to the appropriate sidebar.

## Deployment

`.github/workflows/docs-deploy.yml` builds with the pinned Node/npm lockfile, uploads only `docs/.vitepress/dist`, and deploys through GitHub Pages. It runs for documentation changes on `main` and supports manual dispatch for recovery or verification.

The custom domain is `docs.habiter.dev`, so VitePress must use `base: '/'`. A repository subpath such as `/habiter/` would make CSS and JavaScript requests miss their assets and leave raw HTML.

After deployment, verify:

- the Pages workflow completed successfully;
- `/assets/*.css` and `/assets/*.js` load from the custom-domain root;
- navigation does not add `/habiter/`;
- the home page is styled with JavaScript disabled and enhanced when enabled;
- a nested page such as `/dev/architecture` loads directly.

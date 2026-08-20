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
npm run docs:check
npm run docs:preview
```

Verify desktop and narrow layouts, light and dark appearance, navigation, search, code blocks, and internal links.

## Structure

- `.vitepress/config.mts` owns metadata, navigation, sidebars, search, and canonical base URL.
- `.vitepress/theme/` owns deliberate visual overrides on top of the default theme.
- `public/` contains root assets and the custom-domain `CNAME`.
- `guide/` is user-facing and avoids implementation assumptions.
- `api/` documents public HTTP and signed-data contracts.
- `dev/` explains architecture and contribution workflows.
- Root operational pages document release, QA, and platform-specific contracts.

Use root-relative internal links such as `/guide/features`. Use absolute HTTPS URLs for external services. Add every durable developer page to the appropriate sidebar.

## Content rules

- Write durable behavior and decision rationale, not a transcript of one implementation session.
- Never publish contributor-specific paths, account names, workstation details, tokens, private endpoints, or signing locations.
- Keep release history in the manifest and roadmap; do not keep agent handoffs or temporary execution ledgers in the published site.
- Name the source-of-truth file for a contract and link to the user, developer, API, or operations page that owns its explanation.
- Distinguish automated evidence from physical-device or operator verification.
- Avoid hard-coded “current version” prose when a link to the release feed remains accurate longer.
- Update navigation, examples, and cross-links in the same change as a new durable page.

The documentation validator scans published Markdown for common machine-specific path forms, checks the API inventory against the OpenAPI document, verifies required navigation entries, and then VitePress validates site generation and internal links.

## Public versus repository-internal information

This repository and the VitePress output are public. A file excluded from navigation can still be built, linked, indexed, or read from Git history; hiding it from the sidebar is not an access control.

Do not commit information that requires confidentiality. Keep private operator runbooks and signing-material locations outside the repository. Repository-internal technical contracts are appropriate when they contain no secret data and help maintainers keep two implementations compatible.

## Deployment

`.github/workflows/docs-deploy.yml` builds with the pinned Node/npm lockfile, uploads only `docs/.vitepress/dist`, and deploys through GitHub Pages. It runs for documentation changes on `main` and supports manual dispatch for recovery or verification.

The custom domain is `docs.habiter.dev`, so VitePress must use `base: '/'`. A repository subpath such as `/habiter/` would make CSS and JavaScript requests miss their assets and leave raw HTML.

After deployment, verify:

- the Pages workflow completed successfully;
- `/assets/*.css` and `/assets/*.js` load from the custom-domain root;
- navigation does not add `/habiter/`;
- the home page is styled with JavaScript disabled and enhanced when enabled;
- a nested page such as `/dev/architecture` loads directly.

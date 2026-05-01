# Edge AI Documentation Site

Docusaurus-based static site that renders the canonical markdown content from the repository's [`docs/`](../) tree.

## Prerequisites

- Node.js 24 or later
- npm (bundled with Node.js)

## Local Development

Run all commands from this directory (`docs/docusaurus/`).

```bash
npm install        # Install dependencies
npm start          # Start dev server with hot reload
npm run build      # Build static site to ./build
npm run serve      # Serve the production build locally
npm run clear      # Clear Docusaurus cache
npm test           # Run Jest tests
```

## Directory Structure

- `docusaurus.config.ts` — Site configuration (title, plugins, navbar, footer, broken-link policy)
- `sidebars.js` — Sidebar navigation definition
- `src/` — React components, custom pages, and CSS overrides
- `static/` — Static assets copied verbatim to the build output (images, favicons, redirects)
- `build/` — Generated static site output (git-ignored)

## Relationship to Parent Docs

Authoritative markdown lives in the parent [`docs/`](../) tree. This site consumes those files; edit markdown there, not inside `docs/docusaurus/`. Configuration, theme, and site-specific assets are the only files that belong here.

## Deployment

The site is published via the repository's CI/CD pipeline. See [`docs/build-cicd/`](../build-cicd/) for pipeline details.

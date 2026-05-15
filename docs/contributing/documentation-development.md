---
title: "Documentation Development - Edge AI"
description: "Complete guide for developing, maintaining, and contributing to the Edge AI documentation system with Docusaurus and context-aware URL management for Azure DevOps Wiki builds."
keywords:
  - documentation
  - docusaurus
  - mdx
  - markdown
  - url-tokens
  - azure-devops-wiki
  - github-pages
  - url-replacement
  - documentation-contributing
  - site-development
author: "Edge AI Documentation Team"
last_updated: "2025-09-26"
---

## Overview

The Edge AI documentation is built with [Docusaurus 3.9.2](https://docusaurus.io/) and rendered from the Markdown sources in this `docs/` tree. The Docusaurus site lives at `docs/docusaurus/` and consumes the same Markdown files used for the Azure DevOps Wiki build, so most contributions only require editing Markdown.

URL token replacement (for example `{{REPO_URL}}`) is a **build-time** feature used by the Azure DevOps Wiki builder (`scripts/Build-Wiki.ps1`). Docusaurus and GitHub Pages render Markdown as-is, so use standard relative links in normal documentation authoring.

## Quick Start

1. Clone and install:

   ```bash
   git clone {{CLONE_URL}}
   cd edge-ai/docs/docusaurus
   npm install
   ```

2. Start the local development server:

   ```bash
   npm start
   ```

   Docusaurus serves the site at `http://localhost:3000/edge-ai/` with fast refresh and live reload.

3. Make your changes in Markdown files under `docs/`, then verify them in the browser.

## Writing Documentation

### Use Relative Links Between Docs

Prefer relative Markdown links for navigation inside `docs/`:

```markdown
[Development Environment](./development-environment.md)
[Build CI/CD Overview](../build-cicd/README.md)
```

Absolute repository URLs should only be used when linking to artifacts that are not part of the Docusaurus site (for example, source files, issues, or external repositories).

### URL Tokens (Azure DevOps Wiki Build Only)

When content is destined for the Azure DevOps Wiki, `scripts/Build-Wiki.ps1` replaces URL tokens with the correct absolute URLs for that publishing context. Use tokens only in pages that are intended to appear in the AzDO Wiki build.

Good (AzDO Wiki content):

```markdown
For issues, see {{NEW_ISSUE_URL}}.
Clone with: `git clone {{CLONE_URL}}`
```

Docusaurus and GitHub Pages do not process these tokens at runtime — tokens left in content that is only rendered by Docusaurus will display literally.

### Testing Your Changes

- Run `npm start` in `docs/docusaurus/` and browse the changed pages.
- Check the terminal for broken link warnings emitted by Docusaurus.
- Run `npm run mdlint` from the repo root to lint Markdown.

## Context-Aware URL System (AzDO Wiki Build)

The URL token system is a **build-time** mechanism used by the PowerShell wiki builder to produce correct links for Azure DevOps Wiki output. It does not run in Docusaurus or GitHub Pages output.

### Key Benefits

- **Single-source content**: one Markdown file supports multiple publishing targets.
- **Correct AzDO links**: tokens resolve to AzDO-specific URLs during wiki builds.
- **Environment parity**: the same source content is rendered by Docusaurus for local and GitHub Pages output.

### Available URL Tokens

| Token                  | Purpose                | AzDO Wiki Example                                |
|------------------------|------------------------|--------------------------------------------------|
| `{{REPO_URL}}`         | Repository base URL    | `https://dev.azure.com/{org}/{project}/_git/...` |
| `{{CLONE_URL}}`        | Git clone URL          | `https://dev.azure.com/.../edge-ai`              |
| `{{ISSUES_URL}}`       | Issues listing URL     | AzDO Boards URL                                  |
| `{{NEW_ISSUE_URL}}`    | New issue URL          | AzDO new work item URL                           |
| `{{DOCS_BASE_URL}}`    | Documentation base URL | AzDO Wiki base URL                               |
| `{{CONTRIBUTING_URL}}` | Contributing guide URL | AzDO Wiki contributing page                      |
| `{{PR_URL}}`           | Pull request URL       | AzDO Pull Request URL                            |
| `{{WIKI_URL}}`         | Wiki URL               | AzDO Wiki root                                   |

### Publishing Contexts

- **Local development**: Docusaurus at `http://localhost:3000/edge-ai/`. Tokens render as literal text — use relative links instead.
- **GitHub Pages**: Docusaurus static build deployed under `/edge-ai/`. Tokens render literally.
- **Azure DevOps Wiki**: Built by `scripts/Build-Wiki.ps1`; URL tokens are replaced at build time.

## Content Structure and Organization

### Directory Structure

```text
docs/
├── README.md                   # Documentation landing
├── contributing/               # Contribution guides (this folder)
├── build-cicd/                 # Build and CI/CD documentation
├── getting-started/            # Getting started guides
├── github-copilot/             # Copilot usage docs
├── observability/              # Observability documentation
├── project-planning/           # Planning artifacts and references
├── solution-adr-library/       # Architectural Decision Records
├── solution-security-plan-library/
├── solution-technology-paper-library/
├── templates/                  # Shared templates
├── _parts/                     # AzDO Wiki build fragments (excluded from Docusaurus)
└── docusaurus/                 # Docusaurus site (config, sidebars, theme)
```

### File Naming

- Use lowercase, hyphen-separated file names (`my-new-guide.md`).
- Use `README.md` for section landings.
- Keep related assets under `docs/assets/` and reference them with relative paths.

## Sidebar Navigation (Docusaurus)

Docusaurus generates site navigation from `docs/docusaurus/sidebars.js`. The Docusaurus plugin is configured with `docs.path: '../'` so `docs/` serves as the content root.

To add or change navigation:

1. Edit `docs/docusaurus/sidebars.js` to add or reorder items.
2. Reference documents by their path relative to the `docs/` root, without the `.md` extension.
3. Restart `npm start` if automatic reload does not pick up new files.

## Link Guidelines

### Internal Links

- Use relative Markdown links between documents in `docs/`:

  ```markdown
  [Development Environment](./development-environment.md)
  [Build CI/CD](../build-cicd/README.md)
  ```

- Link to headings with Markdown anchors:

  ```markdown
  [Pull Request Conventions](./coding-conventions.md#pull-request-conventions)
  ```

### External Links

- Link directly to the external URL:

  ```markdown
  [Docusaurus](https://docusaurus.io/)
  ```

- In pages that are published to the AzDO Wiki, prefer URL tokens for repository-scoped URLs.

## Development Workflow

### Local Development Server

From the repository root:

```bash
cd docs/docusaurus
npm install
npm start
```

Docusaurus serves the site at `http://localhost:3000/edge-ai/` with:

- Fast refresh on Markdown and React component changes.
- Live reload of configuration changes (restart required for some config edits).
- Broken link and broken Markdown link warnings in the terminal.

Useful scripts (run from `docs/docusaurus/`):

| Script          | Purpose                             |
|-----------------|-------------------------------------|
| `npm start`     | Start local dev server on port 3000 |
| `npm run build` | Produce static site under `build/`  |
| `npm run serve` | Serve the built static site locally |
| `npm run clear` | Clear Docusaurus caches             |

### Testing Different Contexts

- **Local development (Docusaurus)**: run `npm start` and verify pages and navigation.
- **GitHub Pages**: run `npm run build` then `npm run serve` to validate the static output.
- **Azure DevOps Wiki**: run `pwsh scripts/Build-Wiki.ps1` to produce wiki output and inspect URL token replacement.

### URL Configuration (AzDO Wiki Build)

`scripts/Build-Wiki.ps1` and the AzDO pipeline generate `scripts/url-config.json` with the URLs used for token replacement. This file is not required for Docusaurus or GitHub Pages rendering.

### Build-Time URL Replacement

- **GitHub Pages**: Docusaurus builds static HTML from Markdown. There is no URL token replacement step; use relative links.
- **Azure DevOps Wiki**: `scripts/Build-Wiki.ps1` reads `scripts/url-config.json` and replaces `{{TOKEN}}` occurrences during the wiki build.

### Validation and Linting

Run from the repository root:

```bash
npm run mdlint                                  # Markdown linting
npx markdownlint docs/**/*.md                   # Direct markdownlint invocation
npx markdown-table-formatter docs/**/*.md       # Table formatting
```

## URL Token Reference

| Token               | Purpose                               | Notes                                    |
|---------------------|---------------------------------------|------------------------------------------|
| `{{REPO_URL}}`      | Repository base URL                   | AzDO Wiki build only                     |
| `{{REPO_BASE_URL}}` | Repository base URL (alternate alias) | AzDO Wiki build only                     |
| `{{DOCS_BASE_URL}}` | Documentation base URL                | AzDO Wiki build only                     |
| `{{CLONE_URL}}`     | Git clone URL                         | For `git clone` commands in wiki content |
| `{{NEW_ISSUE_URL}}` | New issue / work item URL             | AzDO Wiki build only                     |

## Troubleshooting

### Links Not Working

- Restart `npm start` and check the terminal for broken link warnings.
- For AzDO Wiki content, confirm URL tokens are well-formed:

  ```bash
  grep -r "{{.*}}" docs/
  ```

### Development Server Issues

- Clear Docusaurus caches and reinstall dependencies:

  ```bash
  cd docs/docusaurus
  npm run clear
  rm -rf node_modules && npm install
  npm start
  ```

- Docusaurus runs on port 3000 by default. If the port is busy:

  ```bash
  lsof -i :3000
  ```

### Getting Help

- File issues at [github.com/microsoft/edge-ai/issues/new](https://github.com/microsoft/edge-ai/issues/new).
- See [Contributing Overview](../contributing/README.md) for broader contribution guidance.

## Scripts Reference

Root-level scripts (run from repo root):

| Script                        | Purpose                                             |
|-------------------------------|-----------------------------------------------------|
| `npm run mdlint`              | Lint all Markdown files                             |
| `npm run mdlint-fix`          | Auto-fix Markdown lint issues                       |
| `pwsh scripts/Build-Wiki.ps1` | Build Azure DevOps Wiki content (token replacement) |

Docusaurus scripts (run from `docs/docusaurus/`):

| Script          | Purpose                                 |
|-----------------|-----------------------------------------|
| `npm start`     | Start Docusaurus dev server (port 3000) |
| `npm run build` | Build the static site to `build/`       |
| `npm run serve` | Serve the built static site locally     |
| `npm run clear` | Clear Docusaurus build caches           |

## Configuration Files

### Essential Files

- `package.json` — root Node scripts including `mdlint`.
- `docs/docusaurus/package.json` — Docusaurus site scripts and dependencies.
- `docs/docusaurus/docusaurus.config.ts` — Docusaurus site configuration.
- `docs/docusaurus/sidebars.js` — sidebar navigation.
- `.mega-linter.yml` — markdown and repository linting configuration.
- `.env.example` — example environment variables.
- `.gitignore` — repository ignore rules.

### Auto-Generated Files (Not in Git)

- `scripts/url-config.json` — generated during AzDO Wiki builds for token replacement.
- `docs/_parts/*.md` — AzDO Wiki build fragments (excluded from Docusaurus).
- `docs/docusaurus/.docusaurus/` — Docusaurus build cache.
- `docs/docusaurus/build/` — Docusaurus static output.
- `docs/docusaurus/node_modules/` — installed Node dependencies.

## Azure DevOps Wiki Build Process

### PowerShell Wiki Builder

The `scripts/Build-Wiki.ps1` PowerShell script produces AzDO-Wiki-ready content from the same Markdown sources used by Docusaurus.

Key features:

- **Comprehensive Content Coverage**: processes documentation across multiple areas:
  - Core documentation (`docs/`)
  - Contributing guides
  - Infrastructure documentation (Terraform and Bicep)
  - Observability documentation
  - Copilot usage guides
  - Learning materials
- **Section-Specific Navigation**: uses `docs/_parts/*.md` fragments to build AzDO navigation.
- **AzDO Integration**: generates `.order` files for AzDO Wiki ordering.
- **URL Token Replacement**: substitutes `{{TOKEN}}` values using `scripts/url-config.json`.
- **Dynamic Content Organization**: composes the wiki structure from the current Markdown tree.

### Build Process

```bash
pwsh scripts/Build-Wiki.ps1
```

The script:

- Reads source Markdown from `docs/` and related folders.
- Applies URL token replacement using the generated URL configuration.
- Composes wiki pages with section-specific navigation fragments from `docs/_parts/`.
- Produces `.order` files for AzDO Wiki ordering.
- Organizes content into an AzDO Wiki directory layout.
- Preserves relative links and references inside the wiki.
- Writes the resulting wiki tree for publication by the pipeline.

### Wiki Structure

```text
.wiki/
├── .order
├── overview.md
├── contributing-guide.md
├── observability/
├── infrastructure/
│   ├── terraform/
│   └── bicep/
├── copilot-guides/
├── learning/
└── github-resources/
```

### Integration with Azure Pipelines

The wiki publishing pipeline (`.azdo/templates/wiki-update-template.yml`) performs a four-step process:

1. Checkout `main` and the target wiki repository.
2. Run `pwsh scripts/Build-Wiki.ps1` to produce wiki content.
3. Copy the generated wiki tree into the wiki repository working copy.
4. Commit and push the updated wiki content.

## Contributing to Documentation

### How to Contribute

1. Fork the repository and create a feature branch.
2. Start the local Docusaurus dev server with `cd docs/docusaurus && npm start`.
3. Follow the writing guidelines above and use URL tokens only in content destined for the AzDO Wiki.
4. Verify changes locally — note that URL token replacement only occurs during the AzDO Wiki build, not in Docusaurus or GitHub Pages output.
5. Run `npm run mdlint` from the repo root and address any findings before submitting a pull request.

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction, then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

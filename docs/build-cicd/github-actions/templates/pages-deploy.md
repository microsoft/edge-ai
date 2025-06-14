---
title: GitHub Pages Docsify Deployment Workflow
description: GitHub Actions reusable workflow for building and deploying Docsify documentation to GitHub Pages
author: Edge AI Team
ms.date: 06/12/2025
ms.topic: concept
estimated_reading_time: 10
keywords:
  - github pages
  - docsify
  - documentation deployment
  - static site deployment
  - github-actions
  - workflow template
  - documentation automation
  - build automation
  - concurrent deployment
  - pages configuration
  - secure deployment
  - documentation publishing
  - url token replacement
---

A reusable workflow that builds and deploys Docsify documentation to GitHub Pages with dynamic URL token replacement for GitHub Pages environment.

## Overview

This workflow builds Docsify documentation from the repository and deploys it to GitHub Pages. It replaces the previous Jekyll-based build system with a Docsify-native build process that includes dynamic URL configuration generation, comprehensive asset management, and enhanced error handling. The workflow can be triggered manually or called from other workflows (like CI/CD pipelines).

## Features

- **Docsify Build System**: Native Docsify CLI build process with Node.js environment
- **Dynamic URL Configuration**: Automatic generation of GitHub Pages-specific URL tokens
- **Asset Management**: Comprehensive copying of docs/assets, custom styling, and CDN-based plugins
- **Build Caching**: NPM dependency caching for improved build performance
- **Build Validation**: Multi-layer verification of HTML structure, plugins, and content
- **Error Handling**: Comprehensive error reporting with detailed debugging information
- **Concurrent Deployment Control**: Prevents multiple simultaneous deployments
- **Manual and Programmatic Triggering**: Can be run manually or called from other workflows
- **Secure Deployment**: Uses GitHub's deployment system with appropriate permissions

## Parameters

| Parameter            | Type   | Required | Description                        | Example                   |
|----------------------|--------|----------|------------------------------------|---------------------------|
| `source_branch`      | string | Yes      | Branch to build documentation from | `main`, `feature/docs`    |
| `deploy_environment` | string | Yes      | Environment to deploy to           | `github-pages`, `staging` |

## Outputs

| Output Variable | Description                               | Example                             |
|-----------------|-------------------------------------------|-------------------------------------|
| `page_url`      | The URL of the deployed GitHub Pages site | `steps.deployment.outputs.page_url` |

## Dependencies

### Required GitHub Permissions

- `contents: read` - To read repository content
- `pages: write` - To deploy to GitHub Pages
- `id-token: write` - For authentication

### Required Repository Setup

- **GitHub Pages**: Must be enabled for the repository
- **Node.js Dependencies**: `package.json` with `docsify-cli` in devDependencies
- **Docsify Configuration**: `index.html` with Docsify setup
- **Documentation Structure**: `docs/` directory with `_sidebar.md`

### Environment Variables

The workflow automatically uses the following GitHub-provided environment variables:

- `GITHUB_REPOSITORY` - Full repository name (owner/repo)
- `GITHUB_REPOSITORY_OWNER` - Repository owner
- `GITHUB_REPOSITORY_NAME` - Repository name
- `SOURCE_BRANCH` - Branch being deployed (from input parameter)

## Usage

### Basic Usage from CI/CD Pipeline

This workflow is typically triggered from another workflow with branch and environment parameters:

```yaml
jobs:
  deploy-docs:
    name: Deploy Documentation
    needs: [build-and-test]
    if: github.ref == 'refs/heads/main'
    uses: ./.github/workflows/pages-deploy.yml
    with:
      source_branch: 'main'
      deploy_environment: 'github-pages'
    secrets: inherit
```

### Feature Branch Documentation

Deploy documentation from a feature branch for preview:

```yaml
jobs:
  deploy-docs-preview:
    name: Deploy Documentation Preview
    uses: ./.github/workflows/pages-deploy.yml
    with:
      source_branch: ${{ github.head_ref }}
      deploy_environment: 'staging'
    secrets: inherit
```

### Manual Triggering

The workflow can be triggered manually from the GitHub Actions tab with custom parameters.

## Implementation Details

The workflow consists of two main jobs with comprehensive Docsify build process:

### Build Job

1. **Environment Setup**:
   - Checks out the repository from specified source branch
   - Sets up Node.js 18 with NPM caching
   - Configures GitHub Pages environment

2. **Dependency Management**:
   - Installs NPM dependencies (including docsify-cli)
   - Uses caching for improved performance

3. **URL Configuration Generation**:
   - Runs `scripts/Generate-GitHubPagesConfig.ps1`
   - Generates GitHub Pages-specific URL tokens
   - Replaces local development URLs with production URLs

4. **Docsify Build Process**:
   - Creates `_site` directory for build output
   - Copies `index.html` and generated `docsify-url-config.js`
   - Copies complete `docs/` directory with all content
   - Copies assets (images, CSS, JS) if present
   - Copies additional static files (`robots.txt`, `sitemap.xml`, etc.)
   - Creates `.nojekyll` file to prevent Jekyll processing

5. **Build Validation**:
   - Verifies critical files are present
   - Checks HTML structure and Docsify configuration
   - Validates plugin references and sidebar content
   - Reports build statistics and potential issues

6. **Artifact Upload**:
   - Uploads the complete `_site` directory as a deployment artifact

### Deploy Job

1. **GitHub Pages Deployment**:
   - Uses `actions/deploy-pages@v4` for deployment
   - Provides the deployed site URL as output

## Key Features

### Dynamic URL Token Replacement

The workflow generates environment-specific URL configuration:

```javascript
// Generated docsify-url-config.js for GitHub Pages
window.EDGE_AI_URL_CONFIG = {
  context: 'github-pages',
  variables: {
    "REPO_URL": "https://github.com/owner/repo",
    "REPO_BASE_URL": "https://github.com/owner/repo/blob/main",
    "DOCS_BASE_URL": "https://owner.github.io/repo",
    "CLONE_URL": "https://github.com/owner/repo.git",
    "NEW_ISSUE_URL": "https://github.com/owner/repo/issues/new"
  }
};
```

### Build Caching Strategy

- NPM dependencies cached based on `package-lock.json` hash
- Node.js setup action includes built-in caching
- Reduces build times significantly for subsequent runs

### Comprehensive Error Handling

- Fail-fast approach for critical build failures
- Detailed error reporting with debug information
- Graceful handling of optional components (assets, additional files)

## Examples

### Example 1: Integration with CI Pipeline

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main]
    paths:
      - 'docs/**'
      - 'src/**/*.md'
      - 'index.html'
      - 'docsify-url-config.js'

jobs:
  build-and-test:
    name: Build and Test
    runs-on: ubuntu-latest
    steps:
      # Build and test steps here

  deploy-docs:
    name: Deploy Documentation
    needs: [build-and-test]
    if: github.ref == 'refs/heads/main'
    uses: ./.github/workflows/pages-deploy.yml
    with:
      source_branch: 'main'
      deploy_environment: 'github-pages'
    secrets: inherit
```

### Example 2: Multi-Environment Deployment

```yaml
jobs:
  # Deploy to staging for all branches
  deploy-docs-staging:
    name: Deploy Documentation (Staging)
    if: github.ref != 'refs/heads/main'
    uses: ./.github/workflows/pages-deploy.yml
    with:
      source_branch: ${{ github.ref_name }}
      deploy_environment: 'staging'
    secrets: inherit

  # Deploy to production for main branch only
  deploy-docs-production:
    name: Deploy Documentation (Production)
    if: github.ref == 'refs/heads/main'
    uses: ./.github/workflows/pages-deploy.yml
    with:
      source_branch: 'main'
      deploy_environment: 'github-pages'
    secrets: inherit
```

## Troubleshooting

### Common Issues

1. **Build Failures**

   **Problem**: Docsify build process fails with missing dependencies

   **Solution**:
   - Ensure `docsify-cli` is listed in `package.json` devDependencies
   - Verify `package-lock.json` is committed to repository
   - Check Node.js version compatibility (workflow uses Node.js 18)

2. **URL Token Replacement Not Working**

   **Problem**: Links in deployed documentation still show local URLs

   **Solution**:
   - Verify `scripts/Generate-GitHubPagesConfig.ps1` exists and is executable
   - Check that markdown content uses token format: `{{REPO_URL}}`
   - Ensure `docsify-url-config.js` is properly loaded in `index.html`

3. **Missing Assets or Styling**

   **Problem**: Images or custom styling not appearing in deployed site

   **Solution**:
   - Verify assets are in `docs/assets/` directory
   - Check that `index.html` references are relative paths
   - Ensure CDN-based plugins are accessible (check browser console)

4. **Navigation or Sidebar Issues**

   **Problem**: Navigation menu not working or sidebar empty

   **Solution**:
   - Verify `docs/_sidebar.md` exists and contains valid navigation
   - Check Docsify configuration in `index.html` for sidebar settings
   - Ensure markdown files referenced in sidebar actually exist

5. **GitHub Pages Not Updating**

   **Problem**: Deployed site not reflecting latest changes

   **Solution**:
   - Check workflow run logs for deployment status
   - Verify GitHub Pages is enabled in repository settings
   - Confirm workflow has required permissions (`pages: write`, `id-token: write`)
   - Check if `.nojekyll` file is present to prevent Jekyll processing

6. **Build Performance Issues**

   **Problem**: Long build times or frequent cache misses

   **Solution**:
   - Verify NPM caching is working (check workflow logs)
   - Consider reducing documentation size or splitting large files
   - Check for unnecessary files being copied in build process

### Debug Information

When troubleshooting, check the following in workflow logs:

- **Environment Variables**: Repository, owner, branch information
- **Build Statistics**: Number of files, total size of build output
- **Validation Results**: Critical file checks, plugin verification
- **Cache Status**: NPM cache hit/miss information

## Migration from Jekyll

If migrating from a Jekyll-based Pages deployment:

1. **Remove Jekyll Dependencies**:
   - Delete `_config.yml` file
   - Remove Jekyll-specific front matter from markdown files
   - Update any Jekyll-specific templating

2. **Update Workflow**:
   - Replace Jekyll build steps with this Docsify workflow
   - Update any references to Jekyll build outputs

3. **Configure Docsify**:
   - Ensure `index.html` contains proper Docsify configuration
   - Create `docs/_sidebar.md` for navigation
   - Test URL token replacement locally before deployment

## Related Workflows

- **Main CI/CD Workflow**: Triggers this workflow when documentation changes
- **Documentation Generation Scripts**: May generate content before deployment

## Learn More

- [Docsify Documentation](https://docsify.js.org/)
- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Pages GitHub Action](https://github.com/marketplace/actions/deploy-github-pages-site)

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

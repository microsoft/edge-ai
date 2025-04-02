# GitHub Pages Deployment Workflow

A reusable workflow that builds and deploys documentation to GitHub Pages whenever documentation files are updated.

## Overview

This workflow is responsible for building documentation from the repository and deploying it to GitHub Pages. It can be triggered manually or called from other workflows (like CI/CD pipelines). The workflow ensures that documentation stays up-to-date with code changes and makes it accessible to users through GitHub Pages.

## Features

- **Manual and Programmatic Triggering**: Can be run manually or called from other workflows
- **Concurrent Deployment Control**: Prevents multiple simultaneous deployments
- **Configurable Documentation Builder**: Supports different documentation generators (commented examples provided)
- **Automatic Pages Configuration**: Sets up GitHub Pages environment automatically
- **Secure Deployment**: Uses GitHub's deployment system with appropriate permissions

## Parameters

This workflow does not accept external parameters but is configured through its YAML definition.

## Outputs

| Output Variable | Description                               | Example                             |
|-----------------|-------------------------------------------|-------------------------------------|
| `page_url`      | The URL of the deployed GitHub Pages site | `steps.deployment.outputs.page_url` |

## Dependencies

This template may depend on the following:

- **Required GitHub Permissions**:
  - `contents: read` - To read repository content
  - `pages: write` - To deploy to GitHub Pages
  - `id-token: write` - For authentication

- **Required GitHub Pages setup**: GitHub Pages must be enabled for the repository

## Usage

### Basic Usage

This workflow is typically triggered from another workflow:

```yaml
jobs:
  documentation:
    name: Update Documentation
    needs: [previous-job]
    uses: ./.github/workflows/pages-deploy.yml
```

### Manual Triggering

The workflow can be triggered manually from the GitHub Actions tab.

## Implementation Details

The workflow consists of two main jobs:

1. **Build**:
   - Checks out the repository
   - Sets up GitHub Pages environment
   - Would build documentation (commented out examples for MkDocs provided)
   - Uploads the built documentation as an artifact

2. **Deploy**:
   - Deploys the documentation artifact to GitHub Pages
   - Provides the URL of the deployed site as an output variable

### Key Components

- **GitHub Pages Configuration**: Uses `actions/configure-pages@v4` to set up the environment
- **Artifact Upload**: Uses `actions/upload-pages-artifact@v3` to prepare the documentation for deployment
- **Pages Deployment**: Uses `actions/deploy-pages@v4` to deploy to GitHub Pages

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

jobs:
  build-and-test:
    name: Build and Test
    runs-on: ubuntu-latest
    steps:
      # Build and test steps here

  deploy-docs:
    name: Update Documentation
    needs: [build-and-test]
    if: github.ref == 'refs/heads/main'
    uses: ./.github/workflows/pages-deploy.yml
```

## Troubleshooting

1. **Documentation Not Updated**: Pages not reflecting latest changes
   - **Solution**: Ensure the correct path is set in the `actions/upload-pages-artifact@v3` action

2. **Deployment Failures**: GitHub Pages deployment failing
   - **Solution**: Check GitHub Pages is enabled in repository settings and the workflow has required permissions

## Related Workflows

- CI/CD Workflow: Typically triggers this workflow when documentation changes

## Learn More

- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Pages GitHub Action](https://github.com/marketplace/actions/deploy-github-pages-site)

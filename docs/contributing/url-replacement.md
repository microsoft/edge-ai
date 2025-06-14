---
title: URL Replacement System
description: Documentation for the URL replacement system used to maintain consistent links across the Edge AI project documentation
author: Edge AI Team
ms.date: 06/06/2025
ms.topic: concept
estimated_reading_time: 8
keywords:
  - url replacement
  - documentation links
  - link management
  - docsify configuration
  - documentation maintenance
  - link consistency
---

## URL Replacement System

The Edge AI project uses a context-aware, variable-based URL replacement system to ensure documentation links work correctly across different publishing contexts (local development, GitHub Pages, Azure DevOps Wiki).

## Overview

Instead of hardcoded URLs, our documentation uses variable tokens that are replaced at build-time or runtime:

```markdown
<!-- Instead of hardcoded URLs -->
[Clone the repository](https://github.com/microsoft/edge-ai.git)

<!-- We use tokens -->
[Clone the repository]({{CLONE_URL}})
```

## Available Tokens

| Token               | Description          | Example                                           |
|---------------------|----------------------|---------------------------------------------------|
| `{{REPO_URL}}`      | Repository home page | `https://github.com/microsoft/edge-ai`            |
| `{{CLONE_URL}}`     | Git clone URL        | `https://github.com/microsoft/edge-ai.git`        |
| `{{ISSUES_URL}}`    | Issues/bug tracker   | `https://github.com/microsoft/edge-ai/issues`     |
| `{{NEW_ISSUE_URL}}` | Create new issue     | `https://github.com/microsoft/edge-ai/issues/new` |
| `{{DOCS_BASE_URL}}` | Documentation base   | `https://microsoft.github.io/edge-ai`             |

## Publishing Contexts

The system supports three publishing contexts, each with different URL patterns:

### Local Development (`local`)

- **Repo URL**: `https://github.com/microsoft/edge-ai`
- **Clone URL**: `https://github.com/microsoft/edge-ai.git`
- **Issues URL**: `https://github.com/microsoft/edge-ai/issues`
- **Docs Base**: `http://localhost:3000` (when serving locally)

### GitHub Pages (`github`)

- **Repo URL**: `https://github.com/microsoft/edge-ai`
- **Clone URL**: `https://github.com/microsoft/edge-ai.git`
- **Issues URL**: `https://github.com/microsoft/edge-ai/issues`
- **Docs Base**: `https://microsoft.github.io/edge-ai`

### Azure DevOps Wiki (`azdo`)

- **Repo URL**: `https://dev.azure.com/msazure/One/_git/edge-ai`
- **Clone URL**: `https://dev.azure.com/msazure/One/_git/edge-ai`
- **Issues URL**: `https://dev.azure.com/msazure/One/_workitems/edit/new`
- **Docs Base**: `https://dev.azure.com/msazure/One/_wiki/wikis/edge-ai.wiki`

## Usage

### For Contributors

When writing documentation, always use tokens instead of hardcoded URLs:

```markdown
<!-- ✅ Good -->
For more information, visit our [repository]({{REPO_URL}}).
To report a bug, [create an issue]({{NEW_ISSUE_URL}}).

<!-- ❌ Avoid -->
For more information, visit our [repository](https://github.com/microsoft/edge-ai).
```

### For Local Development

#### Serving Documentation Locally

```bash
# Serve docs with runtime URL replacement
npm run docs

# Or serve for a specific context
npm run docs:github
npm run docs:azdo
```

#### Manual URL Replacement

```bash
# Replace URLs for GitHub context
npm run url:github

# Replace URLs for Azure DevOps context
npm run url:azdo

# Restore original tokens
npm run url:restore

# Check current URL status
npm run url:status
```

### For Build Pipelines

#### Static Replacement (Build-time)

For build pipelines that generate static files:

```bash
# In your build script
./scripts/replace-urls.sh github  # or 'azdo'
```

#### Runtime Replacement (Dynamic)

For serving with dynamic replacement:

```bash
# Use npm scripts for local development
npm run docs              # Start server with browser opening
npm run docs:no-open      # Start server without opening browser
```

## Configuration

### Main Configuration (`scripts/url-config.json`)

The system uses a centralized configuration file that defines URL mappings for each context:

```json
{
  "contexts": {
    "local": {
      "REPO_URL": "https://github.com/microsoft/edge-ai",
      "CLONE_URL": "https://github.com/microsoft/edge-ai.git",
      "ISSUES_URL": "https://github.com/microsoft/edge-ai/issues",
      "NEW_ISSUE_URL": "https://github.com/microsoft/edge-ai/issues/new",
      "DOCS_BASE_URL": "http://localhost:3000"
    },
    "github": {
      "REPO_URL": "https://github.com/microsoft/edge-ai",
      "CLONE_URL": "https://github.com/microsoft/edge-ai.git",
      "ISSUES_URL": "https://github.com/microsoft/edge-ai/issues",
      "NEW_ISSUE_URL": "https://github.com/microsoft/edge-ai/issues/new",
      "DOCS_BASE_URL": "https://microsoft.github.io/edge-ai"
    },
    "azdo": {
      "REPO_URL": "https://dev.azure.com/msazure/One/_git/edge-ai",
      "CLONE_URL": "https://dev.azure.com/msazure/One/_git/edge-ai",
      "ISSUES_URL": "https://dev.azure.com/msazure/One/_workitems/edit/new",
      "NEW_ISSUE_URL": "https://dev.azure.com/msazure/One/_workitems/edit/new",
      "DOCS_BASE_URL": "https://dev.azure.com/msazure/One/_wiki/wikis/edge-ai.wiki"
    }
  }
}
```

### Local Overrides (`.env`)

Create a `.env` file (based on `.env.example`) to override URLs for your local environment:

```bash
# Local environment overrides
REPO_URL=https://github.com/your-fork/edge-ai
CLONE_URL=https://github.com/your-fork/edge-ai.git
```

## Scripts Reference

### `scripts/replace-urls.sh`

Universal URL replacement script with multiple operation modes:

```bash
# Context-based replacement
./scripts/replace-urls.sh <context>     # github, azdo, local

# Direct replacement
./scripts/replace-urls.sh --replace "{{TOKEN}}" "value"

# Restoration
./scripts/replace-urls.sh --restore

# Status check
./scripts/replace-urls.sh --status
```

### `scripts/local-url-replace.sh`

Helper script for common local development tasks:

```bash
# Setup local environment
./scripts/local-url-replace.sh --setup

# Replace with environment variables
./scripts/local-url-replace.sh --replace

# Restore original tokens
./scripts/local-url-replace.sh --restore

# Show current status
./scripts/local-url-replace.sh --status
```

### NPM Scripts

Enhanced documentation server with runtime URL replacement:

```bash
# Start local development server (port 8080, with browser opening)
npm run docs

# Start server without opening browser
npm run docs:no-open

# Generate URL configuration for development
npm run docs:build-dev

# Generate URL configuration for production (GitHub Pages)
npm run docs:build
```

## Implementation Details

### Runtime Replacement

The runtime replacement system works by:

1. Generating a JavaScript config file (`docsify-url-config.js`) based on the selected context
2. Loading a Docsify plugin that performs client-side URL replacement
3. Replacing tokens in the rendered HTML before display

### Static Replacement

The static replacement system:

1. Reads the configuration from `scripts/url-config.json`
2. Processes all markdown files in the documentation
3. Replaces tokens with context-specific URLs
4. Maintains backup functionality for restoration

### File Patterns

The system processes files matching these patterns:

- `README.md` (root)
- `docs/**/*.md`
- `blueprints/**/README.md`
- Any file containing URL tokens

### Backup and Restoration

- Original files are backed up before replacement
- Backups are stored with `.backup` extension
- Restoration removes replaced files and restores backups
- Git status is checked to prevent data loss

## Troubleshooting

### Common Issues

1. **URLs not replacing**: Check that tokens are properly formatted with double curly braces
2. **Context not found**: Verify the URL configuration is generated correctly with `npm run docs:build-dev`
3. **Permission errors**: Make sure scripts have execute permissions (`chmod +x`)
4. **Port conflicts**: Default port is 8080; docsify will automatically find available port if needed

### Debugging

```bash
# Check what would be replaced
./scripts/replace-urls.sh --status

# Verify configuration
cat scripts/url-config.json | jq '.contexts'

# Test runtime replacement
npm run docs -- --verbose
```

### Recovery

If something goes wrong:

```bash
# Restore from backups
./scripts/replace-urls.sh --restore

# Or reset from git
git checkout -- docs/ README.md
```

## Contributing to the URL System

When adding new URL tokens:

1. Add the token to all contexts in `scripts/url-config.json`
2. Update this documentation
3. Test with all contexts (`local`, `github`, `azdo`)
4. Verify both static and runtime replacement work

When modifying scripts:

1. Ensure backward compatibility
2. Update help text and documentation
3. Test error handling and edge cases
4. Maintain the backup/restore functionality

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

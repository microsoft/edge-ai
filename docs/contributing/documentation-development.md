---
title: Documentation Development Guide
description: Comprehensive guide for developing and maintaining documentation for the Edge AI project, including writing conventions, URL management, local development, and publishing workflows
author: Edge AI Team
ms.date: 06/06/2025
ms.topic: concept
estimated_reading_time: 15
keywords:
  - documentation development
  - docsify
  - url replacement
  - markdown guidelines
  - local development
  - publishing workflows
  - documentation system
  - writing conventions
  - content management
  - github pages
  - azure devops wiki
---

## Documentation Development

This guide covers all aspects of developing and maintaining documentation for the Edge AI project, including writing conventions, URL management, local development, and publishing workflows.

## Documentation System Overview

The Edge AI project uses a comprehensive documentation system that supports multiple publishing contexts and maintains consistency across all content. Our documentation is built with [Docsify](https://docsify.js.org/) and supports context-aware URL replacement for seamless deployment across different platforms.

## Quick Start for Documentation Development

### 1. Set Up Local Development Environment

```bash
# Clone the repository
git clone {{CLONE_URL}}
cd edge-ai

# Install dependencies
npm install

# Serve documentation locally with hot reload
npm run docs
```

This will start a local development server at `http://localhost:3000` with automatic URL replacement and hot reload for all documentation changes.

### 2. Writing Documentation

Always use variable tokens instead of hardcoded URLs:

```markdown
<!-- ✅ Good -->
[Clone the repository]({{CLONE_URL}})
[Report an issue]({{NEW_ISSUE_URL}})
[View documentation]({{DOCS_BASE_URL}}/docs/getting-started)

<!-- ❌ Avoid hardcoded URLs -->
[Clone the repository](https://github.com/microsoft/edge-ai.git)
[Report an issue](https://github.com/microsoft/edge-ai/issues/new)
```

### 3. Testing Your Changes

The URL replacement system works automatically:

- **Local Development**: URLs are replaced at runtime by the docs server
- **GitHub Pages**: URLs are replaced at build time by the GitHub workflow
- **Azure DevOps Wiki**: URLs are replaced at build time by the wiki build script

Simply use the variable tokens in your documentation and the system handles the rest!

## Context-Aware URL System

### System Overview

The Edge AI project uses a variable-based URL replacement system that automatically adapts documentation links based on the publishing context. This ensures that links work correctly whether you're developing locally, viewing on GitHub Pages, or reading in Azure DevOps Wiki.

**Key Benefits:**

- ✅ Links work across all publishing platforms
- ✅ No manual URL updates needed when switching contexts
- ✅ Consistent experience for all users
- ✅ Automated testing and validation

### Available URL Tokens

| Token                  | Description          | Local            | GitHub           | Azure DevOps               |
|------------------------|----------------------|------------------|------------------|----------------------------|
| `{{REPO_URL}}`         | Repository home page | GitHub URL       | GitHub URL       | Azure DevOps URL           |
| `{{CLONE_URL}}`        | Git clone URL        | GitHub clone     | GitHub clone     | Azure DevOps clone         |
| `{{ISSUES_URL}}`       | Issues/bug tracker   | GitHub issues    | GitHub issues    | Azure DevOps work items    |
| `{{NEW_ISSUE_URL}}`    | Create new issue     | GitHub new issue | GitHub new issue | Azure DevOps new work item |
| `{{DOCS_BASE_URL}}`    | Documentation base   | `localhost:3000` | GitHub Pages     | Azure DevOps Wiki          |
| `{{CONTRIBUTING_URL}}` | Contributing guide   | Local path       | GitHub path      | Azure DevOps path          |
| `{{PR_URL}}`           | Pull request base    | GitHub PRs       | GitHub PRs       | Azure DevOps PRs           |
| `{{WIKI_URL}}`         | Wiki base            | Local docs       | GitHub wiki      | Azure DevOps wiki          |

### Publishing Contexts

#### Local Development (`local`)

- **Purpose**: Development and testing
- **Docs Base**: `http://localhost:3000`
- **Features**: Hot reload, runtime URL replacement, context switching

#### GitHub Pages (`github`)

- **Purpose**: Public documentation hosting
- **Docs Base**: `https://microsoft.github.io/edge-ai`
- **Features**: Static site generation, GitHub integration

#### Azure DevOps Wiki (`azdo`)

- **Purpose**: Internal documentation and enterprise scenarios
- **Docs Base**: Azure DevOps Wiki URL
- **Features**: Enterprise integration, work item linking

### Runtime URL Replacement

The documentation server includes intelligent runtime URL replacement:

```javascript
// Automatic context detection and URL replacement
// Generated dynamically based on current environment
window.$docsify.plugins.push(function(hook) {
  hook.beforeEach(function(content) {
    return replaceTokens(content, currentContext);
  });
});
```

### Configuration

URL mappings are defined in `scripts/url-config.json`:

```json
{
  "local": {
    "REPO_URL": "https://github.com/microsoft/edge-ai",
    "CLONE_URL": "https://github.com/microsoft/edge-ai.git",
    "DOCS_BASE_URL": "http://localhost:3000"
  },
  "github": {
    "REPO_URL": "https://github.com/microsoft/edge-ai",
    "CLONE_URL": "https://github.com/microsoft/edge-ai.git",
    "DOCS_BASE_URL": "https://microsoft.github.io/edge-ai"
  },
  "azdo": {
    "REPO_URL": "https://dev.azure.com/msazure/One/_git/edge-ai",
    "CLONE_URL": "https://dev.azure.com/msazure/One/_git/edge-ai",
    "DOCS_BASE_URL": "https://dev.azure.com/msazure/One/_wiki/wikis/edge-ai.wiki"
  }
}
```

## Writing Guidelines

### Markdown Standards

Follow the linting rules defined in `.mega-linter.yml`:

- **Headers**: Always include blank lines before and after headers
- **Lists**: Use `-` for unordered lists, `1.` for ordered lists
- **Code blocks**: Always specify the language
- **Tables**: Include header row and separator row
- **Links**: Use reference-style for repeated URLs

### Content Structure

#### Document Organization

```txt
docs/
├── index.md                    # Main documentation index
├── getting-started/            # User onboarding guides
│   ├── general-user.md
│   ├── blueprint-developer.md
│   └── feature-developer.md
├── contributing/               # Developer documentation
│   ├── index.md
│   ├── documentation-development.md
│   ├── url-replacement.md
│   └── ...
└── solution-*/                 # Reference materials
```

#### File Naming Conventions

- Use lowercase with hyphens: `my-documentation-file.md`
- Be descriptive: `azure-iot-operations-setup.md` not `aio-setup.md`
- Group related files in directories

### Link Guidelines

#### Internal Links

```markdown
<!-- ✅ Relative links for internal content -->
[Getting Started](./getting-started/index.md)
[Contributing](../contributing/index.md)

<!-- ✅ Use tokens for dynamic base URLs -->
[Documentation Home]({{DOCS_BASE_URL}}/docs/)
```

#### External Links

```markdown
<!-- ✅ Use tokens for repository links -->
[Report an Issue]({{NEW_ISSUE_URL}})
[Clone Repository]({{CLONE_URL}})

<!-- ✅ Direct links for external resources -->
[Azure Documentation](https://docs.microsoft.com/azure/)
```

## Development Workflow

### Quick Start

1. **Set up URL configuration** (first time only):

   ```bash
   npm run docs:setup
   ```

2. **Start the documentation server**:

   ```bash
   npm run docs
   ```

3. **Edit documentation** - the server will automatically reload

### Local Development Server

The enhanced documentation server provides:

```bash
npm run docs
```

**Features:**

- 🔄 Hot reload for immediate preview
- 🔀 Runtime URL replacement based on context
- 🎯 Automatic context detection
- 📊 Real-time link validation

**Server Options:**

```bash
npm run docs                    # Start with default context
npm run docs -- --context=github   # Test GitHub Pages URLs
npm run docs -- --context=azdo     # Test Azure DevOps URLs
npm run docs -- --open             # Start and open browser
npm run docs -- --port=8080        # Use different port
```

### Testing Different Contexts

Test your documentation in different publishing environments:

```bash
# Test GitHub Pages deployment
npm run docs -- --context=github

# Test Azure DevOps Wiki deployment
npm run docs -- --context=azdo

# Back to local development
npm run docs
```

### URL Configuration

The URL replacement system is fully automated and environment-specific:

- **Local Development**: The docs server generates URL config automatically based on your repository
- **GitHub Pages**: The build workflow generates config using GitHub environment variables
- **Azure DevOps Wiki**: The build script generates config using Azure DevOps environment variables

The configuration file (`/scripts/url-config.json`) is automatically generated and should not be committed to the repository (it's in `.gitignore`).

### Build-Time URL Replacement

URL replacement happens automatically during publishing:

**GitHub Pages Workflow:**

1. Generates `url-config.json` using `${{ github.* }}` variables
2. Replaces all `{{TOKEN}}` placeholders with actual URLs
3. Builds and deploys the documentation

**Azure DevOps Wiki Build:**

1. Generates `url-config.json` using `BUILD_*` and `SYSTEM_*` variables
2. Replaces all `{{TOKEN}}` placeholders with actual URLs
3. Copies processed files to wiki structure

### Validation and Linting

```bash
# Run all documentation linting
npm run mdlint

# Run specific linters
npx markdownlint docs/**/*.md
npx markdown-table-formatter docs/**/*.md
```

## URL Token Reference

Use these tokens in your documentation - they'll be replaced automatically:

| Token               | Description             | Example                          |
|---------------------|-------------------------|----------------------------------|
| `{{REPO_URL}}`      | Repository home page    | GitHub repo or AzDO project      |
| `{{REPO_BASE_URL}}` | Base URL for file links | Links to source files            |
| `{{DOCS_BASE_URL}}` | Documentation base URL  | GitHub Pages or local server     |
| `{{CLONE_URL}}`     | Git clone URL           | For git clone commands           |
| `{{NEW_ISSUE_URL}}` | Create new issue URL    | Bug reports and feature requests |

## Troubleshooting

### Common Issues

#### Links Not Working

The URL replacement system is automatic, but if you're having issues:

```bash
# Check if local docs server is running properly
npm run docs

# Check that your documentation uses tokens correctly
grep -r "{{.*}}" docs/
```

#### Development Server Issues

```bash
# Clear cache and restart
rm -rf node_modules/.cache
npm run docs

# Check port conflicts (default port is 8080)
lsof -i :8080
```

### Getting Help

- 🐛 [Report Documentation Issues]({{NEW_ISSUE_URL}})
- 💡 [Contributing Guidelines](../contributing/index.md)

## Scripts Reference

### Available Scripts

| Script                   | Description                                                           | Usage             |
|--------------------------|-----------------------------------------------------------------------|-------------------|
| `npm run docs`           | Start development server with URL replacement                         | Local development |
| `npm run docs:no-open`   | Start development server without opening browser                      | Local development |
| `npm run mdlint`         | Run markdown linting                                                  | Quality assurance |
| `scripts/Build-Wiki.ps1` | Build Azure DevOps Wiki with URL replacement and navigation structure | CI/CD pipeline    |

## Configuration Files

### Essential Files

- `package.json` - npm scripts and dependencies
- `.env.example` - Environment variable templates for local development
- `.mega-linter.yml` - Documentation linting rules
- `.gitignore` - Excludes auto-generated configuration files

### Auto-Generated Files (Not in Git)

- `scripts/url-config.json` - Environment-specific URL mapping
- `docsify-url-config.js` - Runtime URL configuration for docs server
- `docs/_sidebar.md` - Auto-generated navigation sidebar

## Azure DevOps Wiki Build Process

### PowerShell Wiki Builder

The project uses `scripts/Build-Wiki.ps1` to build Azure DevOps Wiki documentation. This PowerShell script provides enhanced functionality over the legacy bash script:

**Key Features:**

- **Complete Content Coverage**: Copies all 202+ documentation files from the `docs/` directory
- **Navigation Preservation**: Parses `docs/_sidebar.md` to recreate hierarchical folder structure
- **Azure DevOps Integration**: Generates `.order` files for proper wiki navigation
- **URL Token Replacement**: Automatically replaces URL tokens with Azure DevOps-specific URLs
- **Infrastructure Organization**: Special handling for terraform, bicep, and other infrastructure content

### Build Process

```powershell
# Run the wiki build locally (requires PowerShell)
pwsh scripts/Build-Wiki.ps1
```

This creates a `.wiki` folder with:

- **458 total files** (all docs + infrastructure content)
- **Hierarchical navigation** matching the sidebar structure
- **Azure DevOps URLs** replacing all variable tokens
- **Proper .order files** for wiki navigation at every level

### Wiki Structure

The generated wiki organizes content as follows:

```text
.wiki/
├── .order                           # Root navigation order
├── overview.md                      # Main README
├── contributing-guide.md            # Contributing guidelines
├── getting-started-*.md             # Getting started content
├── project-planning-*.md            # All project planning docs
├── build-cicd-*.md                  # Build and CI/CD docs
├── observability/                   # Observability section
│   ├── .order                      # Section navigation
│   └── *.md                        # All observability docs
└── infrastructure/                  # Infrastructure content
    ├── .order                      # Infrastructure navigation
    ├── terraform/                  # All terraform docs
    ├── bicep/                      # All bicep docs
    └── *.md                        # Other infrastructure docs
```

### Integration with Azure Pipelines

The build process is integrated with Azure DevOps pipelines via `.azdo/templates/wiki-update-template.yml`, which:

1. Checks out both main and wiki repositories
1. Runs `pwsh scripts/Build-Wiki.ps1` to generate wiki content
1. Copies generated content to the wiki repository
1. Commits and pushes changes to the wiki branch

## Contributing to Documentation

### How to Contribute

1. **Fork the repository** and create a feature branch
1. **Use the development environment** with `npm run docs`
1. **Follow writing guidelines** and use URL tokens
1. **Test locally** - URL replacement is automatic in all contexts
1. **Run linting** with `npm run mdlint`
1. **Submit a pull request** with clear documentation changes

### Review Process

Documentation changes go through:

- ✅ Automated linting and validation
- ✅ Link checking and URL validation
- ✅ Multi-context testing
- ✅ Manual review for content quality
- ✅ Integration testing

### Documentation Standards

- **Accuracy**: All information must be current and correct
- **Completeness**: Cover all necessary details without overwhelming
- **Clarity**: Write for your intended audience
- **Consistency**: Follow established patterns and conventions
- **Accessibility**: Ensure content is accessible to all users

---

## Related Documentation

- 📋 [URL Replacement System](./url-replacement.md) - Complete URL token reference
- 🔧 [Development Environment](./development-environment.md) - Dev container setup
- 🧪 [Testing and Validation](./testing-validation.md) - Quality assurance
- 🤖 [AI-Assisted Engineering](./ai-assisted-engineering.md) - GitHub Copilot workflows
- ❓ [Troubleshooting](./troubleshooting.md) - Common issues and solutions

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

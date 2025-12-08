---
title: Documentation Development Guide
description: Comprehensive guide for developing and maintaining documentation for the Edge AI project, including writing conventions, URL management, local development, and publishing workflows
author: Edge AI Team
ms.date: 2025-06-06
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

This will start a local development server at `http://localhost:8080` with automatic URL replacement and hot reload for all documentation changes.

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

| Token                  | Description          | Local                   | GitHub           | Azure DevOps               |
|------------------------|----------------------|-------------------------|------------------|----------------------------|
| `{{REPO_URL}}`         | Repository home page | GitHub URL              | GitHub URL       | Azure DevOps URL           |
| `{{CLONE_URL}}`        | Git clone URL        | GitHub clone            | GitHub clone     | Azure DevOps clone         |
| `{{ISSUES_URL}}`       | Issues/bug tracker   | GitHub issues           | GitHub issues    | Azure DevOps work items    |
| `{{NEW_ISSUE_URL}}`    | Create new issue     | GitHub new issue        | GitHub new issue | Azure DevOps new work item |
| `{{DOCS_BASE_URL}}`    | Documentation base   | `http://localhost:8080` | GitHub Pages     | Azure DevOps Wiki          |
| `{{CONTRIBUTING_URL}}` | Contributing guide   | Local path              | GitHub path      | Azure DevOps path          |
| `{{PR_URL}}`           | Pull request base    | GitHub PRs              | GitHub PRs       | Azure DevOps PRs           |
| `{{WIKI_URL}}`         | Wiki base            | Local docs              | GitHub wiki      | Azure DevOps wiki          |

### Publishing Contexts

#### Local Development (`local`)

- **Purpose**: Development and testing
- **Docs Base**: `http://localhost:8080`
- **Features**: Hot reload, runtime URL replacement, automatic environment detection

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
    "DOCS_BASE_URL": "http://localhost:8080"
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
├── README.md                   # Main documentation index
├── getting-started/            # User onboarding guides
│   ├── general-user.md
│   ├── blueprint-developer.md
│   └── feature-developer.md
├── contributing/               # Developer documentation
│   ├── README.md
│   ├── documentation-development.md
│   ├── url-replacement.md
│   └── ...
└── solution-*/                 # Reference materials
```

#### File Naming Conventions

- Use lowercase with hyphens: `my-documentation-file.md`
- Be descriptive: `azure-iot-operations-setup.md` not `aio-setup.md`
- Group related files in directories

### Sidebar Navigation System

The documentation uses a dynamic section-specific sidebar navigation system that automatically displays relevant navigation based on the current URL path.

#### Sidebar Files

| File                                    | Purpose                | Content                                          |
|-----------------------------------------|------------------------|--------------------------------------------------|
| `docs/_parts/home-sidebar.md`           | Home section           | Default sidebar for home page                    |
| `docs/_parts/docs-sidebar.md`           | Documentation section  | Getting Started, Contributing, ADR Library, etc. |
| `docs/_parts/learning-sidebar.md`       | Learning section       | Katas, Training Labs, Shared Resources           |
| `docs/_parts/blueprints-sidebar.md`     | Blueprints section     | Various cluster configurations                   |
| `docs/_parts/infrastructure-sidebar.md` | Infrastructure section | Source code navigation                           |
| `docs/_parts/copilot-sidebar.md`        | GitHub Copilot section | AI prompts and guides                            |

#### Dynamic Loading

The system automatically detects the current section based on URL patterns and navbar clicks:

- `/docs/getting-started/` → loads `docs/_parts/docs-sidebar.md`
- `/learning/katas/` → loads `docs/_parts/learning-sidebar.md`
- `/blueprints/full-single-node-cluster/` → loads `docs/_parts/blueprints-sidebar.md`
- `/src/000-cloud/` → loads `docs/_parts/infrastructure-sidebar.md`
- `/copilot/` → loads `docs/_parts/copilot-sidebar.md`

#### Adding New Sections

To add a new navigation section:

1. **Create sidebar file**: `docs/_parts/newsection-sidebar.md`
2. **Update integration**: Add section mapping to `navbar-sidebar-integration.js`
3. **Add navbar**: Update `docs/_navbar.md` with new section
4. **Test functionality**: Verify sidebar switches correctly when clicking navbar

#### Maintenance

- **Section-specific sidebars**: Update only the relevant sidebar file in `docs/_parts/` when adding content
- **Testing**: Dynamic sidebars are tested by navigating between navbar sections
- **Architecture**: All sidebar functionality uses the established `docs/_parts/` structure

### Link Guidelines

#### Internal Links

```markdown
<!-- ✅ Relative links for internal content -->
[Getting Started](./getting-started/README.md)
[Contributing](../contributing/README.md)

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

1. **Install dependencies** (first time only):

   ```bash
   npm install
   ```

2. **Start the documentation server**:

   ```bash
   npm run docs
   ```

3. **Edit documentation** - the server will automatically reload

### Local Development Server

The unified documentation server starts two services:

```bash
npm run docs
```

**Services Started:**

- **Docsify Server** (port 8080): Documentation site with hot reload
- **Progress API Server** (port 3002): Backend for learning progress tracking

**Features:**

- 🔄 Hot reload for immediate preview
- 🔀 Runtime URL replacement based on context
- 🎯 Automatic environment detection (container, Windows, Linux/macOS)
- 📊 Progress tracking API integration

**Server Options:**

```powershell
# Start with defaults (Docsify on 8080, Progress API on 3002)
npm run docs

# Or run the PowerShell script directly with custom options
pwsh ./scripts/Serve-Docs.ps1 -DocsPort 8080 -ProgressPort 3002

# Open browser to a specific section
pwsh ./scripts/Serve-Docs.ps1 -StartPage "learning/README"
```

### Testing Different Contexts

URL replacement is handled automatically based on the deployment environment:

- **Local Development**: URLs are replaced at runtime by the Docsify plugins
- **GitHub Pages**: URLs are replaced at build time by the GitHub workflow
- **Azure DevOps Wiki**: URLs are replaced at build time by the `Build-Wiki.ps1` script

To verify your documentation renders correctly, run `npm run docs` and check all links work as expected.

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
npm install
npm run docs

# Check port conflicts
# Docsify runs on port 8080, Progress API on port 3002
lsof -i :8080
lsof -i :3002
```

### Getting Help

- 🐛 [Report Documentation Issues]({{NEW_ISSUE_URL}})
- 💡 [Contributing Guidelines](../contributing/README.md)

## Scripts Reference

### Available Scripts

| Script                    | Description                                                           | Usage             |
|---------------------------|-----------------------------------------------------------------------|-------------------|
| `npm run docs`            | Start Docsify (8080) and Progress API (3002) servers                  | Local development |
| `npm run progress-server` | Start only the Progress API server                                    | API development   |
| `npm run mdlint`          | Run markdown linting                                                  | Quality assurance |
| `npm run mdlint-fix`      | Fix markdown linting issues automatically                             | Quality assurance |
| `scripts/Build-Wiki.ps1`  | Build Azure DevOps Wiki with URL replacement and navigation structure | CI/CD pipeline    |

## Configuration Files

### Essential Files

- `package.json` - npm scripts and dependencies
- `.env.example` - Environment variable templates for local development
- `.mega-linter.yml` - Documentation linting rules
- `.gitignore` - Excludes auto-generated configuration files

### Auto-Generated Files (Not in Git)

- `scripts/url-config.json` - Environment-specific URL mapping
- `docsify-url-config.js` - Runtime URL configuration for docs server
- `docs/_parts/*.md` - Section-specific navigation sidebars (dynamically loaded by navbar integration)

## Azure DevOps Wiki Build Process

### PowerShell Wiki Builder

The project uses `scripts/Build-Wiki.ps1` to build Azure DevOps Wiki documentation. This PowerShell script provides enhanced functionality with comprehensive content coverage across all documentation areas:

**Key Features:**

- **Comprehensive Content Coverage**: Includes all documentation from multiple areas:
  - Main documentation from `docs/` directory following section-specific sidebar navigation
  - Blueprint documentation from `blueprints/*/README.md` files
  - GitHub resources from `.github/prompts/`, `.github/chatmodes/`, `.github/instructions/`
  - AI Assistant guides from `copilot/` folder
  - Learning platform materials from `learning/` folder
- **Section-Specific Navigation**: Parses section-specific `docs/_parts/*.md` files to recreate hierarchical folder structure organized by documentation section (Documentation, Learning, Blueprints, Infrastructure, GitHub Copilot)
- **Azure DevOps Integration**: Generates `.order` files for proper wiki navigation across all sections
- **URL Token Replacement**: Automatically replaces URL tokens with Azure DevOps-specific URLs
- **Dynamic Content Organization**: Creates dedicated wiki sections following the new navbar-based content organization

### Build Process

```powershell
# Run the wiki build locally (requires PowerShell)
pwsh scripts/Build-Wiki.ps1
```

This creates a `.wiki` folder with comprehensive documentation coverage including:

- **Complete documentation** from docs/ folder following section-specific sidebar navigation
- **Blueprint documentation** organized by framework (terraform/bicep)
- **GitHub resources section** with prompts, chatmodes, and instructions
- **Copilot guides section** with AI assistant conventions and instructions
- **Learning section** with training materials and learning resources
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
├── infrastructure/                  # Infrastructure content
│   ├── .order                      # Infrastructure navigation
│   ├── terraform/                  # All terraform docs
│   ├── bicep/                      # All bicep docs
│   └── *.md                        # Other infrastructure docs
├── copilot-guides/                  # AI Assistant guides
│   ├── .order                      # Copilot navigation
│   └── *.md                        # Copilot conventions and instructions
├── learning/                      # Learning platform
│   ├── .order                      # Learning navigation
│   └── *.md                        # Training materials and resources
└── github-resources/                # GitHub resources
    ├── .order                      # GitHub resources navigation
    └── *.md                        # Prompts, chatmodes, instructions
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

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

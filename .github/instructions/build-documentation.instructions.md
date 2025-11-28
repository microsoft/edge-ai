---
applyTo: 'docs/build-cicd/**/*.md'
description: 'Required instructions for build and CI/CD documentation including mandatory troubleshooting sections, H2/H3 hierarchy enforcement, and code example formatting standards - Brought to you by microsoft/edge-ai'
---
# Build Documentation Instructions

These instructions define the content standards enforced for build and CI/CD documentation in this codebase. Follow them when creating or updating any documentation in `docs/build-cicd/`.

## Scope

- **Applies to**: All Markdown files under `docs/build-cicd/` directory
- **Purpose**: Enforce technical reference documentation standards for CI/CD pipelines, build automation, and deployment processes
- **Document types**: How-to guides (`ms.topic: how-to-guide`), concepts (`ms.topic: concept`), reference (`ms.topic: reference`)
- **Exceptions**: README.md files may have simplified structure for index pages

## **HIGHEST PRIORITY**

**Troubleshooting sections are MANDATORY**:

- Every build documentation file MUST include a comprehensive "## Troubleshooting" section
- Use "Symptoms → Solutions" format with clear problem descriptions and actionable fixes
- Include "### Debugging Commands" subsection with diagnostic commands

**Related Documentation section is MANDATORY**:

- Every build documentation file MUST end with "## Related Documentation" section
- Provide links to related build docs, external resources, and reference documentation

**Critical validation requirements**:

- YAML frontmatter MUST include all required fields (title, description, author, ms.date, ms.topic, keywords, estimated_reading_time)
- Document MUST follow H2/H3 hierarchy (no H1 in body, no H4+ headers except troubleshooting issues)
- Code examples MUST use correct language tags (bash, powershell, yaml)
- All internal links MUST use relative paths with `./` prefix

## Document Structure

### Required YAML Frontmatter

All build documentation MUST include YAML frontmatter with these fields:

```yaml
---
title: Document Title (appears as page H1)
description: Clear description of document scope
author: Edge AI Team
ms.date: MM/DD/YYYY
ms.topic: [how-to-guide|concept|reference]
keywords:
  - keyword1
  - keyword2
  - keyword3
estimated_reading_time: [integer minutes]
---
```

**Field requirements**:

- `title`: Document title (will be rendered as H1, do not repeat as `# Title` in body)
- `description`: Single sentence or brief paragraph explaining document purpose
- `author`: Team or individual attribution
- `ms.date`: Date in MM/DD/YYYY format (update when making significant changes)
- `ms.topic`: Content classification matching document type
- `keywords`: Array of 3-10 relevant keywords for search and discovery
- `estimated_reading_time`: Integer representing minutes to read (no units in value)

### Standard Document Opening

After YAML frontmatter, begin with document title as H2 and overview:

````markdown
## [Document Title] (repeats YAML title for body heading)

[Opening paragraph explaining document purpose and scope]

**Example navigation pattern** (with placeholder anchors):

```markdown
## In this guide

- [Link to major section](#anchor)
- [Link to major section](#anchor)
- [Link to major section](#anchor)
```

## Overview

[2-3 paragraphs explaining the technology, tool, or process]
````

**Pattern notes**:

- YAML `title` renders as page H1 (metadata-level title)
- First body heading H2 **repeats** the YAML title (e.g., if YAML has `title: Security Scanning Guide`, body starts with `## Security Scanning Guide`)
- "In this guide" section is optional but recommended for longer documents - provides navigation with links to major H2 sections
- Overview provides context before diving into details

## Header Hierarchy Standards

Build documentation STRICTLY follows H2/H3 hierarchy with NO H1 except YAML title:

<!-- <build-docs-header-hierarchy> -->
```markdown
---
title: Document Title (appears as page H1)
---

## Major Section (H2)

Content explaining the major section...

### Subsection (H3)

Detailed content for subsection...

### Another Subsection (H3)

More detailed content...

## Another Major Section (H2)

Content for next major section...

### Subsection Under Major Section (H3)

Subsection content...
```
<!-- </build-docs-header-hierarchy> -->

**Rules**:

- **NO H1 headers** in document body (YAML `title` serves as H1)
- **H2 headers** for major sections
- **H3 headers** for subsections under H2
- **NO H4+ headers** - keep hierarchy shallow for technical reference docs
  - **Exception**: H4 headers are permitted in "## Troubleshooting" sections for specific issue categories (see troubleshooting pattern)
- All headers must be descriptive and action-oriented ("Getting started", "Configure pipeline", "Troubleshooting builds")

## Standard Section Patterns

### Navigation Pattern

Start documents with navigation to major sections.

**Example navigation pattern** (with placeholder anchors):

<!-- <build-docs-navigation-pattern> -->
```markdown
**Example pattern** (with placeholder anchors):

<!-- markdownlint-disable MD042 -->
```markdown
**Example pattern** (with placeholder anchors):

```markdown
- [Overview](#overview)
- [Getting started](#getting-started)
- [Troubleshooting](#troubleshooting)
- [Related Documentation](#related-documentation)
```

```markdown
<!-- markdownlint-enable MD042 -->
```
<!-- </build-docs-navigation-pattern> -->

**Usage**: Bulleted links to H2 sections using kebab-case anchors

### Overview Section (First Content Section)

<!-- <build-docs-overview-pattern> -->
```markdown
## Overview

[2-3 paragraphs explaining the technology, tool, or process]

[Optional: Add H3 subsections for detailed breakdown]

### Key Features

- **Feature 1**: Description
- **Feature 2**: Description

### Integration Points

[Description of how this integrates with other systems]
```
<!-- </build-docs-overview-pattern> -->

**Purpose**: Establish context and scope before procedural content

### Prerequisites Section

<!-- <build-docs-prerequisites-pattern> -->
```markdown
## Getting started

### Prerequisites

1. **Requirement 1**: Description and link to setup instructions
2. **Requirement 2**: Description and link to setup instructions
3. **Requirement 3**: Description and link to setup instructions

### Setup Steps

[Step-by-step instructions with code examples]
```
<!-- </build-docs-prerequisites-pattern> -->

**Format**: Numbered list with bold requirement names, descriptions, and links to relevant documentation

## Code Example Standards

### Shell/Bash Commands

Use `bash` language tag for shell commands with descriptive comments:

<!-- <build-docs-shell-examples> -->
```bash
# Single command with descriptive comment
./scripts/tf-docs-check.sh

# Multi-line command with flags
./scripts/Run-Checkov.ps1 -Path "src/" -Framework "terraform"

# Command with output redirection
checkov -f src/main.tf --output sarif > results.sarif
```
<!-- </build-docs-shell-examples> -->

**Conventions**:

- Use `bash` language tag even for generic shell commands
- Include descriptive comment before each command or command group
- Show realistic command invocations with actual paths and flags
- Do NOT include shell prompts (dollar sign or hash) - keep commands copy-pasteable

### PowerShell Commands

Use `powershell` language tag for PowerShell scripts:

<!-- <build-docs-powershell-examples> -->
```powershell
# PowerShell script execution
./scripts/Bicep-Var-Compliance-Check.ps1

# PowerShell with parameters
./scripts/Run-Checkov.ps1 -Path "src/" -Verbose

# PowerShell pipeline
Get-ChildItem -Path "src/" -Recurse -Filter "*.tf" | ForEach-Object { terraform fmt $_.FullName }
```
<!-- </build-docs-powershell-examples> -->

**Conventions**:

- Use `powershell` language tag (not `ps1` or `pwsh`)
- Show parameter syntax with hyphens (`-Parameter`)
- Include pipeline examples where relevant

### YAML Configuration (Workflows/Pipelines)

Use `yaml` language tag for workflow and pipeline configurations:

<!-- <build-docs-yaml-examples> -->
```yaml
# GitHub Actions workflow snippet
- name: Infrastructure Security Scan
  run: |
    ./scripts/Run-Checkov.ps1 -Path "src/" -Output "sarif"

- name: Upload Security Results
  uses: github/codeql-action/upload-sarif@v2
  with:
    sarif_file: checkov-results.sarif
```
<!-- </build-docs-yaml-examples> -->

**Conventions**:

- Use `yaml` language tag (not `yml`)
- Include context comments for complex configurations
- Show complete step definitions, not fragments
- Use realistic paths and parameter values

### Inline Code and Paths

Use backticks for inline commands, file paths, parameter names, and configuration values:

**Examples**:

- "Run `./scripts/tf-docs-check.sh` to validate Terraform documentation"
- "Located in `.azdo/templates/` directory"
- "Set `--audit-level=moderate` flag for standard security checks"
- "The `ARM_SUBSCRIPTION_ID` environment variable must be set"

## Troubleshooting Section (MANDATORY)

Every build documentation file MUST include a comprehensive troubleshooting section using this structure:

<!-- <build-docs-troubleshooting-pattern> -->
```markdown
## Troubleshooting

### Common Issues

#### Authentication Failures

**Symptoms**: Pipeline fails with "unauthorized" or "forbidden" errors

**Solutions**:

- Verify service connection credentials are current and have required permissions
- Check that managed identity has appropriate RBAC roles assigned
- Confirm subscription ID matches expected deployment target
- Review Azure AD token expiration and refresh policies

#### Dependency Resolution Errors

**Symptoms**: Build fails with "package not found" or "version conflict" errors

**Solutions**:

- Clear local cache: `npm clean-install` or `pip install --no-cache-dir`
- Verify package registry is accessible from build agent
- Check for version conflicts in lock files (`package-lock.json`, `requirements.txt`)
- Update dependencies to compatible versions using `npm update` or `pip install --upgrade`

### Debugging Commands

Use these commands to diagnose build issues:

```bash
# Verify Azure authentication
az account show

# Check Terraform state
terraform show

# Validate pipeline YAML syntax
az pipelines validate --path azure-pipelines.yml

# Test script locally with verbose output
./scripts/script-name.sh --verbose --dry-run
```
<!-- </build-docs-troubleshooting-pattern> -->

**Required structure**:

- **H2 section**: "## Troubleshooting"
- **H3 subsection**: "### Common Issues" with H4 categories
- **Symptoms → Solutions format**: Each issue has "**Symptoms**:" and "**Solutions**:" subsections
- **H3 subsection**: "### Debugging Commands" with actual diagnostic commands
- **Actionable solutions**: Provide specific commands and steps, not vague advice

## Best Practices Section

Include a best practices section with actionable recommendations:

<!-- <build-docs-best-practices-pattern> -->
```markdown
## Best Practices

- **Practice 1**: Explanation and rationale with specific guidance
- **Practice 2**: Explanation and rationale with specific guidance
- **Practice 3**: Explanation and rationale with specific guidance
- **Practice 4**: Explanation and rationale with specific guidance
```
<!-- </build-docs-best-practices-pattern> -->

**Format**: Bulleted list with bold practice names, explanations, and rationale

## Related Documentation Section (MANDATORY)

Every build documentation file MUST end with related documentation links.

**Example pattern** (with placeholder paths):

<!-- <build-docs-related-links-pattern> -->
```markdown
**Example pattern** (with placeholder path):

```markdown
## Related Documentation

- [Document Title](relative-path.md) - Brief description of how this relates
- [Document Title](relative-path.md) - Brief description of how this relates
```

- [External Resource](https://example.com) - Brief description

<!-- Reference Links -->

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
```markdown
<!-- </build-docs-related-links-pattern> -->

**Required elements**:
- **H2 section**: "## Related Documentation"
- **Internal links**: Use relative paths (`./related-doc.md`) with brief descriptions
- **External links**: Include official documentation, tools, specifications
- **Reference links**: Group external URL references before footer
- **Standard footer**: AI-generated content attribution with markdownlint disable comments

## Cross-Reference Linking Patterns

### Internal Links (Same Directory)

Use relative paths with `./` prefix for links within `docs/build-cicd/`.

**Example pattern**:

```markdown
**Example pattern** (with placeholder paths):

```markdown
See [GitHub Actions Workflows](./github-actions.md) for workflow details.

For security scanning configuration, reference [Security Scanning Guide](./security-scanning.md).
```

```markdown

### Reference-Style Links

Use reference-style for external links to keep content readable.

**When to use reference-style**:
- Long URLs that would break content flow
- URLs referenced multiple times in the document
- Grouping external sources improves readability and maintenance

**Example pattern**:

```markdown
Follow the [Azure DevOps documentation][azdo-service-connections] for setup.

Consult [Checkov documentation][checkov-tool] for rule configuration.

<!-- Reference Links -->
[azdo-service-connections]: https://learn.microsoft.com/azure/devops/pipelines/library/service-endpoints?view=azure-devops
[checkov-tool]: https://www.checkov.io/
```

### In-Page Anchor Links

Use kebab-case anchors matching H2 section titles.

**Example pattern**:

```markdown
## In this guide

- [Overview](#overview)
- [Getting started](#getting-started)
- [Troubleshooting](#troubleshooting)
- [Related Documentation](#related-documentation)
```

**Rules**:

- Anchors are lowercase with hyphens replacing spaces
- Match H2 section titles exactly (converted to kebab-case)

## Table Formatting Standards

Use tables for script references, configuration options, and feature comparisons:

<!-- <build-docs-table-pattern> -->
```markdown
| Script Name                    | Purpose                      | Location   |
|--------------------------------|------------------------------|------------|
| **tf-docs-check.sh**           | Validate Terraform docs      | `scripts/` |
| **Run-Checkov.ps1**            | Infrastructure security scan | `scripts/` |
| **Bicep-Var-Compliance-Check** | Check Bicep variable naming  | `scripts/` |
```
<!-- </build-docs-table-pattern> -->

**Conventions**:

- **Bold** important values in first column (script names, tool names)
- `Inline code` for file paths, commands, and configuration keys
- Left-align all columns
- Keep descriptions concise (single phrase or short sentence)

## Validation Checklist

Before finalizing any build documentation, ensure:

- [ ] YAML frontmatter includes all required fields (title, description, author, ms.date, ms.topic, keywords, estimated_reading_time)
- [ ] Document follows H2/H3 hierarchy (no H1 in body, no H4+)
- [ ] "In this guide" navigation links to major H2 sections
- [ ] Overview section establishes context
- [ ] Code examples use correct language tags (bash, powershell, yaml)
- [ ] **Troubleshooting section is present and comprehensive** (MANDATORY)
- [ ] Troubleshooting uses "Symptoms → Solutions" format
- [ ] "Debugging Commands" subsection included in troubleshooting
- [ ] Best Practices section provides actionable guidance
- [ ] **Related Documentation section is present** (MANDATORY)
- [ ] Standard AI-generated footer is included
- [ ] All internal links use relative paths with `./` prefix
- [ ] External links use reference-style at document bottom
- [ ] Tables use consistent formatting with bold emphasis and inline code

## References

- **Comprehensive example**: `docs/build-cicd/security-scanning.md` - Demonstrates YAML frontmatter, H2/H3 hierarchy, code examples, and troubleshooting patterns
- **Section ordering example**: `docs/build-cicd/github-actions.md` - Shows "In this guide" navigation, prerequisites, and reference tables
- **Additional examples**: `docs/build-cicd/build-scripts.md`, `docs/build-cicd/troubleshooting-builds.md`
- **Baseline standards**: `.github/instructions/markdown.instructions.md` - General markdown formatting conventions

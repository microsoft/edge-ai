---
title: Bicep Documentation Compliance Check Workflow
description: GitHub Actions workflow for validating documentation standards across Bicep modules
author: Edge AI Team
ms.date: 06/06/2025
ms.topic: concept
estimated_reading_time: 7
keywords:
  - bicep
  - documentation validation
  - compliance check
  - github-actions
  - workflow template
  - infrastructure as code
  - documentation standards
  - link validation
  - build automation
  - code quality
  - documentation sync
  - module documentation
---

## Overview

The Bicep Documentation Compliance Check workflow validates documentation standards across the codebase to ensure all Bicep modules are properly documented and that documentation stays in sync with code changes. This workflow helps maintain accurate and consistent documentation across the codebase, improving usability and reducing onboarding time for new contributors.

## Features

- Verifies that Bicep module documentation is current using a custom documentation generator
- Identifies and reports links containing language-specific paths (e.g., 'en-us') which may become outdated when documentation is updated for different languages
- Creates GitHub annotations for issues found
- Generates a summary report of findings
- Configurable failure behavior - can either raise warnings or fail the build

## Inputs

| Input         | Description                                          | Required | Default |
|---------------|------------------------------------------------------|----------|---------|
| `break_build` | Whether to fail the workflow on documentation issues | No       | `false` |

## Outputs

This workflow doesn't produce any output variables, but it:

- Creates GitHub annotations for any documentation issues found
- Adds warnings or errors to the workflow logs
- Generates a workflow summary of documentation checks performed

## Usage Examples

### Basic Validation (Warning Mode)

```yaml
name: Check Bicep Documentation
uses: ./.github/workflows/docs-check-bicep.yml
with:
  break_build: false
```

### Strict Validation (Fail on Issues)

```yaml
name: Validate Bicep Documentation
uses: ./.github/workflows/docs-check-bicep.yml
with:
  break_build: true
```

### Triggering Manually

The workflow can be triggered manually from the GitHub Actions tab with configurable parameters:

- Select the `Bicep Docs Check` workflow
- Click "Run workflow"
- Choose whether to break the build on documentation issues
- Click "Run workflow" again

## Implementation Details

The workflow performs two main checks:

1. **Bicep Documentation Freshness Check**:
   - Uses the `scripts/bicep-docs-check.sh` script to verify that auto-generated documentation for Bicep modules is current
   - If documentation is outdated, provides instructions on how to regenerate it using `scripts/update-all-bicep-docs.sh`

2. **Language Path Segments Check**:
   - Uses the `scripts/link-lang-check.py` script to detect URLs containing language-specific paths (e.g., 'en-us')
   - Reports any found issues with file and line number references
   - These language paths can become outdated when documentation is updated for different languages

## Workflow Steps

1. Check out the repository code
2. Set up Python 3.11 environment
3. Install required Python dependencies
4. Set up Azure CLI with Bicep support
5. Run Bicep documentation freshness check
6. Run link language path segment check
7. Report any issues found as annotations and in workflow summary

## Troubleshooting

### Common Issues

1. **"Bicep auto-gen documentation needs to be updated"**
   - **Solution**: Run `scripts/update-all-bicep-docs.sh` from the repository root, commit and push the changes

2. **"Found URLs with language path segments (en-us)"**
   - **Solution**: Update the URLs in your documentation to remove language-specific paths. For example, change:
     - `https://learn.microsoft.com/azure/documentation` to
     - `https://learn.microsoft.com/azure/documentation`

3. **"Error parsing output from link-lang-check.py script"**
   - **Solution**: Check that Python dependencies are correctly installed and that script permissions are set correctly

### Extending the Workflow

To enhance this workflow:

1. To add additional documentation checks:
   - Add new scripts to the `scripts/` directory
   - Add new steps to the workflow that execute these scripts
   - Ensure proper error handling and output is implemented

2. To modify validation criteria:
   - Edit the existing scripts in the `scripts/` directory to change what they check for

## Related Workflows

- [docs-check-terraform.yml](./docs-check-terraform.md): Similar workflow for Terraform documentation validation
- [megalinter.yml](./megalinter.md): General linting workflow that includes markdown validation

## Security Considerations

This workflow requires read-only access to the repository and doesn't handle any sensitive information.

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

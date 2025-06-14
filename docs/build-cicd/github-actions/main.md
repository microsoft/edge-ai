---
title: Main Branch CI/CD Workflow
description: GitHub Actions workflow for main branch continuous integration and deployment processes
author: Edge AI Team
ms.date: 06/06/2025
ms.topic: concept
estimated_reading_time: 7
keywords:
  - main-branch
  - ci-cd
  - continuous integration
  - continuous deployment
  - github-actions
  - codeql analysis
  - security scanning
  - megalinter
  - terraform
  - bicep
  - infrastructure as code
  - documentation validation
  - github pages
  - dependency scanning
  - code quality
  - vulnerability scanning
  - automated deployment
---
## Overview

The Main Branch CI/CD workflow is the primary continuous integration and deployment pipeline for the main branch of the repository. This workflow runs automatically when changes are pushed to the main branch, ensuring code quality and deploying documentation to GitHub Pages.

## Features

- Performs comprehensive security scanning with CodeQL analysis across multiple languages
- Runs MegaLinter for static code analysis across multiple languages and file formats
- Validates documentation standards for both Terraform and Bicep configurations
- Deploys documentation to GitHub Pages when documentation changes are detected
- Runs automated dependency scanning to identify security vulnerabilities
- Orchestrates multiple specialized workflows in a coordinated sequence

## Inputs

This workflow does not accept any inputs when triggered automatically. When manually triggered using `workflow_dispatch`, no additional parameters are required.

## Outputs

This workflow doesn't produce any direct output variables, but it generates the following:

- GitHub code scanning alerts for any security issues found
- Static analysis results via MegaLinter
- Documentation validation results
- Deployed GitHub Pages documentation site (on successful execution)

## Usage Examples

### Automatic Execution

The workflow is automatically triggered on pushes to the main branch and doesn't need manual invocation.

### Manual Execution

The workflow can also be triggered manually from the GitHub Actions tab:

1. Navigate to the "Actions" tab in the repository
2. Select the "Main Branch CI/CD" workflow
3. Click "Run workflow"
4. Select the branch (typically main)
5. Click "Run workflow"

## Implementation Details

The workflow consists of multiple jobs that run in a specific sequence:

1. **CodeQL Analysis**: Scans code for security vulnerabilities across JavaScript, Python, TypeScript, and C#
2. **Dependency Scan**: Analyzes project dependencies for known security issues
3. **MegaLinter**: Performs comprehensive linting and static analysis
4. **Terraform Documentation Check**: Validates Terraform documentation consistency
5. **Bicep Documentation Check**: Validates Bicep documentation consistency
6. **Deploy Pages**: Publishes documentation to GitHub Pages when changes are detected

## Workflow Steps

### CodeQL Analysis

1. Checks out the repository code
2. Initializes CodeQL for the specified language
3. Automatically builds the codebase
4. Performs CodeQL analysis for security vulnerabilities
5. Uploads results to GitHub Security tab

### Dependency Scan

1. Checks out the repository code
2. Performs dependency review for security vulnerabilities
3. Reports findings as GitHub annotations

### MegaLinter

Calls the reusable `megalinter.yml` workflow with these parameters:

- `validate_all_codebase: true` - Checks the entire codebase, not just changed files
- `github_comment_reporter: false` - Disables PR comment reporting (since this runs on the main branch)

### Terraform Documentation Check

Calls the reusable `docs-check-terraform.yml` workflow with:

- `break_build: false` - Warnings won't fail the workflow, but will be reported

### Bicep Documentation Check

Calls the reusable `docs-check-bicep.yml` workflow with:

- `break_build: false` - Warnings won't fail the workflow, but will be reported

### Deploy Pages

Calls the reusable `pages-deploy.yml` workflow with:

- `source_branch: main` - Deploys documentation from the main branch
- `deploy_environment: production` - Deploys to the production environment

## Troubleshooting

### Common Issues

1. **Failed CodeQL Analysis**:
   - **Solution**: Review security issues in the GitHub Security tab and fix identified vulnerabilities

2. **MegaLinter Failures**:
   - **Solution**: Check the MegaLinter report in the workflow artifacts for specific issues to fix

3. **Documentation Validation Issues**:
   - **Solution**: Use the documentation generation scripts (`update-all-terraform-docs.sh` or `update-all-bicep-docs.sh`) to regenerate documentation

4. **Pages Deployment Failed**:
   - **Solution**: Verify that the GitHub Pages source is correctly configured in the repository settings

### Extending the Workflow

To enhance this workflow:

1. To add additional validation steps:
   - Add new jobs after existing checks
   - Ensure proper dependencies between jobs using `needs: [job-name]`

2. To modify documentation deployment:
   - Edit parameters passed to the `pages-deploy.yml` workflow

## Related Workflows

- [pr-validation.yml](./pr-validation.md): Similar workflow that runs on pull requests
- [megalinter.yml](./megalinter.md): Linting workflow called by this workflow
- [docs-check-terraform.yml](./docs-check-terraform.md): Terraform documentation validation
- [docs-check-bicep.yml](./docs-check-bicep.md): Bicep documentation validation
- [pages-deploy.yml](./pages-deploy.md): GitHub Pages deployment workflow

## Security Considerations

This workflow requires specific permissions to function correctly:

- `security-events: write`: Required for CodeQL analysis
- `actions: read`: Required for workflow execution
- `contents: read`: Required for repository access

The workflow uses secrets inheritance (`secrets: inherit`) to pass repository secrets to called workflows.

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

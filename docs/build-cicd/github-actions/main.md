---
title: Main Branch CI/CD Workflow
description: GitHub Actions workflow for main branch continuous integration and deployment processes
author: Edge AI Team
ms.date: 2026-11-24
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

- Runs security scanning (`security-scan.yml`, workflow permissions, dangerous workflow, runner, and action pin provenance scans)
- Runs individual lint jobs for static code analysis across multiple languages and file formats
- Validates documentation standards for both Terraform and Bicep configurations
- Deploys documentation to GitHub Pages when documentation changes are detected
- Orchestrates multiple specialized workflows in a coordinated sequence

*(CodeQL static analysis runs in the dedicated `.github/workflows/codeql.yml` workflow across `javascript-typescript`, `python`, `csharp`, and `rust` on pushes to `main`, pull requests, and weekly schedules.)*

## Inputs

This workflow does not accept any inputs when triggered automatically. When manually triggered using `workflow_dispatch`, no additional parameters are required.

## Outputs

This workflow doesn't produce any direct output variables, but it generates the following:

- GitHub code scanning alerts for any security issues found
- Static analysis results via individual lint jobs
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

1. **Security Scans**: Runs Gitleaks, Grype, Secretlint (`security-scan.yml`), workflow permissions, dangerous workflow, runner label, and action pin provenance scans
2. **Lint Jobs**: Performs comprehensive linting and static analysis
3. **Terraform Documentation Check**: Validates Terraform documentation consistency
4. **Bicep Documentation Check**: Validates Bicep documentation consistency
5. **Deploy Pages**: Publishes documentation to GitHub Pages when changes are detected

## Workflow Steps

### Security Scans

1. Runs Gitleaks (full history on `main`, uploading SARIF under `category: gitleaks`), Grype (advisory), and Secretlint via `security-scan.yml`
2. Runs workflow permissions and workflow security scans and uploads SARIF to the GitHub Security tab

*(CodeQL static analysis is orchestrated separately in `.github/workflows/codeql.yml` so pushes to `main`, pull requests, and scheduled runs share one configuration and language matrix.)*

### Lint Jobs

Runs dedicated lint jobs for shell scripts, YAML, Python, PowerShell, Bicep, Terraform, documentation, and code quality analysis across the entire codebase.

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

1. **Failed Security Scan**:
   - **Solution**: Review findings in the workflow summary, uploaded SARIF artifacts, or the GitHub Security tab and resolve reported issues

2. **Lint Job Failures**:
   - **Solution**: Check the individual lint job logs in the workflow run for specific issues to fix

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
- [docs-check-terraform.yml](./templates/docs-check-terraform.md): Terraform documentation validation
- [docs-check-bicep.yml](./templates/docs-check-bicep.md): Bicep documentation validation
- [pages-deploy.yml](./templates/pages-deploy.md): GitHub Pages deployment workflow

## Security Considerations

This workflow declares a deny-all top-level `permissions: {}` baseline and grants minimum scopes per job, including:

- `security-events: write`: Required for SARIF uploads from security scan jobs
- `actions: read`: Required for workflow execution
- `contents: read`: Required for repository access

The workflow uses secrets inheritance (`secrets: inherit`) to pass repository secrets to called workflows.

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

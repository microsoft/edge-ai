---
title: GitHub Pull Pipeline
description: Azure DevOps pipeline configuration for GitHub pull request validation
  and testing workflows
author: Edge AI Team
ms.date: 06/06/2025
ms.topic: concept
estimated_reading_time: 7
keywords:
  - github pull
  - azure devops
  - pipeline automation
  - repository sync
  - github app
  - jwt authentication
  - pull request automation
  - branch management
  - repository mirroring
  - manual trigger
  - change detection
  - continuous integration
---
## Overview

This pipeline automates pulling content from GitHub repositories into Azure DevOps. It's designed to keep internal (Azure DevOps) and external (GitHub) versions of the repository in sync by fetching changes, creating branches, and opening pull requests when updates are available.

## Prerequisites

- GitHub App configured with appropriate permissions
- Variable group `ai-on-edge-secrets` containing:
- `github-app-private-key`: Private key for GitHub App authentication
- `github-app-client-id`: Client ID for the GitHub App
- `githubRepoUrl`: URL to the source GitHub repository (with `__token__` placeholder)
- `azdoRepoUrl`: URL to the target Azure DevOps repository

## Pipeline Triggers

- **Manual trigger only**: This pipeline must be run manually

## Pipeline Resources

- **Agent Pool**: `ai-on-edge-managed-pool`
- **VM Image**: `ubuntu-latest`

## Pipeline Structure

### Jobs

1. **GitHubPull**: Pulls changes from GitHub to Azure DevOps
   - Creates GitHub access token using JWT authentication
   - Clones the GitHub repository
   - Compares changes with Azure DevOps main branch
   - If changes exist:
     - Creates a new branch in Azure DevOps (named `github-{BuildId}`)
     - Opens a pull request in Azure DevOps

## Usage

1. Run the pipeline manually when you want to sync changes from GitHub to Azure DevOps
2. Monitor the pipeline for successful completion
3. If changes are detected, check Azure DevOps for the newly created branch and pull request
4. Review and merge the pull request to incorporate GitHub changes

## Authentication

This pipeline uses:

1. GitHub App authentication for accessing GitHub:
   - Creates a JWT token using the app's private key
   - Exchanges the JWT token for an installation token
2. System access token for Azure DevOps operations

## Notes

- The pipeline only creates a PR if it detects changes between the repositories
- The pull request will be titled "GitHub merge for branch github-{BuildId}"
- The pipeline depends on helper scripts in `scripts/github/` directory
- The pipeline force-pushes to create the branch in Azure DevOps

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

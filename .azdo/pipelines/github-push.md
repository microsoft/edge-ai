# GitHub Push Pipeline

## Overview

This pipeline automates pushing content from Azure DevOps repositories to GitHub. It's designed to keep internal (Azure DevOps) and external (GitHub) versions of the repository in sync by pushing changes, creating branches, and opening pull requests.

## Prerequisites

- GitHub App configured with appropriate permissions
- Variable group `ai-on-edge-secrets` containing:
  - `github-app-private-key`: Private key for GitHub App authentication
  - `github-app-client-id`: Client ID for the GitHub App
  - `githubRepoUrl`: URL to the target GitHub repository (with `__token__` placeholder)

## Pipeline Triggers

- **Manual trigger only**: This pipeline must be run manually

## Pipeline Resources

- **Agent Pool**: `ai-on-edge-managed-pool`
- **VM Image**: `ubuntu-latest`

## Pipeline Structure

### Jobs

1. **GitHubPush**: Pushes changes from Azure DevOps to GitHub
   - Creates GitHub access token using JWT authentication
   - Sets up Git remote pointing to GitHub
   - Pushes current branch to a new branch on GitHub (named `azdo-{BuildId}`)
   - Opens a pull request in GitHub

2. **Versioning**: Updates version based on Git tag (runs only on `feat/gh-push` branch)
   - Uses GitVersion to determine semantic version
   - Creates and pushes a Git tag with the version

## Usage

1. Run the pipeline manually when you want to sync changes from Azure DevOps to GitHub
2. Monitor the pipeline for successful completion
3. Check GitHub for the newly created branch and pull request

## Authentication

This pipeline uses GitHub App authentication:

1. Creates a JWT token using the app's private key
2. Exchanges the JWT token for an installation token
3. Uses the installation token to authenticate Git operations

## Notes

- The pipeline force-pushes to GitHub, overwriting the target branch if it exists
- The versioning job only runs when the source branch is `feat/gh-push`
- The pipeline depends on helper scripts in `scripts/github/` directory

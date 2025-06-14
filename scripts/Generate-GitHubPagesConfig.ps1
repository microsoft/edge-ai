#Requires -Version 7.0

<#
.SYNOPSIS
    Generate Docsify URL configuration for GitHub Pages deployment.

.DESCRIPTION
    Generates docsify-url-config.js for GitHub Pages deployment with proper URL token replacement.
    This script replaces local development URLs with GitHub Pages-specific URLs.

    The script creates a JavaScript configuration file that enables URL token replacement
    throughout the Docsify documentation site, allowing for seamless transitions between
    local development and GitHub Pages deployment environments.

.PARAMETER Development
    Generate configuration for local development environment instead of GitHub Pages.

.PARAMETER OutputPath
    Path where the configuration file will be written. Defaults to 'docsify-url-config.js' in current directory.

.PARAMETER Repository
    GitHub repository in format 'owner/repo'. Uses GITHUB_REPOSITORY environment variable if available.

.PARAMETER RepositoryOwner
    GitHub repository owner. Uses GITHUB_REPOSITORY_OWNER environment variable if available.

.PARAMETER RepositoryName
    GitHub repository name. Uses GITHUB_REPOSITORY_NAME environment variable if available.

.PARAMETER SourceBranch
    Source branch being deployed. Uses SOURCE_BRANCH environment variable or defaults to 'main'.

.PARAMETER Port
    Port number for local development server. Defaults to 8080.

.EXAMPLE
    .\Generate-GitHubPagesConfig.ps1
    Generates GitHub Pages configuration using environment variables.

.EXAMPLE
    .\Generate-GitHubPagesConfig.ps1 -Development
    Generates configuration for local development environment.

.EXAMPLE
    .\Generate-GitHubPagesConfig.ps1 -Development -Port 3000
    Generates configuration for local development on port 3000.

.EXAMPLE
    .\Generate-GitHubPagesConfig.ps1 -Repository "Microsoft/edge-ai" -SourceBranch "develop"
    Generates configuration with specific repository and branch.

.NOTES
    Environment variables used:
    - GITHUB_REPOSITORY: Full repository name (owner/repo)
    - GITHUB_REPOSITORY_OWNER: Repository owner
    - GITHUB_REPOSITORY_NAME: Repository name only
    - SOURCE_BRANCH: Branch being deployed (defaults to 'main')
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$Development,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = 'docsify-url-config.js',

    [Parameter(Mandatory = $false)]
    [string]$Repository = '',

    [Parameter(Mandatory = $false)]
    [string]$RepositoryOwner = '',

    [Parameter(Mandatory = $false)]
    [string]$RepositoryName = '',

    [Parameter(Mandatory = $false)]
    [string]$SourceBranch = '',

    [Parameter(Mandatory = $false)]
    [int]$Port = 8080
)

# Error handling
$ErrorActionPreference = 'Stop'

try {
    # Get environment variables with fallbacks
    if ([string]::IsNullOrEmpty($Repository)) {
        $Repository = $env:GITHUB_REPOSITORY
        if ([string]::IsNullOrEmpty($Repository)) {
            $Repository = 'Microsoft/edge-ai'
        }
    }

    if ([string]::IsNullOrEmpty($RepositoryOwner)) {
        $RepositoryOwner = $env:GITHUB_REPOSITORY_OWNER
        if ([string]::IsNullOrEmpty($RepositoryOwner)) {
            $RepositoryOwner = $Repository.Split('/')[0]
        }
    }

    if ([string]::IsNullOrEmpty($RepositoryName)) {
        $RepositoryName = $env:GITHUB_REPOSITORY_NAME
        if ([string]::IsNullOrEmpty($RepositoryName)) {
            $repositoryParts = $Repository.Split('/')
            if ($repositoryParts.Length -ge 2) {
                $RepositoryName = $repositoryParts[1]
            } else {
                $RepositoryName = 'edge-ai'
            }
        }
    }

    if ([string]::IsNullOrEmpty($SourceBranch)) {
        $SourceBranch = $env:SOURCE_BRANCH
        if ([string]::IsNullOrEmpty($SourceBranch)) {
            $SourceBranch = 'main'
        }
    }

    # Calculate URLs based on environment
    $context = if ($Development) { 'local' } else { 'github-pages' }

    if ($Development) {
        # Development URLs
        $repoUrl = "https://github.com/$Repository"
        $repoBaseUrl = "https://github.com/$Repository/blob/$SourceBranch"
        $docsBaseUrl = "http://localhost:$Port"
        $cloneUrl = "https://github.com/$Repository.git"
        $newIssueUrl = "https://github.com/$Repository/issues/new"
    } else {
        # GitHub Pages URLs
        $repoUrl = "https://github.com/$Repository"
        $repoBaseUrl = "https://github.com/$Repository/blob/$SourceBranch"
        $docsBaseUrl = "https://$RepositoryOwner.github.io/$RepositoryName"
        $cloneUrl = "https://github.com/$Repository.git"
        $newIssueUrl = "https://github.com/$Repository/issues/new"
    }

    # Generate timestamp
    $timestamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
    $environment = if ($Development) { 'Development' } else { 'GitHub Pages' }

    # Generate the configuration content
    $configContent = @"
// Auto-generated URL replacement configuration for $context
// Generated on: $timestamp
// Repository: $Repository
// Branch: $SourceBranch
// Environment: $environment
window.EDGE_AI_URL_CONFIG = {
  context: '$context',
  variables: {
    "REPO_URL": "$repoUrl",
    "REPO_BASE_URL": "$repoBaseUrl",
    "DOCS_BASE_URL": "$docsBaseUrl",
    "CLONE_URL": "$cloneUrl",
    "NEW_ISSUE_URL": "$newIssueUrl"
  }
};

// URL replacement function
window.replaceUrlTokens = function(text) {
  if (!text || !window.EDGE_AI_URL_CONFIG || !window.EDGE_AI_URL_CONFIG.variables) return text;

  let result = text;
  const variables = window.EDGE_AI_URL_CONFIG.variables;

  for (const [token, value] of Object.entries(variables)) {
    const tokenPattern = new RegExp('{{' + token + '}}', 'g');
    result = result.replace(tokenPattern, value);
  }

  return result;
};

// Docsify hook to replace URLs in rendered content
if (window.`$docsify) {
  window.`$docsify.plugins = window.`$docsify.plugins || [];
  window.`$docsify.plugins.push(function(hook) {
    hook.afterEach(function(html) {
      return window.replaceUrlTokens(html);
    });

    // Also handle markdown parsing to catch tokens in markdown before rendering
    hook.beforeEach(function(content) {
      return window.replaceUrlTokens(content);
    });
  });
}
"@

    # Write the configuration file
    Set-Content -Path $OutputPath -Value $configContent -Encoding UTF8

    # Success output
    Write-Host "✅ $environment URL configuration generated successfully" -ForegroundColor Green
    Write-Host "📁 Output file: $OutputPath" -ForegroundColor Cyan
    Write-Host "🔗 Configuration details:" -ForegroundColor Yellow
    Write-Host "   Environment: $environment" -ForegroundColor Gray
    Write-Host "   Repository: $Repository" -ForegroundColor Gray
    Write-Host "   Branch: $SourceBranch" -ForegroundColor Gray
    Write-Host "   Docs Base URL: $docsBaseUrl" -ForegroundColor Gray
    Write-Host "   Repo Base URL: $repoBaseUrl" -ForegroundColor Gray

} catch {
    Write-Error "❌ Failed to generate URL configuration: $($_.Exception.Message)"
    exit 1
}

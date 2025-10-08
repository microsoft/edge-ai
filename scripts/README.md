# Scripts Directory

This directory contains utility scripts used by both developers and the
Azure DevOps build system for managing and validating the project's IaC.

## Table of Contents

* [Scripts Directory](#scripts-directory)
  * [Table of Contents](#table-of-contents)
  * [Azure Environment Initialization Scripts](#azure-environment-initialization-scripts)
    * [az-sub-init.sh](#az-sub-initsh)
  * [Terraform Documentation and Validation Scripts](#terraform-documentation-and-validation-scripts)
    * [update-all-terraform-docs.sh](#update-all-terraform-docssh)
    * [tf-docs-check.sh](#tf-docs-checksh)
    * [tf-vars-compliance-check.py](#tf-vars-compliance-checkpy)
    * [tf-provider-version-check.sh](#tf-provider-version-checksh)
    * [install-terraform-docs.sh](#install-terraform-docssh)
    * [tf-walker.sh](#tf-walkersh)
    * [tf-walker-parallel.sh](#tf-walker-parallelsh)
  * [Bicep Documentation and Validation Scripts](#bicep-documentation-and-validation-scripts)
    * [generate-bicep-docs.py](#generate-bicep-docspy)
    * [update-all-bicep-docs.sh](#update-all-bicep-docssh)
    * [bicep-docs-check.sh](#bicep-docs-checksh)
    * [Bicep-Var-Compliance-Check.ps1](#bicep-var-compliance-checkps1)
  * [Security Scanning Scripts](#security-scanning-scripts)
    * [Detect-Folder-Changes.ps1](#detect-folder-changesps1)
    * [Run-Checkov.ps1](#run-checkovps1)
    * [Invoke-SecurityAnalysisWithWorkItems.ps1](#invoke-securityanalysiswithworkitemsps1)
  * [Security Hardening Scripts](#security-hardening-scripts)
    * [security/Initialize-HardenRunner.ps1](#securityinitialize-hardenrunnerps1)
    * [security/Monitor-EgressTraffic.ps1](#securitymonitor-egresstrafficps1)
    * [security/New-SecurityDashboard.ps1](#securitynew-securitydashboardps1)
    * [security/Invoke-OSSFScorecard.ps1](#securityinvoke-ossfscorecardps1)
    * [security/Test-DependencyPinning.ps1](#securitytest-dependencypinningps1)
    * [security/Test-SHAStaleness.ps1](#securitytest-shastalenessps1)
    * [security/Update-ActionSHAPinning.ps1](#securityupdate-actionshapinningps1)
    * [security/Update-DockerSHAPinning.ps1](#securityupdate-dockershapinningps1)
    * [security/Update-ShellScriptSHAPinning.ps1](#securityupdate-shellscriptshapinningps1)
  * [Azure IoT Operations Scripts](#azure-iot-operations-scripts)
    * [aio-version-checker.py](#aio-version-checkerpy)
  * [Blueprint Deployment Preparation Scripts](#blueprint-deployment-preparation-scripts)
    * [location-check.sh](#location-checksh)
  * [Documentation Generation and Serving Scripts](#documentation-generation-and-serving-scripts)
    * [Generate-DocsSidebar.ps1](#generate-docssidebarps1)
    * [Generate-GitHubPagesConfig.ps1](#generate-githubpagesconfigps1)
    * [Serve-Docs.ps1](#serve-docsps1)
    * [Invoke-DocsHealthCheck.ps1](#invoke-docshealthcheckps1)
  * [Documentation Validation Scripts](#documentation-validation-scripts)
    * [Validate-MarkdownFrontmatter.ps1](#validate-markdownfrontmatterps1)
    * [linting/Link-Lang-Check.ps1](#lintinglink-lang-checkps1)
    * [linting/Docs-Link-Check.ps1](#lintingdocs-link-checkps1)
    * [Fix-VisuallySimilarUnicode.ps1](#fix-visuallysimilarunicodeps1)
  * [Documentation Publishing Scripts](#documentation-publishing-scripts)
    * [Build-Wiki.ps1](#build-wikips1)
    * [wiki-build.sh (deprecated)](#wiki-buildsh-deprecated)
  * [GitHub Integration Scripts](#github-integration-scripts)
    * [github/create-pr.sh](#githubcreate-prsh)
    * [github/access-tokens-url.sh](#githubaccess-tokens-urlsh)
  * [Developer Tools Scripts](#developer-tools-scripts)
    * [dev-tools/Generate-PrReference.ps1](#dev-toolsgenerate-prreferenceps1)
    * [dev-tools/pr-ref-gen.sh](#dev-toolspr-ref-gensh)
    * [pr-diff-parser.py](#pr-diff-parserpy)
  * [Build System Scripts](#build-system-scripts)
    * [build/Build-Consistency-Check.ps1](#buildbuild-consistency-checkps1)
    * [build/detect-folder-changes.sh](#builddetect-folder-changessh)
  * [Community Analysis Scripts](#community-analysis-scripts)
    * [community/get-azure-devops-prs.ps1](#communityget-azure-devops-prsps1)
    * [community/modules/AzDO](#communitymodulesazdo)
  * [Container and Application Scripts](#container-and-application-scripts)
    * [docker-lint.sh](#docker-lintsh)
    * [tag-rust-components.sh](#tag-rust-componentssh)
    * [update-versions-in-gitops.sh](#update-versions-in-gitopssh)
  * [Microsoft Fabric Scripts](#microsoft-fabric-scripts)
    * [capture-fabric-definitions.sh](#capture-fabric-definitionssh)
  * [Test Framework Scripts](#test-framework-scripts)
    * [Invoke-Pester.ps1](#invoke-pesterps1)
  * [Error Handling](#error-handling)
  * [Build System Integration](#build-system-integration)

## Azure Environment Initialization Scripts

### az-sub-init.sh

Initializes Azure environment and sets subscription context for Terraform operations.

* **Usage**: `source ./scripts/az-sub-init.sh [--tenant your-tenant.onmicrosoft.com] [--help]`
* **Arguments**:
  * `--tenant`: Optional tenant ID or domain (e.g., contoso.onmicrosoft.com)
  * `--help`: Display help message
* **Returns**: Sets `ARM_SUBSCRIPTION_ID` environment variable for Terraform
* **Dependencies**: Azure CLI (`az`)
* **When to Use**: Must be run before any Terraform commands (`init`, `validate`, `plan`, `apply`)
* **Best Practice**:
  * Source the script (don't execute it) to export environment variables to current shell
  * Run once per terminal session before Terraform operations
  * Use with `--tenant` flag when working with multiple Azure AD tenants

The script performs these actions:

1. Checks if Azure CLI is logged in
2. Attempts login if not authenticated (with optional tenant specification)
3. Retrieves current subscription ID
4. Exports `ARM_SUBSCRIPTION_ID` environment variable

## Terraform Documentation and Validation Scripts

### update-all-terraform-docs.sh

Updates Terraform documentation across all modules.

* **Usage**: `./update-all-terraform-docs.sh`
* **Dependencies**: Requires terraform-docs to be installed (see `./install-terraform-docs.sh`)
* **Build Integration**: Called by tf-docs-check.sh during the DocsCheckTerraform job
* **When to Use**: After making changes to Terraform variable definitions or outputs
* **Best Practice**: Always run this script after making Terraform changes to keep documentation current

### tf-docs-check.sh

Verifies that Terraform documentation is up-to-date.

* **Usage**: `./tf-docs-check.sh`
* **Returns**: Boolean indicating if documentation needs updates
* **Build Integration**: Used by the [docs-check-terraform-template.yml](../.azdo/docs-check-terraform-template.yml) in the DocsCheckTerraform job
* **When to Use**: Before submitting PRs to ensure documentation matches code

### tf-vars-compliance-check.py

Validates Terraform variable definitions across modules for consistency.

* **Usage**:
  * Ensure `terraform-docs` is installed and available in PATH
  * Run `./tf-vars-compliance-check.py`
* **Returns**: JSON array of inconsistencies found in variable definitions
* **Build Integration**: Used by the [variable-compliance-terraform-template.yml](../.azdo/variable-compliance-terraform-template.yml) job
* **When to Use**: Run before submitting PRs to ensure variable consistency

### tf-provider-version-check.sh

Checks Terraform provider versions against latest available versions.

* **Usage**: `./tf-provider-version-check.sh [-a] [-f <folder_path>]`
* **Flags**:
  * `-a`: Run check on all Terraform folders under src/
  * `-f <folder_path>`: Run check on a specific folder path
* **Returns**: JSON array of provider version mismatches
* **Build Integration**: Used by the [cluster-test-terraform-template.yml](../.azdo/cluster-test-terraform-template.yml) job
* **When to Use**: Run periodically to check if your modules use current provider versions

### install-terraform-docs.sh

Installs the terraform-docs tool at a specific version.

* **Usage**: `./install-terraform-docs.sh [-v version] [-h]`
* **Flags**:
  * `-v version`: Specify terraform-docs version (default: v0.20.0)
  * `-h`: Display help message
* **Build Integration**: Used by the [docs-check-terraform-template.yml](../.azdo/docs-check-terraform-template.yml) in the DocsCheckTerraform job
* **When to Use**: When setting up a new development environment or updating the terraform-docs version

### tf-walker.sh

Walks through Terraform directories and executes commands sequentially.

* **Usage**: `./tf-walker.sh "command to execute" [need_auth]`
* **Arguments**:
  * Command string to execute in each Terraform directory
  * `need_auth`: Optional boolean (`true`/`false`) to authenticate with Azure before execution (default: `false`)
* **Returns**: Executes command in each Terraform directory found in `blueprints` and `src`
* **Dependencies**:
  * Bash shell
  * `az-sub-init.sh` (when `need_auth` is true)
* **When to Use**: For sequential execution of Terraform commands across all modules
* **Example**:

  ```bash
  # Initialize and validate all Terraform modules
  ./tf-walker.sh "terraform init; terraform validate" true

  # Format all Terraform files
  ./tf-walker.sh "terraform fmt"
  ```

### tf-walker-parallel.sh

Walks through Terraform directories and executes commands in parallel for improved performance.

* **Usage**: `./tf-walker-parallel.sh "command to execute" [out_folder] [need_auth] [max_jobs] [dir_filter]`
* **Arguments**:
  * Command string to execute in each Terraform directory
  * `out_folder`: Output folder for logs (default: `tf-walker-YYYYMMDD-HHMMSS`)
  * `need_auth`: Optional boolean to authenticate with Azure (default: `false`)
  * `max_jobs`: Maximum parallel jobs (default: `4`)
  * `dir_filter`: Optional directory filter (e.g., `ci` to only process CI directories)
* **Returns**: Executes command in parallel across Terraform directories, outputs logs to specified folder
* **Dependencies**:
  * Bash shell with `parallel` or `xargs` support
  * `az-sub-init.sh` (when `need_auth` is true)
* **When to Use**: For faster execution of Terraform commands across many modules
* **Best Practice**:
  * Use for read-only operations or operations that don't conflict
  * Adjust `max_jobs` based on system resources
  * Review individual log files in output folder for any failures
* **Example**:

  ```bash
  # Run Terraform tests in parallel (4 jobs)
  ./tf-walker-parallel.sh "terraform test" "test-run" true 4

  # Validate all CI configurations in parallel
  ./tf-walker-parallel.sh "terraform validate" "validation" true 4 ci
  ```

## Bicep Documentation and Validation Scripts

### generate-bicep-docs.py

Python script that generates standardized markdown documentation for Bicep modules by parsing ARM JSON output.

* **Usage**:
  * Run `pip install -r requirements.txt` (to install module dependencies)
  * Run `python3 generate-bicep-docs.py <arm_json_file> <output_md_file> [-t <template_file>] [-n <nesting_level>]`
* **Arguments**:
  * `arm_json_file`: Path to the ARM JSON file (compiled Bicep)
  * `output_md_file`: Path where the generated markdown documentation will be saved
  * `-t, --template-file`: Optional path to a custom Jinja2 template file (default: ./templates/bicep-docs-template.md.template)
  * `-n, --modules-nesting-level`: Optional maximum number of nested module levels to process (default: 1)
* **Example Usage**:

  ```sh
  # Basic usage with default template
  python generate-bicep-docs.py ./src/005-onboard-reqs/bicep/main.json ./src/005-onboard-reqs/README.md

  # Using a custom template
  python generate-bicep-docs.py ./src/005-onboard-reqs/bicep/main.json ./src/005-onboard-reqs/README.md -t ./templates/custom-template.md

  # Specifying nesting level for module processing
  python generate-bicep-docs.py ./src/005-onboard-reqs/bicep/main.json ./src/005-onboard-reqs/README.md -n 2
  ```

* **Dependencies**:
  * Python 3.x
  * Required packages: `jinja2` (for templating)
* **Build Integration**: Called by `update-all-bicep-docs.sh`
* **When to Use**: Typically not called directly, but used by update-all-bicep-docs.sh when regenerating documentation
* **Best Practice**:
  * When generating docs for complex Bicep modules, consider creating a custom Jinja2 template
  * Templates can be customized to highlight specific aspects of your modules (parameters, outputs, nested resources)

### update-all-bicep-docs.sh

Updates Bicep documentation across all components in the repository.

* **Usage**: `./update-all-bicep-docs.sh [directory1 directory2 ...]`
* **Dependencies**:
  * Azure CLI with Bicep extension
  * Python 3.x with `generate-bicep-docs.py` script and its dependencies installed
* **When to Use**: After making changes to Bicep modules to keep documentation current
* **Best Practice**: Run this script before submitting PRs that include Bicep changes to ensure documentation is up-to-date,
  also run `npm run mdlint-fix` to fix any markdown linting issues

### bicep-docs-check.sh

Verifies that Bicep documentation is up-to-date by comparing the current documentation with what would be generated.

* **Usage**: `./bicep-docs-check.sh`
* **Dependencies**:
  * Azure CLI with Bicep extension
  * Python 3.x with dependencies installed for generate-bicep-docs.py
* **Returns**: Exit code 0 if documentation is up-to-date, non-zero otherwise
* **Build Integration**: Used by the [docs-check-bicep-template.yml](../.azdo/docs-check-bicep-template.yml) in the DocsCheckBicep job
* **When to Use**: Before submitting PRs to ensure Bicep documentation matches the current state of Bicep modules
* **Best Practice**:
  * Run this script as part of your pre-commit workflow when changing Bicep files
  * If documentation is out of date, run `./update-all-bicep-docs.sh` to update it
  * Review generated documentation changes before committing to ensure they reflect your intended module changes

The script works by:

1. Running `update-all-bicep-docs.sh` to generate the latest documentation for `/src/*/bicep/` and `./blueprints/*/bicep/`
2. Comparing the generated documentation with the existing documentation
3. Reporting any differences found

### Bicep-Var-Compliance-Check.ps1

PowerShell script that validates Bicep parameter definitions across modules for consistency.

* **Usage**: `./Bicep-Var-Compliance-Check.ps1 [<path-to-src-directory>]`
* **Arguments**:
  * Optional path to source directory (default: `../src` and `../blueprints`)
* **Returns**: JSON array of inconsistencies found in parameter definitions
* **Build Integration**: Similar to `tf-vars-compliance-check.py` but for Bicep files
* **Dependencies**:
  * PowerShell 7.0+
  * Bicep PowerShell module (automatically installed if missing)
* **When to Use**: Before submitting PRs to ensure Bicep parameter consistency across modules
* **Best Practice**:
  * Run as part of pre-commit workflow when changing Bicep parameters
  * Review inconsistencies and align parameter definitions across modules
  * Ensure parameter names, types, and descriptions are consistent

The script performs these actions:

1. Scans all Bicep files in specified directories
2. Extracts parameter definitions including names, types, descriptions, and validation rules
3. Compares parameters with the same name across different files
4. Reports inconsistencies in types, descriptions, or validation rules
5. Generates structured JSON output with detailed inconsistency information

## Security Scanning Scripts

### Detect-Folder-Changes.ps1

PowerShell script that detects changes in repository folders and files, providing structured JSON output for security scanning.

* **Usage**:
  * Basic usage: `.\Detect-Folder-Changes.ps1`
  * Include all folders (not just changed): `.\Detect-Folder-Changes.ps1 -IncludeAllFolders`
  * Compare against a different branch: `.\Detect-Folder-Changes.ps1 -BaseBranch origin/develop`
  * Write output to file: `.\Detect-Folder-Changes.ps1 -OutputFile "folder-changes.json"`
* **Returns**: JSON structure identifying which components have been modified
* **Build Integration**: Typically piped into Run-Checkov.ps1 for security scanning
* **When to Use**: Before running security scans to focus the scan on changed components
* **Best Practice**:
  * Use with pipeline integration to only scan changed files in PRs
  * Use with -IncludeAllFolders for periodic full scans

The script detects:

* Changes in shell/PowerShell scripts in the subscription setup folder
* Terraform folders containing modified files
* Bicep folders containing modified files

### Run-Checkov.ps1

PowerShell script that runs Checkov security scanner on folders identified by Detect-Folder-Changes.ps1 and aggregates results.

* **Usage**:
  * Via pipeline: `.\Detect-Folder-Changes.ps1 | .\Run-Checkov.ps1`
  * With explicit JSON: `.\Run-Checkov.ps1 -InputJson $jsonData`
  * With custom output: `.\Run-Checkov.ps1 -OutputFolder "./security-reports" -OutputFile "security-results.xml"`
  * Using existing data: `.\Run-Checkov.ps1 -UseExistingData -OutputFolder "./checkov-results"`
* **Returns**: Path to the aggregated JUnit XML report file
* **Build Integration**:
  * npm script: `npm run checkov-changes` scans only changed folders
  * npm script: `npm run checkov-all` scans all folders
* **When to Use**: During development and in CI/CD pipelines to identify security issues in IaC
* **Dependencies**: Requires Checkov to be installed via pip
* **Best Practice**:
  * Run before committing changes to identify security issues early
  * Use the generated reports to track security posture over time

The script performs these actions:

1. Processes JSON output from Detect-Folder-Changes.ps1
2. Runs Checkov security scanner on identified folders
3. Aggregates results into a single JUnit XML file
4. Deduplicates redundant findings in the final report

### Invoke-SecurityAnalysisWithWorkItems.ps1

PowerShell script that orchestrates comprehensive security analysis workflow with Azure DevOps work item integration.

* **Usage**: `.\Invoke-SecurityAnalysisWithWorkItems.ps1 [-ConfigFile <path>] [-OutputFolder <path>] [-TargetComponents <json>] [-SeverityThreshold <level>] [-Project <name>] [-AreaPath <path>] [-IterationPath <path>] [-Interactive]`
* **Arguments**:
  * `-ConfigFile`: Path to Checkov config (default: `../.checkov.yml`)
  * `-OutputFolder`: Folder for reports (default: `./logs/checkov-security-analysis`)
  * `-TargetComponents`: JSON string or file specifying components to analyze
  * `-SeverityThreshold`: Minimum severity level (LOW, MEDIUM, HIGH, CRITICAL; default: HIGH)
  * `-Project`: Azure DevOps project name (default: `edge-ai`)
  * `-AreaPath`: Azure DevOps area path for work items
  * `-IterationPath`: Azure DevOps iteration path for work items
  * `-Interactive`: Enable interactive triage mode
* **Returns**: Security analysis report and work item planning files for Azure DevOps handoff
* **Build Integration**: Creates structured planning files for Azure DevOps work item creation
* **Dependencies**:
  * PowerShell 7.0+
  * Checkov security scanner
  * Run-Checkov.ps1 and Detect-Folder-Changes.ps1
* **Documentation**: See `docs/security-analysis-workflow.md` for full workflow details
* **When to Use**:
  * Running comprehensive security analysis on Kubernetes and Arc components
  * Preparing security findings for Azure DevOps work item tracking
  * Interactive triage of security issues before work item creation
* **Best Practice**:
  * Use `-Interactive` mode for manual review of critical findings
  * Set appropriate `-SeverityThreshold` based on project security requirements
  * Review generated planning files before Azure DevOps handoff

The script orchestrates these stages:

1. Executes Checkov security scanning using existing configuration
2. Parses JSON output to filter K8s/Arc-specific findings
3. Evaluates security findings by severity and criticality
4. Creates work item planning files following `.github/instructions/ado-wit-planning.instructions.md`
5. Generates handoff documentation for Azure DevOps work item creation workflow

## Security Hardening Scripts

### security/Initialize-HardenRunner.ps1

Initializes security hardening for CI/CD runners with cross-platform support.

* **Usage**: `./security/Initialize-HardenRunner.ps1 [-EnableEgressFilter] [-EnableEndpointMonitoring] [-AllowedEndpoints <list>] [-ConfigurationPath <path>]`
* **Arguments**:
  * `-EnableEgressFilter`: Enable network egress filtering
  * `-EnableEndpointMonitoring`: Enable endpoint monitoring
  * `-AllowedEndpoints`: Comma-separated list of allowed endpoints (default: `github.com,registry-1.docker.io,*.azurecr.io,packages.microsoft.com`)
  * `-ConfigurationPath`: Path to configuration file (default: `./security-hardening-config.json`)
* **Returns**: Configures runner security settings
* **Build Integration**: Can be integrated into Azure DevOps and GitHub Actions pipelines
* **When to Use**: At the start of CI/CD pipeline runs to harden runner security
* **Best Practice**: Use in combination with other security scripts for comprehensive hardening

### security/Monitor-EgressTraffic.ps1

Monitors and logs network egress traffic from CI/CD runners.

* **Usage**: `./security/Monitor-EgressTraffic.ps1`
* **Returns**: Network traffic logs and alerts for unauthorized connections
* **Build Integration**: Used in security monitoring workflows
* **When to Use**: During pipeline execution to track network access patterns

### security/New-SecurityDashboard.ps1

Generates security dashboard for CI/CD pipeline security metrics.

* **Usage**: `./security/New-SecurityDashboard.ps1`
* **Returns**: Security dashboard HTML or JSON report
* **Build Integration**: Post-pipeline reporting
* **When to Use**: For periodic security posture reporting

### security/Invoke-OSSFScorecard.ps1

Runs OSSF Scorecard security assessment on the repository.

* **Usage**: `./security/Invoke-OSSFScorecard.ps1`
* **Returns**: OSSF Scorecard assessment results
* **Build Integration**: Security compliance checking
* **When to Use**: Periodic security posture assessment against OSSF standards

### security/Test-DependencyPinning.ps1

Tests and validates dependency pinning in workflow files.

* **Usage**: `./security/Test-DependencyPinning.ps1`
* **Returns**: Report on unpinned dependencies
* **Build Integration**: Pre-commit and PR validation
* **When to Use**: Before committing changes to ensure dependencies are properly pinned

### security/Test-SHAStaleness.ps1

Checks for stale SHA pinnings in workflow files and dependencies.

* **Usage**: `./security/Test-SHAStaleness.ps1`
* **Returns**: Report on outdated SHA references
* **Build Integration**: Periodic maintenance workflows
* **When to Use**: Regular security maintenance to identify outdated pinned versions

### security/Update-ActionSHAPinning.ps1

Updates GitHub Actions to use SHA pinning for security.

* **Usage**: `./security/Update-ActionSHAPinning.ps1`
* **Returns**: Updated workflow files with SHA-pinned actions
* **Build Integration**: Automated security maintenance
* **When to Use**: When updating GitHub Actions security posture

### security/Update-DockerSHAPinning.ps1

Updates Docker image references to use SHA pinning.

* **Usage**: `./security/Update-DockerSHAPinning.ps1`
* **Returns**: Updated files with SHA-pinned Docker images
* **Build Integration**: Security hardening workflows
* **When to Use**: When securing Docker image references

### security/Update-ShellScriptSHAPinning.ps1

Updates shell script references to use SHA pinning for downloaded resources.

* **Usage**: `./security/Update-ShellScriptSHAPinning.ps1`
* **Returns**: Updated shell scripts with SHA-pinned references
* **Build Integration**: Security hardening workflows
* **When to Use**: When securing shell script dependencies

## Azure IoT Operations Scripts

### aio-version-checker.py

Validates Azure IoT Operations component versions against latest available.

* **Usage**: `python3 ./aio-version-checker.py [flags]`
* **Flags**:
* `--error-on-mismatch`: Exit with code 1 if mismatches are found
* `-v, --verbose`: Enable verbose logging
* `-t, --iac-type {terraform,bicep,all}`: Which IaC files to evaluate
* `--print-manifest-urls`: Print only the resolved enablement/instance manifest URLs as JSON and exit
* `--release-tag <tag>`: Resolve a specific release tag (e.g., `v1.2.36`)
* `--channel {stable,preview}`: When no tag provided, choose latest stable (default) or latest preview
* `--strict-latest`: Fail if the GitHub API call fails (no legacy fallback)
* `--require-asset-files`: Require JSONs to be present as release assets (no branch fallback)
* **Returns**: Compare mode outputs a JSON array of version differences; URL resolution mode outputs a JSON object with `enablement_url`, `instance_url`, and `meta`
* **Build Integration**: Used by the [aio-version-checker-template.yml](../docs/build-cicd/pipelines/azure-devops/templates/aio-version-checker-template.md) job
* **When to Use**: Periodically check that AIO components use the currently released versions, or resolve manifest URLs for other tooling
* **Dependencies**: Python packages `hcl2`, `requests`
* **Notes**:
  * Uses `GITHUB_TOKEN` or `GH_TOKEN` if set to reduce GitHub API rate limits, optional
  * Used by the `iotops-version-upgrade.prompt.md` Prompt to resolve manifest URLs for IoT Operations version upgrades

## Blueprint Deployment Preparation Scripts

### location-check.sh

Uses a chosen blueprint to crawl all referenced modules, create a list of deployed resources, and find the intersection of all resources' allowed Azure locations.

* **Usage**: `./location-check.sh`
* **Returns**: List of all blueprint resources and list of all possible locations for blueprint
* **When to use**: Optionally run to assist in choosing a location for blueprint deployment
* **Dependencies**: grep, sort, comm (all 3 should be standard tooling), az
* **Notes**: Only bicep deployment files are supported at current

## Documentation Generation and Serving Scripts

### Generate-DocsSidebar.ps1

Generates enhanced Docsify sidebar with Infrastructure Code documentation from src directory.

* **Usage**: `.\Generate-DocsSidebar.ps1 [-DocsPath <path>] [-SrcPath <path>] [-SidebarFile <file>] [-Section <name>] [-AllSections]`
* **Arguments**:
  * `-DocsPath`: Path to docs directory (default: `../docs`)
  * `-SrcPath`: Path to src directory (default: `../src`)
  * `-SidebarFile`: Output sidebar file (default: `_sidebar.md` in docs directory)
  * `-Section`: Generate sidebar for specific section (`all`, `docs`, `praxisworx`, `blueprints`, `infrastructure`)
  * `-AllSections`: Generate all section-specific sidebars at once
* **Returns**: Generated sidebar markdown file(s)
* **Dependencies**: PowerShell 7.0+
* **When to Use**: After adding new documentation or infrastructure components
* **Features**:
  * Enhanced main documentation with README.md ordering
  * Infrastructure Code sections for Terraform and Bicep
  * Component overview with cross-references
  * Multi-section navigation architecture support

### Generate-GitHubPagesConfig.ps1

Generates Docsify URL configuration for GitHub Pages deployment.

* **Usage**: `.\Generate-GitHubPagesConfig.ps1 [-Development] [-OutputPath <path>] [-Repository <owner/repo>] [-RepositoryOwner <owner>] [-RepositoryName <name>] [-SourceBranch <branch>] [-Port <number>]`
* **Arguments**:
  * `-Development`: Generate config for local development instead of GitHub Pages
  * `-OutputPath`: Where to write config file (default: `docsify-url-config.js`)
  * `-Repository`: GitHub repository in format `owner/repo`
  * `-RepositoryOwner`: GitHub repository owner
  * `-RepositoryName`: GitHub repository name
  * `-SourceBranch`: Source branch being deployed (default: `main`)
  * `-Port`: Port for local development server (default: `8080`)
* **Returns**: JavaScript configuration file for Docsify URL token replacement
* **Dependencies**: PowerShell 7.0+
* **When to Use**: Before deploying documentation to GitHub Pages
* **Features**:
  * URL token replacement throughout documentation
  * Seamless transitions between local development and GitHub Pages
  * Environment variable support for CI/CD integration

### Serve-Docs.ps1

Starts Docsify documentation server for local development.

* **Usage**: `.\Serve-Docs.ps1 [-Open] [-StartPage <page>]`
* **Arguments**:
  * `-Open`: Automatically open browser after server starts
  * `-StartPage`: Specify starting page/route (e.g., `praxisworx/`)
* **Returns**: Runs local documentation server on port 8080
* **Dependencies**:
  * PowerShell 7.0+
  * Docsify CLI (`npm install -g docsify-cli`)
* **When to Use**: During documentation development to preview changes
* **Example**:

  ```powershell
  # Start server
  .\Serve-Docs.ps1

  # Start server and open to specific section
  .\Serve-Docs.ps1 -Open -StartPage "praxisworx/"
  ```

### Invoke-DocsHealthCheck.ps1

Performs comprehensive health checks on deployed Docsify documentation site.

* **Usage**: `.\Invoke-DocsHealthCheck.ps1 -SiteUrl <url> [-Timeout <seconds>] [-OutputJson] [-UserAgent <string>]`
* **Arguments**:
  * `-SiteUrl`: Base URL of documentation site to check (required)
  * `-Timeout`: Request timeout in seconds (default: 10)
  * `-OutputJson`: Output detailed results in JSON format
  * `-UserAgent`: Custom User-Agent string (default: `EdgeAI-Docs-Health-Check/1.0`)
* **Returns**: Health check results and exit code (0 = pass, 1 = fail)
* **Dependencies**: PowerShell 7.0+
* **When to Use**:
  * In CI/CD pipelines after documentation deployment
  * For monitoring deployed documentation sites
* **Features**:
  * Site accessibility validation
  * Docsify configuration checks
  * URL replacement verification
  * Navigation functionality testing
  * Asset availability checks
  * Search functionality validation

## Documentation Validation Scripts

### Validate-MarkdownFrontmatter.ps1

Validates frontmatter consistency across markdown files in the repository.

* **Usage**: `.\Validate-MarkdownFrontmatter.ps1 [-Paths <paths>] [-Files <files>] [-WarningsAsErrors] [-ChangedFilesOnly] [-BaseBranch <branch>]`
* **Arguments**:
  * `-Paths`: Array of paths to validate (default: `docs`, `src`, `blueprints`, `praxisworx`, `.github`)
  * `-Files`: Specific files to validate
  * `-WarningsAsErrors`: Treat warnings as errors
  * `-ChangedFilesOnly`: Only validate changed files
  * `-BaseBranch`: Base branch for comparison (default: `origin/main`)
* **Returns**: Validation report with frontmatter issues
* **Dependencies**: PowerShell 7.0+
* **When to Use**: Before committing markdown documentation changes
* **Features**:
  * Required field validation
  * Date format validation
  * Content structure validation
  * Git-aware changed file detection

### linting/Link-Lang-Check.ps1

PowerShell script that finds and optionally fixes URLs with language path segments ('en-us').

* **Usage**:
  * Find links with language defaults only: `pwsh ./linting/Link-Lang-Check.ps1` (outputs JSON)
  * Find links with verbose output: `pwsh ./linting/Link-Lang-Check.ps1 -Verbose`
  * Fix links and remove 'en-us': `pwsh ./linting/Link-Lang-Check.ps1 -Fix`
  * Fix links with verbose output: `pwsh ./linting/Link-Lang-Check.ps1 -Fix -Verbose`
* **Returns**: JSON array of detected links with file paths and line numbers (in search mode)
* **Build Integration**:
  * Used by the [docs-check-terraform-template.yml](../.azdo/templates/docs-check-terraform-template.yml) in the DocsCheckTerraform job
  * Used by the [docs-check-bicep-template.yml](../.azdo/templates/docs-check-bicep-template.yml) in the DocsCheckBicep job
* **When to Use**: Run before submitting PRs to ensure links don't contain language-specific paths which can cause internationalization issues
* **Features**: Enhanced CI/CD logging support for Azure DevOps and GitHub Actions

### linting/Docs-Link-Check.ps1

Repository-aware wrapper for markdown-link-check with Docsify hash-route normalization.

* **Usage**: `.\linting\Docs-Link-Check.ps1 [-Path <paths>] [-ConfigPath <path>] [-Quiet]`
* **Arguments**:
  * `-Path`: Files or directories to scan (default: Docsify navigation sources)
  * `-ConfigPath`: Path to markdown-link-check config file
  * `-Quiet`: Suppress non-error output
* **Returns**: Link validation results
* **Dependencies**:
  * PowerShell 7.0+
  * markdown-link-check npm package
* **When to Use**: Before submitting PRs to validate documentation links
* **Features**:
  * Docsify hash-route normalization
  * Recursive directory scanning
  * Repository-specific configuration

### Fix-VisuallySimilarUnicode.ps1

Finds and replaces visually similar Unicode characters with ASCII equivalents.

* **Usage**: `.\Fix-VisuallySimilarUnicode.ps1 [-Path <paths>] [-Filter <pattern>] [-Include <patterns>] [-Exclude <patterns>] [-OutputOnly] [-Quiet]`
* **Arguments**:
  * `-Path`: Paths supporting PowerShell wildcards
  * `-Filter`: Provider-side filter (e.g., `*.md`)
  * `-Include`: Include patterns
  * `-Exclude`: Exclude patterns
  * `-ExcludeDirectories`: Directories to exclude (default: `node_modules`, `.git`, etc.)
  * `-OutputOnly`: Report violations without modifying files
  * `-NoColor`: Disable colored output
  * `-Extensions`: File extensions to scan (default: common code/doc extensions)
  * `-Quiet`: Suppress non-error output
* **Returns**: Report of violations (and fixes if not `-OutputOnly`)
* **Dependencies**: PowerShell 7.0+
* **When to Use**:
  * Before committing to detect non-ASCII look-alike characters
  * After copying content from documents, chats, or AI assistants
* **Best Practice**: Run in `-OutputOnly` mode first to review changes
* **Features**:
  * Detects curly quotes, special spaces, en/em dashes, ellipsis
  * Fixes files in-place or reports only
  * Performance-optimized filtering
  * Repository-aware exclusions

The script enforces strict ASCII-only policy for visually similar characters to avoid:

* Unreadable diffs
* Broken tooling
* Invisible whitespace bugs

## Documentation Publishing Scripts

### Build-Wiki.ps1

PowerShell script that generates Azure DevOps Wiki content from markdown files in the repository.
Parses the navigation structure from docs/_sidebar.md and includes comprehensive content coverage
from all documentation folders throughout the repository.

* **Usage**: `./Build-Wiki.ps1`
* **Features**:
  * Parses docs/_sidebar.md to extract complete 4-level navigation hierarchy
  * Creates wiki structure with proper directory hierarchy and .order files at every level
  * Includes standalone content from all documentation folders (.github/prompts, .github/chatmodes, .github/instructions, copilot/, praxisworx/)
  * Updates relative links to work correctly in the new wiki structure
  * Handles URL token replacement for Azure DevOps integration
  * Integrates blueprint documentation seamlessly
  * Provides comprehensive documentation coverage beyond just sidebar navigation
* **Content Areas**:
  * Main documentation from docs/ folder following sidebar navigation
  * Blueprint documentation from blueprints/*/README.md
  * GitHub resources including prompts, chatmodes, and instructions
  * AI Assistant guides from copilot/ folder
  * Learning platform materials from praxisworx/ folder
* **Build Integration**: Used by the [wiki-update-template.yml](../.azdo/wiki-update-template.yml) job to rebuild the Azure DevOps wiki
* **When to Use**: Generally only used by the build system after merges to main
* **Notes**: Creates a .wiki directory and organizes documentation to match the sidebar navigation exactly, with additional sections for comprehensive content coverage

### wiki-build.sh (deprecated)

Legacy bash script for generating wiki content. This script has been replaced by Build-Wiki.ps1.

* **Status**: Deprecated - Use Build-Wiki.ps1 instead
* **Legacy Usage**: `./wiki-build.sh`
* **Migration**: The Azure DevOps pipeline now calls Build-Wiki.ps1 directly using pwsh
* **Notes**: This script may be removed in future versions

## GitHub Integration Scripts

### github/create-pr.sh

Creates a pull request in GitHub from the Azure DevOps repository branch.

* **Usage**: `./github/create-pr.sh <token> <branch> <commitmsg>`
* **Arguments**:
  * `token`: GitHub access token with repository permissions
  * `branch`: Branch name to create the PR from
  * `commitmsg`: Commit message to use in the PR description
* **Build Integration**: Used for synchronization between Azure DevOps and GitHub repositories
* **When to Use**: When you need to mirror changes from Azure DevOps to GitHub

### github/access-tokens-url.sh

Gets the access tokens URL for a GitHub App installation.

* **Usage**: `./github/access-tokens-url.sh <jwt>`
* **Arguments**:
  * `jwt`: JSON Web Token for GitHub App authentication
* **Returns**: URL for obtaining access tokens
* **Build Integration**: Used in conjunction with create-pr.sh for GitHub integration
* **When to Use**: Part of the GitHub synchronization process, generally used by CI/CD

## Developer Tools Scripts

### dev-tools/Generate-PrReference.ps1

Generates Copilot PR reference XML using git history and diff data.

* **Usage**: `.\dev-tools\Generate-PrReference.ps1 [-BaseBranch <branch>] [-ExcludeMarkdownDiff]`
* **Arguments**:
  * `-BaseBranch`: Git branch for comparison (default: `main`)
  * `-ExcludeMarkdownDiff`: Excludes markdown files from diff output
* **Returns**: Creates `.copilot-tracking/pr/pr-reference.xml` in repository root
* **Dependencies**: PowerShell 7.0+, Git
* **When to Use**: Before PR creation to generate reference documentation for Copilot
* **Features**:
  * Mirrors behavior of `pr-ref-gen.sh`
  * Supports markdown exclusion
  * Git history integration

### dev-tools/pr-ref-gen.sh

Bash version of PR reference generation for Copilot.

* **Usage**: `./dev-tools/pr-ref-gen.sh`
* **Returns**: Creates `.copilot-tracking/pr/pr-reference.xml`
* **Dependencies**: Bash, Git
* **When to Use**: Alternative to Generate-PrReference.ps1 for bash environments

### pr-diff-parser.py

Parses Git-style diffs embedded in PR reference XML files.

* **Usage**: `./pr-diff-parser.py <xml_file> [--summary] [--hunk-range <start-end>] [--output-format <table|json>]`
* **Arguments**:
  * `xml_file`: Path to PR reference XML file
  * `--summary`: Generate summary of changes
  * `--hunk-range`: Return specific hunk range (e.g., `1-100`)
  * `--output-format`: Output format (`table` or `json`)
* **Returns**: Diff summaries or paged diff hunks
* **Dependencies**: Python 3.x
* **When to Use**: For analyzing large PR diffs in manageable chunks
* **Features**:
  * Aggregates file-level metadata
  * Supports paging for large diffs
  * Table and JSON output formats

## Build System Scripts

### build/Build-Consistency-Check.ps1

Analyzes Azure DevOps templates and GitHub workflow files for naming consistency.

* **Usage**: `.\build\Build-Consistency-Check.ps1 [-AzDoPath <path>] [-GitHubPath <path>] [-ExcludeFiles <files>] [-Report]`
* **Arguments**:
  * `-AzDoPath`: Path to Azure DevOps templates (default: `.azdo/templates`)
  * `-GitHubPath`: Path to GitHub workflows (default: `.github/workflows`)
  * `-ExcludeFiles`: Workflow filenames to exclude (default: `main.yml`, `pr-validation.yml`, etc.)
  * `-Report`: Generate detailed JSON report
* **Returns**: Console output with comparison results and optional JSON report
* **Dependencies**: PowerShell 7.0+
* **When to Use**: Ensuring CI/CD consistency between Azure DevOps and GitHub
* **Exit Codes**: 0 if consistent, 1 if inconsistencies found

### build/detect-folder-changes.sh

Bash version of folder change detection for build systems.

* **Usage**: `./build/detect-folder-changes.sh`
* **Returns**: JSON structure of changed folders
* **Dependencies**: Bash, Git
* **When to Use**: Alternative to Detect-Folder-Changes.ps1 for bash environments

## Community Analysis Scripts

### community/get-azure-devops-prs.ps1

PowerShell script for analyzing Azure DevOps pull request data and generating comprehensive reports.

* **Usage**: `./community/get-azure-devops-prs.ps1 [-Organization <string>] [-Project <string>] [-Repository <string>] [-ReportOutputPath <string>] [-UseExistingJsonData] [-JsonDataPath <string>]`
* **Arguments**:
  * `-Organization`: Azure DevOps organization name (default: "ai-at-the-edge-flagship-accelerator")
  * `-Project`: Azure DevOps project name (default: "edge-ai")
  * `-Repository`: Repository name to analyze (default: "edge-ai")
  * `-ReportOutputPath`: Directory to save reports (default: "./docs")
  * `-UseExistingJsonData`: Use existing JSON data instead of API call (switch)
  * `-JsonDataPath`: Path to JSON file for import/export (default: "./pr-data.json")
* **Returns**: Comprehensive markdown report with PR metrics and contribution analytics
* **Build Integration**: Can be used in pipelines to create periodic project reports
* **Dependencies**:
  * PowerShell 7.0+
  * Azure DevOps PAT
* **When to Use**: For analyzing team performance, contribution patterns, and development metrics

### community/modules/AzDO

Directory containing PowerShell modules used by the PR analysis script.

* **Key Module Files**:
  * `AzDO.psd1`: Main module manifest
  * `AzDO-Auth.psm1`: Authentication and security functions
  * `AzDO-API.psm1`: Core API interaction
  * `AzDO-DataCollection.psm1`: PR data collection
  * `AzDO-DataProcessing.psm1`: Metrics generation
  * `AzDO-Main.psm1`: Main workflow orchestration
  * `AzDO-ReportGeneration.psm1`: Report formatting
  * `AzDO-ReportTypes.psm1`: Report data structure definitions
  * `AzDO-Types.psm1`: Data structure type definitions
* **Build Integration**: Used by get-azure-devops-prs.ps1 as supporting libraries
* **When to Use**: Reference for extending the PR analysis functionality with custom metrics or reports

## Container and Application Scripts

### docker-lint.sh

Lints Dockerfiles using Hadolint for best practices and security.

* **Usage**: `./docker-lint.sh`
* **Returns**: Linting results for all Dockerfiles in the repository
* **Dependencies**:
  * Docker
  * Hadolint Docker image (`hadolint/hadolint:latest`)
* **When to Use**: Before committing Dockerfile changes to ensure best practices
* **Features**:
  * Automatically finds all Dockerfiles
  * Excludes `node_modules` and `.git` directories
  * Runs Hadolint with DL3018 rule ignored

### tag-rust-components.sh

Tags Rust components based on version in their Cargo.toml files.

* **Usage**: `./tag-rust-components.sh [-n] [-f] [-p] [components_dir]`
* **Arguments**:
  * `-n`: Dry run (print actions without creating tags)
  * `-f`: Force (replace existing local tags and force push)
  * `-p`: Push created tags to origin
  * `components_dir`: Directory containing Rust components (default: current directory)
* **Returns**: Creates git tags in format `<component-name>/<semver>`
* **Dependencies**: Bash, Git, Cargo/Rust
* **When to Use**: After releasing new versions of Rust components
* **Example**:

  ```bash
  # Dry run to preview tags
  ./tag-rust-components.sh -n

  # Create and push tags
  ./tag-rust-components.sh -p
  ```

### update-versions-in-gitops.sh

Updates kustomization.yaml image tags to latest semver tags from Azure Container Registry.

* **Usage**: `./update-versions-in-gitops.sh <environment> <ACR_NAME> <ACR_RESOURCE_GROUP> [repo_root] [environments_dir]`
* **Arguments**:
  * `environment`: Target environment name
  * `ACR_NAME`: Azure Container Registry name
  * `ACR_RESOURCE_GROUP`: Resource group containing the ACR
  * `repo_root`: Repository root path (default: `.`)
  * `environments_dir`: Environments directory (default: `environments`)
* **Returns**: Updates kustomization.yaml with latest image tags
* **Dependencies**:
  * Azure CLI (`az`)
  * grep, awk, sed
* **When to Use**: During GitOps deployment workflows to update image versions
* **Build Integration**: Part of continuous deployment pipelines

## Microsoft Fabric Scripts

### capture-fabric-definitions.sh

Captures Microsoft Fabric event stream definitions using the Fabric API.

* **Usage**: `export WORKSPACE_ID=<id> ITEM_ID=<id> [OUTPUT_DIR=<dir>] && ./capture-fabric-definitions.sh`
* **Environment Variables**:
  * `WORKSPACE_ID`: Fabric workspace ID (required)
  * `ITEM_ID`: Event stream item ID (required)
  * `OUTPUT_DIR`: Output directory (default: `out`)
* **Returns**: Event stream definitions saved to timestamped directory
* **Dependencies**:
  * Azure CLI (`az`)
  * curl, jq, base64
* **When to Use**: For backing up or analyzing Fabric event stream configurations
* **Features**:
  * Uses Azure CLI authentication
  * Decodes and saves all definition parts
  * Organized output with timestamps

## Test Framework Scripts

### Invoke-Pester.ps1

PowerShell script for running Pester tests on PowerShell code.

* **Usage**: `./Invoke-Pester.ps1 -Path <test_path> -OutputFile <results_file>`
* **Arguments**:
  * `-Path`: Path to the directory containing tests
  * `-OutputFile`: Path to output test results in NUnit XML format
* **Build Integration**: Used by the [resource-provider-pwsh-tests-template.yml](../.azdo/resource-provider-pwsh-tests-template.yml) for testing PowerShell scripts
* **When to Use**: When developing or testing PowerShell modules, particularly for resource provider scripts

## Error Handling

Most scripts follow these error handling practices:

1. Exit with code 0 on success
2. Exit with code 1 on failure
3. Output structured data (usually JSON) for integration with build pipelines
4. Include basic error messages to stdout/stderr

## Build System Integration

The following Azure DevOps pipeline templates depend on these scripts:

| Azure DevOps Template                                                                                                                       | Script Dependencies                                                           |
|---------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------|
| [docs-check-terraform-template.yml](../docs/build-cicd/pipelines/azure-devops/templates/docs-check-terraform-template.md)                   | install-terraform-docs.sh, tf-docs-check.sh, Link-Lang-Check.ps1 (PowerShell) |
| [aio-version-checker-template.yml](../docs/build-cicd/pipelines/azure-devops/templates/aio-version-checker-template.md)                     | aio-version-checker.py                                                        |
| [variable-compliance-terraform-template.yml](../docs/build-cicd/pipelines/azure-devops/templates/variable-compliance-terraform-template.md) | tf-vars-compliance-check.py                                                   |
| [cluster-test-terraform-template.yml](../docs/build-cicd/pipelines/azure-devops/templates/cluster-test-terraform-template.md)               | tf-provider-version-check.sh                                                  |
| [resource-provider-pwsh-tests-template.yml](../docs/build-cicd/pipelines/azure-devops/templates/resource-provider-pwsh-tests-template.md)   | Invoke-Pester.ps1                                                             |
| [wiki-update-template.yml](../docs/build-cicd/pipelines/azure-devops/templates/wiki-update-template.md)                                     | Build-Wiki.ps1                                                                |

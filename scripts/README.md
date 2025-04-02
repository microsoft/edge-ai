# Scripts Directory

This directory contains utility scripts used by both developers and the
Azure DevOps build system for managing and validating the project's IaC.

## Table of Contents

- [Scripts Directory](#scripts-directory)
  - [Table of Contents](#table-of-contents)
  - [Terraform Documentation and Validation Scripts](#terraform-documentation-and-validation-scripts)
    - [update-all-terraform-docs.sh](#update-all-terraform-docssh)
    - [tf-docs-check.sh](#tf-docs-checksh)
    - [tf-vars-compliance-check.py](#tf-vars-compliance-checkpy)
    - [tf-provider-version-check.sh](#tf-provider-version-checksh)
    - [install-terraform-docs.sh](#install-terraform-docssh)
  - [Bicep Documentation and Validation Scripts](#bicep-documentation-and-validation-scripts)
    - [generate-bicep-docs.py](#generate-bicep-docspy)
    - [update-all-bicep-docs.sh](#update-all-bicep-docssh)
  - [Azure IoT Operations Scripts](#azure-iot-operations-scripts)
    - [aio-version-checker.py](#aio-version-checkerpy)
  - [Documentation and Link Validation Scripts](#documentation-and-link-validation-scripts)
    - [link-lang-check.py](#link-lang-checkpy)
    - [wiki-build.sh](#wiki-buildsh)
  - [GitHub Integration Scripts](#github-integration-scripts)
    - [github/create-pr.sh](#githubcreate-prsh)
    - [github/access-tokens-url.sh](#githubaccess-tokens-urlsh)
  - [Test Framework Scripts](#test-framework-scripts)
    - [Invoke-Pester.ps1](#invoke-pesterps1)
  - [Error Handling](#error-handling)
  - [Build System Integration](#build-system-integration)

## Terraform Documentation and Validation Scripts

### update-all-terraform-docs.sh

Updates Terraform documentation across all modules.

- **Usage**: `./update-all-terraform-docs.sh`
- **Dependencies**: Requires terraform-docs to be installed (see `./install-terraform-docs.sh`)
- **Build Integration**: Called by tf-docs-check.sh during the DocsCheck job
- **When to Use**: After making changes to Terraform variable definitions or outputs
- **Best Practice**: Always run this script after making Terraform changes to keep documentation current

### tf-docs-check.sh

Verifies that Terraform documentation is up-to-date.

- **Usage**: `./tf-docs-check.sh`
- **Returns**: Boolean indicating if documentation needs updates
- **Build Integration**: Used by the [docs-check-terraform-template.yml](../.azdo/docs-check-terraform-template.yml) in the DocsCheck job
- **When to Use**: Before submitting PRs to ensure documentation matches code

### tf-vars-compliance-check.py

Validates Terraform variable definitions across modules for consistency.

- **Usage**:
  - Run `pip install -r requirements.txt` (to pick up the requests library)
  - Run `./tf-vars-compliance-check.py`
- **Returns**: JSON array of inconsistencies found in variable definitions
- **Build Integration**: Used by the [variable-compliance-terraform-template.yml](../.azdo/variable-compliance-terraform-template.yml) job
- **When to Use**: Run before submitting PRs to ensure variable consistency

### tf-provider-version-check.sh

Checks Terraform provider versions against latest available versions.

- **Usage**: `./tf-provider-version-check.sh [-a] [-f <folder_path>]`
- **Flags**:
  - `-a`: Run check on all Terraform folders under src/
  - `-f <folder_path>`: Run check on a specific folder path
- **Returns**: JSON array of provider version mismatches
- **Build Integration**: Used by the [cluster-test-terraform-template.yml](../.azdo/cluster-test-terraform-template.yml) job
- **When to Use**: Run periodically to check if your modules use current provider versions

### install-terraform-docs.sh

Installs the terraform-docs tool at a specific version.

- **Usage**: `./install-terraform-docs.sh [-v version] [-h]`
- **Flags**:
  - `-v version`: Specify terraform-docs version (default: v0.16.0)
  - `-h`: Display help message
- **Build Integration**: Used by the [docs-check-terraform-template.yml](../.azdo/docs-check-terraform-template.yml) in the DocsCheck job
- **When to Use**: When setting up a new development environment or updating the terraform-docs version

## Bicep Documentation and Validation Scripts

### generate-bicep-docs.py

Python script that generates standardized markdown documentation for Bicep modules by parsing ARM JSON output.

- **Usage**:
  - Run `pip install -r requirements.txt` (to install module `mdutils`)
  - Run `python3 generate-bicep-docs.py <arm_json_file> <output_md_file>`
- **Arguments**:
  - `arm_json_file`: Path to the ARM JSON file (compiled Bicep)
  - `output_md_file`: Path where the generated markdown documentation will be saved
  - `--modules-nesting-level`: Specify the nesting level for modules (default: 1)
- **Dependencies**:
  - Python 3.x
  - Install Python dependencies: `pip install -r requirements.txt`
- **Build Integration**: Called by update-all-bicep-docs.sh
- **When to Use**: Typically not called directly, but used by update-all-bicep-docs.sh when regenerating documentation

### update-all-bicep-docs.sh

Updates Bicep documentation across all components in the repository.

- **Usage**: `./update-all-bicep-docs.sh [directory1 directory2 ...]`
- **Dependencies**:
  - Azure CLI with Bicep extension
  - Python 3.x with `generate-bicep-docs.py` script
- **When to Use**: After making changes to Bicep modules to keep documentation current
- **Best Practice**: Run this script before submitting PRs that include Bicep changes to ensure documentation is up-to-date,
  also run `npm run mdlint-fix` to fix any markdown linting issues

## Azure IoT Operations Scripts

### aio-version-checker.py

Validates Azure IoT Operations component versions against latest available.

- **Usage**: `python3 ./aio-version-checker.py [--error-on-mismatch] [-v] [-t {terraform,bicep,both}]`
- **Flags**:
  - `--error-on-mismatch`: Exit with error code 1 if versions don't match
  - `-v, --verbose`: Enable verbose output
  - `-t, --iac-type {terraform,bicep,both}`: Type of IaC files to check
- **Returns**: JSON array of version differences between local and remote
- **Build Integration**: Used by the [aio-version-checker-template.yml](../.azdo/aio-version-checker-template.yml) job
- **When to Use**: Run periodically to check if AIO components use the currently released versions
- **Dependencies**: Requires Python packages: hcl2, requests

## Documentation and Link Validation Scripts

### link-lang-check.py

Finds and optionally fixes URLs with language path segments ('en-us').

- **Usage**:
  - Find links with language defaults only: `python3 link-lang-check.py` (outputs JSON)
  - Find links with verbose output: `python3 link-lang-check.py -v`
  - Fix links and remove 'en-us': `python3 link-lang-check.py -f`
  - Fix links with verbose output: `python3 link-lang-check.py -f -v`
- **Returns**: JSON array of detected links with file paths and line numbers (in search mode)
- **Build Integration**: Used by the [docs-check-terraform-template.yml](../.azdo/docs-check-terraform-template.yml) in the DocsCheck job
- **When to Use**: Run before submitting PRs to ensure links don't contain language-specific paths which can cause internationalization issues

### wiki-build.sh

Generates wiki content from markdown files in the repository.

- **Usage**: `./wiki-build.sh`
- **Build Integration**: Used by the [wiki-update-template.yml](../.azdo/wiki-update-template.yml) job to rebuild the Azure DevOps wiki
- **When to Use**: Generally only used by the build system after merges to main
- **Notes**: Creates a .wiki directory and organizes documentation for the Azure DevOps wiki

## GitHub Integration Scripts

### github/create-pr.sh

Creates a pull request in GitHub from the Azure DevOps repository branch.

- **Usage**: `./github/create-pr.sh <token> <branch> <commitmsg>`
- **Arguments**:
  - `token`: GitHub access token with repository permissions
  - `branch`: Branch name to create the PR from
  - `commitmsg`: Commit message to use in the PR description
- **Build Integration**: Used for synchronization between Azure DevOps and GitHub repositories
- **When to Use**: When you need to mirror changes from Azure DevOps to GitHub

### github/access-tokens-url.sh

Gets the access tokens URL for a GitHub App installation.

- **Usage**: `./github/access-tokens-url.sh <jwt>`
- **Arguments**:
  - `jwt`: JSON Web Token for GitHub App authentication
- **Returns**: URL for obtaining access tokens
- **Build Integration**: Used in conjunction with create-pr.sh for GitHub integration
- **When to Use**: Part of the GitHub synchronization process, generally used by CI/CD

## Test Framework Scripts

### Invoke-Pester.ps1

PowerShell script for running Pester tests on PowerShell code.

- **Usage**: `./Invoke-Pester.ps1 -Path <test_path> -OutputFile <results_file>`
- **Arguments**:
  - `-Path`: Path to the directory containing tests
  - `-OutputFile`: Path to output test results in NUnit XML format
- **Build Integration**: Used by the [resource-provider-pwsh-tests-template.yml](../.azdo/resource-provider-pwsh-tests-template.yml) for testing PowerShell scripts
- **When to Use**: When developing or testing PowerShell modules, particularly for resource provider scripts

## Error Handling

Most scripts follow these error handling practices:

1. Exit with code 0 on success
2. Exit with code 1 on failure
3. Output structured data (usually JSON) for integration with build pipelines
4. Include basic error messages to stdout/stderr

## Build System Integration

The following Azure DevOps pipeline templates depend on these scripts:

| Azure DevOps Template                                                                            | Script Dependencies                                             |
|--------------------------------------------------------------------------------------------------|-----------------------------------------------------------------|
| [docs-check-terraform-template.yml](../.azdo/docs-check-terraform-template.md)                   | install-terraform-docs.sh, tf-docs-check.sh, link-lang-check.py |
| [aio-version-checker-template.yml](../.azdo/aio-version-checker-template.md)                     | aio-version-checker.py                                          |
| [variable-compliance-terraform-template.yml](../.azdo/variable-compliance-terraform-template.md) | tf-vars-compliance-check.py                                     |
| [cluster-test-terraform-template.yml](../.azdo/cluster-test-terraform-template.md)               | tf-provider-version-check.sh                                    |
| [resource-provider-pwsh-tests-template.yml](../.azdo/resource-provider-pwsh-tests-template.md)   | Invoke-Pester.ps1                                               |
| [wiki-update-template.yml](../.azdo/wiki-update-template.md)                                     | wiki-build.sh                                                   |

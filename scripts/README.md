# Scripts Directory

This directory contains utility scripts used by both developers and the
Azure DevOps build system for managing and validating the project's IaC.

## Developer and Build System Scripts

### link-lang-check.py

Finds and optionally fixes URLs with language path segments ('en-us').

- **Usage**:
  - Find links with language defaults only: `python3 link-lang-check.py` (outputs JSON)
  - Find links with verbose output: `python3 link-lang-check.py -v`
  - Fix links and remove 'en-us': `python3 link-lang-check.py -f`
  - Fix links with verbose output: `python3 link-lang-check.py -f -v`
- **Returns**: JSON array of detected links with file paths and line numbers (in search mode)
- **Build Integration**: Used by DocsCheck job to detect links with language path segments and generate build warnings
- **When to Use**: Run before submitting PRs to ensure links don't contain language-specific paths which can cause internationalization issues

### tf-vars-compliance-check.sh

Validates terraform variable definitions across modules for consistency.

- **Usage**:
  - run `pip install -r requirements.tct` (to pick up the requests library)
  - run `./tf-vars-compliance-check.py`
- **Returns**: JSON array of inconsistencies found in variable definitions
- **Build Integration**: Used by TFVariableComplianceChecker job to enforce variable definition standards
- **When to Use**: Run before submitting PRs to ensure variable consistency

### tf-provider-version-check.sh

Checks terraform provider versions against latest available versions.

- **Usage**: `./tf-provider-version-check.sh [-a] [-f <folder_path>]`
- **Flags**:
  - `-a`: Run check on all terraform folders under src/
  - `-f <folder_path>`: Run check on a specific folder path
- **Returns**: JSON array of provider version mismatches
- **Build Integration**: Used by TerraformClusterTest job to detect outdated providers
- **When to Use**: Run periodically to check if your modules use current provider versions

### aio-version-checker.sh

Validates Azure IoT Operations component versions against latest available.

- **Usage**: `./aio-version-checker.sh`
- **Returns**: JSON array of version differences between local and remote
- **Build Integration**: Used by TfAIOVersionChecker job
- **When to Use**: Run periodically to check if AIO components use the currently released versions

### tf-docs-check.sh

Verifies that terraform documentation is up-to-date.

- **Usage**: `./tf-docs-check.sh`
- **Returns**: Boolean indicating if documentation needs updates
- **Build Integration**: Used by TerraformDocsCheck job

### wiki-build.sh

Generates wiki content from markdown files.

- **Usage**: `./wiki-build.sh`
- **Build Integration**: Used by WikiUpdate job to rebuild the Azure DevOps wiki based on merged to main documentation

### update-all-terraform-docs.sh

Updates terraform documentation across all modules.

- **Usage**: `./update-all-terraform-docs.sh`
- **When to Use**: After making changes to terraform variable definitions or outputs
- **Best Practice**: Always run this script after making terraform changes to keep documentation current

### Invoke-Pester.ps1

PowerShell script for running Pester tests.

- **Usage**: `./Invoke-Pester.ps1 -Path <test_path> -OutputFile <results_file>`
- **When to Use**: When developing or testing PowerShell modules or Bicep code

## Error Handling

Most scripts will:

1. Exit with code 0 on success
2. Exit with code 1 on failure
3. Output structured data (usually JSON) for integration with build pipelines
4. Include basic error messages to stdout/stderr

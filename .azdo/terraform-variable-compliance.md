# Terraform Variable Compliance Checking

This document explains the automated process used to ensure consistency in Terraform variable definitions across modules in the repository.

## Overview

The Terraform Variable Compliance Checker is designed to detect and report inconsistencies in variable definitions across Terraform modules. This ensures that variables with the same name have consistent descriptions, types, and default values across the codebase, maintaining high code quality and reducing confusion for contributing developers.

## Process Flow

1. The CI/CD pipeline runs the `TFVariableComplianceChecker` job on pull requests
2. The job executes the `tf-vars-compliance-check.py` script
3. The script analyzes all Terraform files in the repository looking for variable definitions
4. It identifies inconsistencies in variable attributes (descriptions, types, defaults)
5. Issues are reported as pipeline errors with details about the inconsistencies

## How the Variable Compliance Checker Works

### Variable Analysis

The `tf-vars-compliance-check.py` script performs a comprehensive analysis of Terraform variable definitions:

1. **Discovery Phase**:
   - Recursively locates all `.tf` files in the `/src` and `/blueprints` directories
   - Filters out test directories and `.terraform` directories
   - Uses `terraform-docs` to generate JSON metadata about each Terraform module
   - Parses the variable definations using the JSON generated docs

2. **Extraction Phase**:
   - Extracts variable definitions including:
     - Variable names
     - Descriptions
     - Default values
     - Type constraints
     - Validation rules

3. **Comparison Phase**:
   - Creates a database of all variables used across modules
   - For variables used in multiple modules, compares their definitions
   - Identifies inconsistencies in descriptions, types, defaults, or validation rules

4. **Reporting Phase**:
   - Generates structured JSON output listing all inconsistencies
   - For each inconsistent variable, includes:
     - The variable name
     - The directories where it's defined differently
     - The specific differences found

### Example Detection

The job calls the `tf-vars-compliance-check.py` script which produces an output like the following:

```json
{
  "variable_name": "example_variable",
  "directories": [
    "/src/module1",
    "/src/module2"
  ],
  "differences": {
    "description": [
      "Description in module1",
      "Description in module2"
    ],
    "type": [
      "string",
      "number"
    ]
  }
}
```

Each of these records will be used to generate a unique build warning per variable/per folder.

## The Azure DevOps YAML Pipeline Template

The `tf-variable-compliance-template.yml` file defines the Azure DevOps pipeline that runs the Terraform variable compliance checks.

### Pipeline Structure

The pipeline template is structured as follows:

```yaml
# Terraform Variable Compliance Check Template
parameters:
  # Dependencies for this job
  dependsOn: []
  # Display name for the job
  displayName: 'Terraform Variable Compliance Check'
  # Condition for when this job should run
  condition: 'succeeded()'
  # Version of terraform-docs to install
  terraformDocsVersion: 'v0.16.0'
  # Pool configuration
  pool:
    name: 'ai-on-edge-managed-pool'
    vmImage: 'ubuntu-latest'
```

### Key Components

1. **Parameter Definitions**:
   - `dependsOn`: Specifies job dependencies
   - `displayName`: The name displayed in the Azure DevOps pipeline UI
   - `condition`: The condition under which this job should run
   - `terraformDocsVersion`: The version of terraform-docs to use
   - `pool`: Configuration for the agent pool to use

2. **Jobs**:
   - The template defines a single job called `TFVariableComplianceChecker`
   - This job runs on the specified agent pool and executes the compliance checking script

3. **Steps**:
   - Checkout the repository
   - Check for newer versions of terraform-docs
   - Install terraform-docs with the specified version
   - Run the `tf-vars-compliance-check.py` script
   - Generate errors in the build log for any inconsistencies found

### Terraform-docs Version Checking

The pipeline includes an automatic version checking mechanism for terraform-docs:

1. **Version Detection**:
   - Fetches the latest available version from GitHub API
   - Compares it with the version specified in the pipeline parameters

2. **Warning Generation**:
   - Creates a build warning if a newer version is detected
   - The warning includes both the current and latest version numbers
   - Example: "A newer version of terraform-docs is available: v0.17.0 (currently using v0.16.0). Consider updating the terraformDocsVersion parameter."

3. **Version Handling**:
   - Continues to use the specified version for the current run, ensuring consistency
   - Does not automatically update to prevent unexpected behavior

4. **Updating Process**:
   - When a newer version is detected, update the `terraformDocsVersion` parameter in your pipeline configuration
   - Test the updated version in a feature branch before merging to main

This approach ensures that the team is aware of new terraform-docs releases while maintaining pipeline stability by continuing to use known working versions until explicitly updated.

### Pipeline Execution

The pipeline is designed to be included as a template in other Azure DevOps YAML pipelines:

```yaml
stages:
- stage: CodeQuality
  jobs:
  - template: /.azdo/tf-variable-compliance-template.yml
    parameters:
      workingDirectory: $(System.DefaultWorkingDirectory)
```

### Success Criteria

The pipeline succeeds if:

- All Terraform variables used across multiple modules have consistent definitions
- The script runs without errors

The pipeline warns if:

- It finds variables with the same name but different descriptions, types, defaults, or validation rules

### Fixing Issues

When inconsistencies are detected:

1. Review the build warnings showing inconsistent variable definitions
2. Determine the correct/canonical definition that should be used
3. Update all instances of the variable to match the canonical definition
4. Create/update the PR with these changes
5. Re-run the pipeline to confirm the inconsistencies are resolved

### Integration with CI/CD

This checker is typically:

- Run on pull requests to prevent inconsistencies from being merged
- Included in the PR validation pipeline

By maintaining consistent variable definitions across the codebase, the team ensures:

- Better reusability of modules
- Reduced confusion when working with multiple modules
- Cleaner, more maintainable infrastructure-as-code

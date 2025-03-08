# Matrix Build System for Terraform Testing

This document describes the automated Terraform build and testing process implemented in our Azure DevOps pipeline.

## Overview

Our pipeline uses a matrix build pattern to efficiently test Terraform code changes across multiple infrastructure components. The system detects which Terraform modules have changed in a pull request and dynamically creates build jobs only for affected modules.

## Process Flow

1. The pipeline detects changes in Terraform files within the source directory
2. It dynamically creates a build matrix with only the affected components
3. For each affected component, it runs Terraform initialization, validation, planning, and testing
4. Test results are published in JUnit XML format and displayed in Azure DevOps for the branch's build

## Change Detection

The `MatrixBuildFolderCheck` job scans for changes in Terraform files and creates a dynamic test matrix:

1. The job compares the current branch against the main branch to identify changed files
2. It filters for files with `.tf`, `.tfvars`, `.tfstate`, or `.hcl` extensions
3. The first-level directories containing these files are extracted (e.g., `010-vm-host`, `020-cncf-cluster`)
4. A JSON object is created for the build matrix, with each directory as a key

## Provider Version Checker

The pipeline includes a comprehensive provider version check system that ensures all Terraform providers are using the latest available versions. This is implemented through the `TfAIOVersionChecker` job and the `tf-provider-version-check.sh` script.

1. **Provider Detection**:
   - The script parses Terraform configuration files to identify all providers used in the module
   - It extracts the provider name and version from the provider blocks

2. **Version Verification**:
   - For each detected provider, the script queries the Terraform Registry API
   - It compares the specified version with the latest available version
   - It caches results to avoid repeated API calls for the same provider

3. **Reporting Mechanism**:
   - When outdated providers are detected, warnings are generated in the pipeline
   - Each warning includes:
     - The module path
     - The provider name
     - The current version being used
     - The latest available version

4. **Integration in the Pipeline**:
   - The `TerraformClusterTest` job runs this check for each changed module
   - Results are published as pipeline warnings to notify developers
   - Non-blocking: The build continues even if outdated providers are detected

## TerraformClusterTest Job

The `TerraformClusterTest` job is responsible for running tests on the affected Terraform modules. It performs the following steps:

1. Initializes the Terraform configuration for the module
2. Validates the Terraform configuration
3. Plans the Terraform deployment
4. Publishes the Terrform Plan to current build
5. Runs any terrform tests for that folder
6. Publishes test results in JUnit XML format for the pipeline report

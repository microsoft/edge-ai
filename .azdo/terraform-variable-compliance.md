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

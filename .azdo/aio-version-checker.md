# AIO Version Checker

This document explains the automated process used to ensure that the versions and trains of
Azure IoT Operations (AIO) components defined in the associated Terraform component
variables file [iot-ops](../src/040-iot-ops/terraform/variables.init.tf) are consistent with the latest versions available in the PG's manifest file.

## Overview

The AIO Version Checker is designed to detect and report inconsistencies in the versions
and trains of AIO components. This ensures that the infrastructure is using the latest
available versions and trains of the required components, and creates build warnings if they
are out of date.

## Process Flow

1. The CI/CD pipeline runs the `TfAIOVersionChecker` job on pull requests
2. The job executes the `aio-version-checker.sh` script
3. The script compares the local AIO Terraform variables file with the PG's manifest file
4. The script identifies inconsistencies in component versions and trains
5. Issues are reported as pipeline errors with details about the inconsistencies

> NOTE: there will likely be component name mismatches as the PG GA's components like the Secrets Sync Controller

## How the AIO Version Checker Works

### Version and Train Analysis

The `aio-version-checker.sh` script performs a comprehensive analysis of AIO component versions and trains:

1. **Dependency Check**:
   - Verifies that `jq` is installed and accessible in the system PATH

2. **Local Variables Extraction**:
   - Reads the local AIO Terraform variables file
   - Extracts variable blocks for each AIO component
   - Cleans up each variable block by removing the "type" object and control characters
   - Converts local variables to a JSON array of objects

3. **Remote JSON Fetching**:
   - Downloads the PG's manifest file from GitHub
   - Extracts version and train information for the specified AIO components

4. **Comparison Phase**:
   - Compares the local and remote versions and trains for each component
   - Identifies inconsistencies in versions and trains

5. **Reporting Phase**:
   - Generates structured JSON output listing all inconsistencies
   - For each inconsistent component, includes:
     - The component name
     - The local version and train
     - The remote version and train

### Example Detection

The script can detect issues such as:

- Component: `example-component`
  - Local Version: `1.0.0`
  - Remote Version: `1.1.0`
  - Local Train: `preview`
  - Remote Train: `stable`

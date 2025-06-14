---
title: Cluster Terraform Testing Workflow
description: GitHub Actions reusable workflow for validating Terraform configurations in cluster deployments
author: Edge AI Team
ms.date: 06/06/2025
ms.topic: concept
estimated_reading_time: 7
keywords:
  - terraform
  - cluster testing
  - infrastructure validation
  - terraform testing
  - github-actions
  - workflow template
  - terraform init
  - terraform validate
  - terraform plan
  - test deployment
  - documentation generation
  - infrastructure as code
  - deployment validation
---

A reusable workflow that validates Terraform configurations for cluster deployments by running terraform init, validate, and plan operations to ensure infrastructure code quality and correctness.

## Overview

This workflow provides comprehensive testing of Terraform configurations for cluster deployments. It performs multiple validation steps including format checking, initialization, validation, and planning. Optionally, it can perform a test deployment and cleanup in an isolated environment. The workflow also generates documentation for the Terraform configurations.

## Features

- **Multiple Validation Steps**: Runs terraform fmt, init, validate, and plan operations
- **Flexible Backend Configuration**: Supports custom backend configuration
- **Variables Support**: Allows specifying a variables file for testing
- **Test Deployment Option**: Can perform a test apply and destroy cycle
- **Documentation Generation**: Automatically generates documentation for Terraform modules
- **Artifact Upload**: Saves terraform plan files as artifacts for review

## Parameters

| Parameter             | Type    | Required | Default   | Description                                             |
|-----------------------|---------|----------|-----------|---------------------------------------------------------|
| `working-directory`   | string  | Yes      |           | Directory containing the Terraform configurations       |
| `terraform-version`   | string  | No       | `'1.5.7'` | Version of Terraform to use                             |
| `backend-config`      | string  | No       | `'{}'`    | Optional backend configuration parameters (JSON format) |
| `terraform-vars-file` | string  | No       | `''`      | Optional path to terraform.tfvars file                  |
| `test-apply`          | boolean | No       | `false`   | Whether to perform a test apply                         |
| `test-destroy`        | boolean | No       | `true`    | Whether to destroy test resources after apply           |

## Outputs

This workflow does not define explicit outputs, but it does upload the Terraform plan as an artifact.

## Dependencies

This template may depend on the following:

- **Required GitHub Secrets**:
- `TERRAFORM_API_TOKEN` - For Terraform Cloud integration (if used)
- **Required Tools**:
- terraform-docs - Installed during workflow if not present

## Usage

### Basic Usage

```yaml
terraform-tests:
  name: Terraform Configuration Tests
  uses: ./.github/workflows/cluster-test-terraform.yml
  with:
    working-directory: 'blueprints/terraform/full-single-cluster'
    terraform-version: '1.5.7'
```

### Advanced Usage

```yaml
terraform-tests:
  name: Terraform Configuration Tests
  uses: ./.github/workflows/cluster-test-terraform.yml
  with:
    working-directory: 'blueprints/terraform/full-single-cluster'
    terraform-version: '1.6.0'
    backend-config: '{"key": "my-state-file", "bucket": "my-tf-state"}'
    terraform-vars-file: './test/fixtures/test.tfvars'
    test-apply: true
    test-destroy: true
```

## Implementation Details

The workflow executes a single job that:

1. Checks out the repository
2. Sets up Terraform with the specified version
3. Checks Terraform formatting
4. Initializes Terraform with backend configuration
5. Validates the Terraform configuration
6. Runs a Terraform plan
7. Optionally applies the configuration (test deployment)
8. Optionally destroys deployed resources
9. Generates documentation for the module
10. Uploads plan files as artifacts

### Key Components

- **Setup Terraform**: Uses HashiCorp's official action to set up the correct Terraform version
- **Backend Configuration**: Processes JSON input to generate backend config parameters
- **Variables Handling**: Checks for and uses a variables file if specified
- **Documentation Generation**: Uses terraform-docs to generate markdown documentation

### Error Handling

- The workflow will fail if terraform validate or plan operations fail
- Test destroy operations are run with continue-on-error to ensure the workflow completes even if destroy fails
- Documentation generation is run with continue-on-error to prevent non-critical failures from failing the workflow

## Examples

### Example 1: Matrix Testing of Multiple Modules

```yaml
name: Terraform Tests

on:
  pull_request:
    paths:
      - 'blueprints/terraform/**'

jobs:
  changes:
    uses: ./.github/workflows/matrix-folder-check.yml

  terraform-matrix-tests:
    needs: changes
    if: needs.changes.outputs.changesInInstall == 'true'
    strategy:
      matrix: ${{ fromJson(needs.changes.outputs.changedTFFolders) }}
    uses: ./.github/workflows/cluster-test-terraform.yml
    with:
      working-directory: ${{ matrix.folderName }}
      terraform-version: '1.5.7'
```

### Example 2: Test Deployment for Main Branch

```yaml
name: Test Deployment

on:
  push:
    branches:
      - main
    paths:
      - 'blueprints/terraform/dev-environment/**'

jobs:
  deploy-test:
    uses: ./.github/workflows/cluster-test-terraform.yml
    with:
      working-directory: 'blueprints/terraform/dev-environment'
      terraform-version: '1.5.7'
      terraform-vars-file: './test/fixtures/dev.tfvars'
      test-apply: true
      test-destroy: true
```

## Troubleshooting

1. **Terraform Init Failure**: Backend configuration issues
   - **Solution**: Check the backend-config parameter format and credentials

2. **Terraform Plan/Apply Failures**: Configuration or provider issues
   - **Solution**: Review plan output for specific error messages and fix configuration

3. **Documentation Generation Failure**: Missing terraform-docs
   - **Solution**: The workflow should install terraform-docs automatically, but check log for specific errors

## Related Workflows

- [Matrix Folder Check Workflow](./matrix-folder-check.md) - Often used to determine which folders to test with this workflow

## Learn More

- [Terraform Documentation](https://www.terraform.io/docs)
- [GitHub Actions for Terraform](https://github.com/hashicorp/setup-terraform)
- [terraform-docs](https://terraform-docs.io/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

---
title: Testing and Validation
description: Comprehensive guide to testing infrastructure components and validating changes, covering testing strategies, validation procedures, and quality assurance practices
author: Edge AI Team
ms.date: 2025-06-06
ms.topic: how-to
estimated_reading_time: 7
keywords:
  - testing
  - validation
  - quality assurance
  - infrastructure testing
  - terraform testing
  - bicep testing
  - pester
  - terraform test
  - terratest
  - checkov
  - security testing
---

This guide covers testing strategies, validation procedures, and quality assurance practices for the AI on Edge Flagship Accelerator. Following these practices ensures reliable, secure, and maintainable infrastructure components.

## Test Policy

To maintain code quality and the OSSF Best Practices Badge, we enforce the following:

1. **New Functionality**: All new major functionality requires corresponding automated tests.
2. **Bug Fixes**: Bug fixes require regression tests that verify the fix.

### Technology Requirements

| Technology     | Framework               | Minimum Requirement                                   |
|:---------------|:------------------------|:------------------------------------------------------|
| **Terraform components** | native `terraform test` | One `.tftest.hcl` per component with `command = plan`     |
| **Blueprint IaC**        | Go / Terratest           | Contract and deployment tests under blueprint `tests/`    |
| **Rust**                 | `cargo test`             | `#[cfg(test)]` module covering core logic                 |
| **.NET**                 | xUnit / NUnit            | Test project covering business logic                      |
| **JavaScript**           | Jest / TypeScript        | Docs tests and `tsc --noEmit` checks                      |

## Testing Philosophy

The project follows a comprehensive testing approach:

- **Infrastructure as Code Testing**: Validate templates before deployment
- **Security-First Validation**: Continuous security scanning and compliance checking
- **Multi-Environment Testing**: Validate across development, staging, and production scenarios
- **Automated Quality Gates**: Prevent issues through automated validation pipelines

## Infrastructure Testing

### Terraform Testing

#### Static Analysis

Validate Terraform configurations without deployment:

```bash
# Navigate to component directory
cd src/000-cloud/010-security-identity/terraform

# Initialize Terraform
terraform init

# Validate syntax and configuration
terraform validate

# Check formatting
terraform fmt -check

# Plan to verify resource configuration
terraform plan
```

#### Linting with TFLint

Run advanced Terraform linting:

```bash
# Run TFLint on current directory
tflint

# Run with specific configuration
tflint --config=.tflint.hcl

# Run on specific files
tflint main.tf variables.tf
```

#### Native Terraform Tests

Use Terraform's native test framework for component tests. Place `.tftest.hcl`
files under the component's `terraform/tests/` directory and use `command = plan`
for fast validation that does not deploy Azure resources.

```bash
# Navigate to a component Terraform directory
cd src/000-cloud/000-resource-group/terraform

# Initialize providers and modules
terraform init

# Run the component's .tftest.hcl files
terraform test

# Run through the repository npm helper
npm run tf-test -- src/000-cloud/000-resource-group/terraform

# Run all Terraform tests
npm run tf-test-all
```

### Bicep Testing

#### Template Validation

Validate Bicep templates:

```bash
# Navigate to component directory
cd src/000-cloud/010-security-identity/bicep

# Validate template syntax
az bicep validate --file main.bicep

# Build to ARM template
az bicep build --file main.bicep

# Test deployment (what-if)
az deployment group what-if \
  --resource-group "test-rg" \
  --template-file main.bicep \
  --parameters @parameters.json
```

#### Linting with Bicep

Use built-in Bicep linting:

```bash
# Lint Bicep files
az bicep lint --file main.bicep

# Check for security issues
az bicep lint --file main.bicep --level Error
```

### Rust Testing

Rust services in this repository are tested from their service directories. The
root `Cargo.toml` intentionally has no workspace members, so run `cargo test`
from the crate that changed.

```bash
# Navigate to the changed Rust service
cd src/500-application/512-avro-to-json/operators/avro-to-json

# Run unit and integration tests for that crate
cargo test

# Optional static checks for Rust changes
cargo fmt --check
cargo clippy --all-targets --all-features
```

### JavaScript and Docs Testing

The Docusaurus docs package uses Jest for docs tests and TypeScript for static
type validation.

```bash
# Run docs tests through the root helper
npm run docs:test

# Run tests and type checks directly from the docs package
npm run --prefix docs/docusaurus test
npm run --prefix docs/docusaurus typecheck

# Build the docs site before publishing larger docs changes
npm run docs:build
```

## Validation Tools

### Security Scanning with Checkov

Run comprehensive security analysis:

```bash
# Scan changed folders only
npm run checkov-changes

# Scan all folders
npm run checkov-all

# Scan specific directory
checkov -d src/000-cloud/010-security-identity

# Generate detailed report
checkov -d . --output json --output-file checkov-report.json
```

#### Common Checks

Checkov validates:

- **Resource configuration** against security best practices
- **Access control** and RBAC configurations
- **Network security** settings and firewall rules
- **Encryption** configuration for data at rest and in transit
- **Compliance** with industry standards (CIS, PCI DSS, GDPR)

### Code Quality Linting

Run linting tools locally:

```bash
# Run Terraform linting and formatting
npm run tflint-fix-all

# Run markdown linting
npm run mdlint-fix

# Run Terraform validation
npm run tf-validate
```

### Spell Checking

Maintain documentation quality:

```bash
# Check spelling in all markdown files
npm run cspell

# Check specific file
npx cspell docs/contributing/testing-validation.md

# Add words to project dictionary
echo "Docusaurus" >> .cspell-dictionary.txt
```

## Pre-Commit Validation

Run these checks before committing changes:

### Quick Validation Script

```bash
#!/bin/bash
# Save as scripts/pre-commit-check.sh

echo "Running pre-commit validation..."

# 1. Format and lint code
echo "1. Running linters..."
npm run lint-fix-devcontainer

# 2. Security scanning
echo "2. Running security scans..."
npm run checkov-changes

# 3. Spell checking
echo "3. Checking spelling..."
npm run cspell

# 4. Test changed components
echo "4. Testing components..."
# Add component-specific testing here

echo "Pre-commit validation complete!"
```

### Manual Validation Checklist

Before committing, verify:

- [ ] All linting issues resolved
- [ ] Security scans pass without new high-severity issues
- [ ] Terraform/Bicep templates validate successfully
- [ ] Documentation is spell-checked and formatted
- [ ] Tests pass for modified components
- [ ] Commit messages follow conventional commit format

## Component Testing

### Test Structure

Each component should include comprehensive tests:

```text
src/000-cloud/000-resource-group/
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── tests/
│       ├── naming-convention.tftest.hcl
│       ├── output-validation.tftest.hcl
│       └── setup/
│           └── main.tf
└── ci/
    └── terraform/
        ├── main.tf
        └── variables.tf
```

### Writing Component Tests

Create comprehensive test coverage with `.tftest.hcl` files:

```hcl
# Example: terraform/tests/naming-convention.tftest.hcl
provider "azurerm" {
  storage_use_azuread = true
  features {}
}

# Call the setup module to create a random resource prefix
run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

run "naming_with_different_environments" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "prod"
    location        = "eastus2"
    instance        = "001"
  }

  assert {
    condition     = azurerm_resource_group.new[0].name == "rg-${run.setup_tests.resource_prefix}-prod-001"
    error_message = "Resource group name should follow convention with environment = prod"
  }
}
```

### Test Data Management

Use test setup modules or inline `variables` blocks for test data. The resource
group component provides a setup module for generated prefixes:

```hcl
# terraform/tests/setup/main.tf
terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.1"
    }
  }
  required_version = ">= 1.12.0, < 2.0"
}

resource "random_string" "prefix" {
  length  = 4
  special = false
  upper   = false
}

output "resource_prefix" {
  value = "a${random_string.prefix.id}"
}
```

## Blueprint Testing

Some blueprints include comprehensive test suites using Go and the Terratest framework. The testing infrastructure validates both IaC declarations and actual deployments.

### Blueprint Test Architecture

**Shared Test Utilities:** [src/900-tools-utilities/904-test-utilities/](https://github.com/microsoft/edge-ai/tree/main/src/900-tools-utilities/904-test-utilities/)

Provides reusable testing functions for all blueprints including:

- Contract validation functions for Terraform and Bicep
- Deployment and cleanup utilities
- Output normalization across frameworks

**Reference Implementation:** [blueprints/full-single-node-cluster/tests/](https://github.com/microsoft/edge-ai/tree/main/blueprints/full-single-node-cluster/tests/)

Complete test suite demonstrating:

- Contract tests for both Terraform and Bicep
- End-to-end deployment validation
- Helper scripts for test execution
- Output contract definitions

### Contract Testing

**Purpose:** Fast static validation ensuring output declarations match test expectations

**Characteristics:**

- Runs in seconds without Azure authentication
- Zero cost - no Azure resources created
- Validates IaC configuration correctness
- Catches drift before expensive deployments

**Running Contract Tests:**

```bash
cd blueprints/full-single-node-cluster/tests

# Test both frameworks
./run-contract-tests.sh both

# Test specific framework
./run-contract-tests.sh terraform
./run-contract-tests.sh bicep

# Direct Go execution
go test -v -run Contract
```

### Deployment Testing

**Purpose:** Full end-to-end validation with real Azure resource deployment

**Characteristics:**

- Creates billable Azure resources
- Tests actual infrastructure deployment
- Validates resource connectivity and functionality
- Duration: 30-45 minutes per test

**Running Deployment Tests:**

```bash
cd blueprints/full-single-node-cluster/tests

# Enable automatic cleanup
export CLEANUP_RESOURCES=true

# Test specific framework
./run-deployment-tests.sh terraform
./run-deployment-tests.sh bicep

# Direct Go execution
go test -v -run TestTerraformFullSingleNodeClusterDeploy -timeout 2h
go test -v -run TestBicepFullSingleNodeClusterDeploy -timeout 2h
```

**Environment Variables:**

- `CLEANUP_RESOURCES` - Auto-delete resources after test (default: `false`)
- `TEST_ENVIRONMENT` - Environment name (default: `dev`)
- `TEST_LOCATION` - Azure region (default: `eastus2`)
- `TEST_RESOURCE_PREFIX` - Resource naming prefix (default: `t6`)
- `SKIP_BICEP_DEPLOYMENT` - Use existing deployment (default: `false`)

### Blueprint Test Organization

Each blueprint test suite includes:

```text
blueprints/{blueprint-name}/tests/
├── outputs.go                     # Output contract definition
├── contract_terraform_test.go     # Terraform contract validation
├── contract_bicep_test.go         # Bicep contract validation
├── deploy_terraform_test.go       # Terraform deployment test
├── deploy_bicep_test.go           # Bicep deployment test
├── validation.go                  # Shared validation functions
├── setup.go                       # Post-deployment setup
├── run-contract-tests.sh          # Contract test runner
└── run-deployment-tests.sh        # Deployment test runner
```

### Blueprint Integration Testing

```bash
# Navigate to blueprint directory
cd blueprints/full-single-node-cluster/terraform

# Initialize with test backend
terraform init -backend-config="container_name=test-tfstate"

# Plan deployment
terraform plan -var-file="test.tfvars"

# Apply to test environment
terraform apply -var-file="test.tfvars" -auto-approve


# Clean up
terraform destroy -var-file="test.tfvars" -auto-approve
```

### Creating Blueprint Tests

When creating a new blueprint, add comprehensive test coverage:

1. **Define output contract** in `tests/outputs.go` with struct tags for both frameworks
2. **Create contract tests** for static validation
3. **Create deployment tests** for end-to-end validation
4. **Add helper scripts** for simplified test execution
5. **Document test requirements** in blueprint README

**See:** [Blueprint Developer Guide](../getting-started/blueprint-developer.md#testing-and-validation) for detailed instructions

**See:** [test-utilities README](https://github.com/microsoft/edge-ai/blob/main/src/900-tools-utilities/904-test-utilities/README.md) for complete API reference

### Blueprint Validation Script

Create comprehensive validation:

```bash
#!/bin/bash
# scripts/validate-blueprint.sh

BLUEPRINT_DIR=$1
ENVIRONMENT=${2:-test}

echo "Validating blueprint: $BLUEPRINT_DIR"

# 1. Validate Terraform
cd "$BLUEPRINT_DIR/terraform"
terraform init
terraform validate
terraform plan -var-file="${ENVIRONMENT}.tfvars"

# 2. Run security scans
checkov -d .

# 3. Validate dependencies
echo "Checking component dependencies..."
# Add component dependency validation

echo "Blueprint validation complete!"
```

## Continuous Integration

### Pipeline Testing

The CI/CD pipeline includes comprehensive testing:

#### Build Stage

```yaml
# .azdo/pipelines/build.yml excerpt
- task: TerraformCLI@0
  displayName: 'Terraform Validate'
  inputs:
    command: 'validate'
    workingDirectory: '$(System.DefaultWorkingDirectory)/src/*/terraform'

- task: PowerShell@2
  displayName: 'Run Checkov Security Scan'
  inputs:
    filePath: 'scripts/Run-Checkov.ps1'
    arguments: '-IncludeChangedFolders'
```

#### Test Stage

```yaml
- name: Run Terraform tests
  run: npm run tf-test-all
```

### Quality Gates

The pipeline enforces these quality gates:

- **Linting**: All files must pass lint validation
- **Security**: No new high-severity security issues
- **Testing**: All component tests must pass
- **Documentation**: All documentation must be current and properly formatted

### Test Environments

Use dedicated environments for testing:

- **Development**: Individual developer testing and validation
- **CI/CD**: Automated testing in isolated environments
- **Staging**: Integration testing with production-like configurations
- **Production**: Final validation before deployment

## Troubleshooting

### Common Testing Issues

#### Terraform State Issues

```bash
# Reset state for testing
terraform workspace new test-$(date +%s)
terraform init

# Or use isolated backend
terraform init -backend-config="container_name=test-tfstate"
```

#### Azure Authentication Issues

```bash
# Verify Azure CLI authentication
az account show

# Login with service principal (CI/CD)
az login --service-principal -u $CLIENT_ID -p $CLIENT_SECRET --tenant $TENANT_ID

# Set subscription
az account set --subscription "your-subscription-id"
```

#### Test Timeout Issues

```bash
# Narrow the run to one Terraform test file while debugging
terraform test -filter=tests/naming-convention.tftest.hcl

# Run one component at a time through the helper
npm run tf-test -- src/000-cloud/000-resource-group/terraform
```

### Debugging Test Failures

#### Terraform Debugging

```bash
# Enable detailed logging
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log

# Run with verbose output
terraform apply -auto-approve -input=false
```

#### Bicep Debugging

```bash
# Deploy with verbose output
az deployment group create \
  --resource-group "test-rg" \
  --template-file main.bicep \
  --parameters @parameters.json \
  --verbose
```

#### Test Data Investigation

```bash
# Inspect a plan before applying it
terraform plan -var-file="test.tfvars" -out=tfplan

# Clean up after investigation
terraform destroy -auto-approve
```

### Performance Testing

#### Infrastructure Performance

Monitor deployment times and resource utilization:

```bash
# Time Terraform operations
time terraform apply -auto-approve

# Monitor Azure resource deployment
az deployment group show \
  --resource-group "test-rg" \
  --name "deployment-name" \
  --query "properties.duration"
```

#### Test Execution Performance

Optimize test execution time:

```bash
# Run all Terraform tests through the parallel repository helper
npm run tf-test-all

# Run a single component while narrowing a failure
npm run tf-test -- src/000-cloud/000-resource-group/terraform
```

## Best Practices

### Test Organization

- **Separate unit and integration tests** clearly
- **Use descriptive test names** that explain what is being tested
- **Include both positive and negative test cases**
- **Test error conditions** and edge cases
- **Implement contract tests** for fast validation before deployment tests
- **Use test-utilities package** for consistent testing patterns across blueprints

### Best Practices for Test Data

- **Use parameterized tests** for multiple scenarios
- **Clean up test resources** with `terraform destroy` after deployment validation
- **Isolate test environments** to prevent interference
- **Use realistic test data** that represents production scenarios
- **Run contract tests first** to catch errors before expensive deployments
- **Enable cleanup in CI/CD** to prevent resource accumulation

### Validation Strategy

- **Test early and often** during development
- **Automate repetitive validation tasks**
- **Include security testing** in all validation procedures
- **Document test procedures** for team consistency

### Continuous Improvement

- **Regular review** of test coverage and effectiveness
- **Update tests** when requirements change
- **Share testing knowledge** across the team
- **Contribute improvements** to testing frameworks and tools

For more information about development workflows, see the [Development Environment](./development-environment.md) and [Contributing Guidelines](../contributions.md).

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

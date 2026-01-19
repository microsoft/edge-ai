# Tests for Full Single Node Cluster Blueprint

This directory contains comprehensive integration and contract tests for the [Full Single Node Cluster](../README.md) blueprint supporting both Terraform and Bicep deployments.

## Quick Start

```bash
# Contract tests (fast, zero-cost validation)
./run-contract-tests.sh both

# Terraform deployment tests (creates Azure resources)
./run-deployment-tests.sh terraform

# Bicep deployment tests (creates Azure resources, auto-generates password)
./run-deployment-tests.sh bicep

# Run both deployment frameworks
./run-deployment-tests.sh both
```

## Test Architecture

The test suite provides two complementary testing strategies:

### 1. Contract Tests (Fast, Zero-Cost)

**Purpose:** Static validation of IaC output declarations without deployment

- ✅ Validates `BlueprintOutputs` struct matches IaC output declarations
- ⚡ Executes in seconds without Azure authentication
- 💰 Zero cost - no Azure resources created
- 🔧 Uses `terraform-docs` and `az bicep build` for static analysis
- 🐛 Catches configuration drift before expensive deployments

### 2. Deployment Tests (Full Integration)

**Purpose:** End-to-end deployment and functional validation

- 🚀 Deploys complete infrastructure to Azure
- ✅ Validates resource creation and configuration
- 🔌 Tests Kubernetes cluster connectivity and operations
- ☁️ Verifies IoT Operations deployment and functionality
- ⚠️ **Creates billable Azure resources** - requires cleanup

## Prerequisites

### For Contract Tests

**Required:**

- Go 1.23 or later
- `terraform-docs` - Terraform contract validation
- Azure CLI with Bicep (`az bicep`) - Bicep contract validation

**No Azure authentication required** - tests run entirely offline

### For Deployment Tests

**Required (in addition to contract test prerequisites):**

- Terraform CLI (for Terraform deployment tests)
- Azure CLI authenticated (`az login`)
- Azure subscription with Owner or Contributor role
- Sufficient Azure quota for:
  - Virtual machines (Standard_D4s_v3)
  - IoT Operations resources
  - Azure Arc enabled Kubernetes

**Recommended:**

- `kubectl` - Kubernetes cluster validation
- `jq` - JSON parsing in helper scripts

## Setup

### 1. Install Go Dependencies

Run `go mod download` from the tests directory to fetch required Go packages.

### 2. Install Required Tools

**terraform-docs:** Install via package manager (Homebrew on macOS, manual download on Linux)

**Azure Bicep:** Install via `az bicep install`

**See:** Tool installation documentation in project root or official tool websites

### 3. Configure Azure Credentials (Deployment Tests Only)

Authenticate with `az login`, optionally set subscription with `az account set`, and verify with `az account show`. The deployment scripts automatically export `ARM_SUBSCRIPTION_ID`.

**See:** [run-deployment-tests.sh](run-deployment-tests.sh) for automatic credential handling

## Running Contract Tests

Contract tests validate that all outputs defined in the `BlueprintOutputs` struct are properly declared in both Terraform and Bicep configurations. These tests run entirely offline and complete in seconds.

### Using Helper Script (Recommended)

Use `run-contract-tests.sh` with framework argument (`both`, `terraform`, or `bicep`) and optional `-v` flag for verbose output.

**See:** [run-contract-tests.sh](run-contract-tests.sh) for script implementation

### Using Go Test Directly

Run `go test -v -run Contract` to execute all contract tests, or specify individual test names:

- `TestTerraformOutputsContract` - Terraform validation
- `TestBicepOutputsContract` - Bicep validation

**See:** [contract_terraform_test.go](contract_terraform_test.go) and [contract_bicep_test.go](contract_bicep_test.go)

## Running Deployment Tests

### Using the Helper Script (Recommended)

The `run-deployment-tests.sh` script handles environment setup, auto-detection, and password generation.

**Usage:** Framework argument (`terraform`, `bicep`, or `both`) with optional `-v` verbose flag

**See:** [run-deployment-tests.sh](run-deployment-tests.sh) for complete implementation

### Environment Variables

**Auto-Detected Variables** (script handles these):

- `ARM_SUBSCRIPTION_ID` - Azure subscription ID from `az account show`
- `CUSTOM_LOCATIONS_OID` - Custom Locations RP object ID from Azure AD
- `ADMIN_PASSWORD` - Auto-generated secure password (if not provided)

**Configuration Variables** (override as needed):

Set environment variables before running tests to customize behavior. See "Environment Variables Reference" section below for complete list with defaults.

**Common overrides:**

- `TEST_ENVIRONMENT`, `TEST_LOCATION`, `TEST_RESOURCE_PREFIX`, `TEST_INSTANCE` - Test naming
- `ADMIN_PASSWORD` - VM admin password (auto-generated if not set)
- `CLEANUP_RESOURCES` - Enable automatic resource deletion after test
- `SKIP_BICEP_DEPLOYMENT` + `BICEP_DEPLOYMENT_NAME` - Use existing deployment

### Advanced Go Test Usage

For advanced usage or CI/CD integration:

```bash
# Initialize Azure subscription context
source ../../../scripts/az-sub-init.sh

# Configure test parameters
export TEST_ENVIRONMENT="dev"
export TEST_LOCATION="eastus2"
export TEST_RESOURCE_PREFIX="t6"
export TEST_INSTANCE="001"

# Terraform deployment test
export TEST_RESOURCE_GROUP_NAME="t6-terraform"
go test -v -run TestTerraformFullSingleNodeClusterDeploy -timeout 2h

# Bicep deployment test (requires additional variables)
export TEST_RESOURCE_GROUP_NAME="t6-bicep"
export ADMIN_PASSWORD="MySecurePassword123!"
export CUSTOM_LOCATIONS_OID=$(az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv)
go test -v -run TestBicepFullSingleNodeClusterDeploy -timeout 2h
```

**Note**: Timeout of 2h allows for full deployment, validation, and optional cleanup.

## Test Organization

### Contract Tests (Static Analysis)

- [contract_terraform_test.go](contract_terraform_test.go) - Terraform output contract validation using `terraform-docs`
- [contract_bicep_test.go](contract_bicep_test.go) - Bicep output contract validation using `az bicep build`

### Deployment Tests (Integration)

- [deploy_terraform_test.go](deploy_terraform_test.go) - Terraform deployment, validation, and optional cleanup
- [deploy_bicep_test.go](deploy_bicep_test.go) - Bicep deployment, validation, and optional cleanup

### Shared Infrastructure

- [outputs.go](outputs.go) - `BlueprintOutputs` struct defining the output contract
- [validation.go](validation.go) - Comprehensive validation test suites for deployed infrastructure
- [setup.go](setup.go) - Post-deployment configuration (Arc proxy, RBAC permissions)

### Automation Scripts

- [run-contract-tests.sh](run-contract-tests.sh) - Contract test runner with dependency checks
- [run-deployment-tests.sh](run-deployment-tests.sh) - Deployment test runner with auto-configuration

## Test Files Reference

| File                         | Purpose                     | Azure Auth Required | Deploys Resources |
|------------------------------|-----------------------------|---------------------|-------------------|
| `contract_terraform_test.go` | Validate Terraform outputs  | (-) No              | (-) No            |
| `contract_bicep_test.go`     | Validate Bicep outputs      | (-) No              | (-) No            |
| `deploy_terraform_test.go`   | Deploy & validate Terraform | (+) Yes             | (+) Yes           |
| `deploy_bicep_test.go`       | Deploy & validate Bicep     | (+) Yes             | (+) Yes           |
| `outputs.go`                 | Output contract definition  | (-) No              | (-) No            |
| `validation.go`              | Shared validation logic     | (-) No              | (-) No            |
| `setup.go`                   | Post-deployment setup       | (+) Yes             | (-) No            |

## Important Notes

### Cost Considerations

- **Contract tests:** Free - no Azure resources created
- **Deployment tests:** Creates billable Azure resources including:
  - Virtual machines (Standard_D4s_v3)
  - Azure Arc enabled Kubernetes
  - IoT Operations resources
  - Storage accounts and networking

**Always set `CLEANUP_RESOURCES=true` for cost control** or manually delete resources after testing.

### Test Duration

- **Contract tests:** < 1 second (static analysis only)
- **Deployment tests:** 30-45 minutes (full infrastructure deployment)

### Resource Cleanup

When `CLEANUP_RESOURCES=true`:

- **Terraform:** Runs `terraform destroy` to remove all resources
- **Bicep:** Deletes entire resource group with `az group delete`

**Manual cleanup** if tests fail during deployment:

Use `az group list` to find test resource groups (typically prefixed with `t6-`), then delete with `az group delete --name <name> --yes --no-wait`.

## Troubleshooting Guide

### Contract Test Issues

**terraform-docs not found:** Install terraform-docs via package manager

**az bicep not found:** Run `az bicep install`

**Missing outputs:** Add to `outputs.tf` (Terraform) or `main.bicep` outputs (Bicep), or remove from `BlueprintOutputs` struct

### Deployment Test Issues

**Authentication errors:** Ensure `az login` completed successfully and verify with `az account show`

**InsufficientQuota:** Request quota increase in Azure Portal or try different region via `TEST_LOCATION` variable

**Timeout errors:** Increase test timeout using `-timeout` flag (e.g., `-timeout 3h`)

**Cluster unreachable:** VM and Arc proxy setup handled automatically by [setup.go](setup.go); check Azure Portal for VM status
| `validation.go` | Validation test suites | ✅ Yes | ❌ No |
| `setup.go` | Arc proxy & permissions | ✅ Yes | ❌ No |

## Validation Test Suite

The [validation.go](validation.go) file contains comprehensive validation functions:

### Core Infrastructure Validation

Implemented in `validateCoreInfrastructure()`:

- ✅ Deployment summary (resource group, location, environment)
- ✅ Security and identity (Key Vault, managed identities, RBAC)
- ✅ Observability (Log Analytics workspace, Grafana, Azure Monitor)
- ✅ Networking (NAT Gateway, virtual network, subnets)
- ✅ Data storage (Storage Account, Schema Registry)
- ✅ Container registry (Azure Container Registry)
- ✅ VM host resources (compute, networking, storage)
- ✅ Arc-connected cluster (Connected Cluster resource)

### Kubernetes Cluster Validation

Implemented in `validateKubernetesCluster()`:

- ✅ Node status and readiness
- ✅ System namespaces and core pods
- ✅ Kubernetes services availability
- ✅ Resource quotas and limits

### Azure IoT Operations Validation

Implemented in `validateAzureIoTOperations()`:

- ✅ AIO namespace existence and pod status
- ✅ Custom Location configuration
- ✅ Asset Endpoint Profile resources
- ✅ MQTT Broker deployment (Terraform deployments only)

### Messaging Validation

Implemented in `validateMessagingInfrastructure()` (Terraform only):

- ✅ Event Hub message consumption and parsing
- ✅ Message format and schema validation
- ✅ End-to-end data flow verification

## Key Differences: Terraform vs Bicep Tests

| Feature                  | Terraform                                  | Bicep                                     |
|--------------------------|--------------------------------------------|-------------------------------------------|
| **Test Function**        | `TestTerraformFullSingleNodeClusterDeploy` | `TestBicepFullSingleNodeClusterDeploy`    |
| **Validation Function**  | `validateTerraformDeployment`              | `validateBicepDeployment`                 |
| **Messaging Tests**      | (+) Included (Event Hub validation)        | (-) Skipped (dataflow config limitations) |
| **Password Requirement** | (-) Not required (uses SSH keys)           | (+) Required (auto-generated by script)   |
| **Custom Locations OID** | (-) Not required (uses managed identity)   | (+) Required (auto-detected by script)    |
| **Deployment Scope**     | Resource group                             | Subscription-level                        |

## Environment Variables Reference

### Auto-Detected Variables

| Variable               | Description                        | Fallback                     |
|------------------------|------------------------------------|------------------------------|
| `ARM_SUBSCRIPTION_ID`  | Azure subscription ID              | Script fails if not detected |
| `CUSTOM_LOCATIONS_OID` | Custom Locations service principal | Script fails if not detected |
| `ADMIN_PASSWORD`       | VM admin password                  | Auto-generated password      |

### Configuration Variables

| Variable                   | Description          | Default                                 |
|----------------------------|----------------------|-----------------------------------------|
| `TEST_ENVIRONMENT`         | Environment name     | `dev`                                   |
| `TEST_LOCATION`            | Azure region         | `eastus2`                               |
| `TEST_RESOURCE_PREFIX`     | Resource name prefix | `t6`                                    |
| `TEST_INSTANCE`            | Instance identifier  | `001`                                   |
| `TEST_RESOURCE_GROUP_NAME` | Resource group name  | `${TEST_RESOURCE_PREFIX}-{tf or bicep}` |

### Optional Control Variables

| Variable                | Description                      | Default                 |
|-------------------------|----------------------------------|-------------------------|
| `CLEANUP_RESOURCES`     | Auto-delete resources after test | `false`                 |
| `SKIP_BICEP_DEPLOYMENT` | Skip deployment, use existing    | `false`                 |
| `BICEP_DEPLOYMENT_NAME` | Name of existing deployment      | `bicep-deployment-test` |

**⚠️ Resource Cleanup Note**: By default, tests **DO NOT** delete resources after completion. Set `CLEANUP_RESOURCES=true` to enable automatic cleanup.

## Common Workflows

### Development Workflow

**Typical development cycle for test improvements:**

```bash
# Step 1: Validate IaC output contract (fast, no costs)
./run-contract-tests.sh both

# Step 2: Initial deployment (resources remain for inspection)
./run-deployment-tests.sh terraform

# Step 3: Iterate on validation logic without redeploying
export SKIP_BICEP_DEPLOYMENT=true
go test -v -run TestBicepFullSingleNodeClusterDeploy -timeout 30m

# Step 4: Test cleanup functionality before final commit
export CLEANUP_RESOURCES=true
./run-deployment-tests.sh terraform
```

### CI/CD Integration

**Recommended pipeline stages:**

```bash
# Stage 1: PR validation (every commit, ~30 seconds)
./run-contract-tests.sh both

# Stage 2: Nightly integration tests (scheduled, ~90 minutes)
export CLEANUP_RESOURCES=true
./run-deployment-tests.sh both
```

### Adding New Infrastructure Outputs

**Complete workflow for adding new outputs:**

```bash
# Step 1: Add output to IaC configuration
# - For Terraform: Edit ../terraform/outputs.tf
# - For Bicep: Edit ../bicep/main.bicep

# Step 2: Add corresponding field to BlueprintOutputs struct
# - Edit outputs.go
# - Add struct field with terraform:"/" or bicep:"/" tag

# Step 3: Verify contract validation passes
./run-contract-tests.sh both

# Step 4: Add validation logic (if needed)
# - Edit validation.go
# - Add assertions for new output values

# Step 5: Run end-to-end deployment test
./run-deployment-tests.sh terraform
```

### Debugging Failed Deployments

**Troubleshooting and inspection workflow:**

```bash
# Deploy without cleanup to inspect resources
export CLEANUP_RESOURCES=false
./run-deployment-tests.sh terraform

# Manually inspect resources in Azure Portal or CLI
az resource list --resource-group t6-terraform -o table

# Test specific validation functions
go test -v -run TestTerraformFullSingleNodeClusterDeploy/Validate -timeout 30m

# Clean up when done
export CLEANUP_RESOURCES=true
go test -v -run TestTerraformFullSingleNodeClusterDeploy -timeout 15m
```

## Troubleshooting

### Contract Test Failures

```text
❌ Missing 2 required outputs in terraform: [new_output_1, new_output_2]
```

**Solution**: Add the missing outputs to `terraform/outputs.tf` or `bicep/main.bicep`, or remove them from the `BlueprintOutputs` struct in `outputs.go`.

### Auto-Detection Failures

If `ARM_SUBSCRIPTION_ID` auto-detection fails:

```bash
az login
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
```

If `CUSTOM_LOCATIONS_OID` auto-detection fails:

```bash
# Ensure you have permissions to query Azure AD
export CUSTOM_LOCATIONS_OID=$(az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv)
```

### Arc Proxy Connection Issues

If Arc proxy fails to connect:

```bash
# Manually test Arc connectivity
az connectedk8s proxy \
  --name <cluster-name> \
  --resource-group <resource-group> &

# Wait a few seconds, then test
kubectl get nodes
```

### Permission Issues

Required Azure permissions:

- **Contributor** access to subscription
- **Azure AD read** permissions (for Custom Locations OID query)
- **Event Hub Data Receiver** role (auto-assigned by test setup)

## Cost Management

**⚠️ WARNING**: Deployment tests create real Azure resources and incur costs!

### Cost Optimization Strategies

1. **Use contract tests for rapid iteration** - Zero cost, instant feedback
2. **Reuse deployments** - Set `SKIP_BICEP_DEPLOYMENT=true` after initial deployment
3. **Clean up after testing** - Tests don't auto-destroy resources
4. **Use smaller configurations** - Modify test variables to use minimal SKUs
5. **Monitor Azure costs** - Track spending during test development

### Estimated Costs

Approximate costs per deployment test run (varies by region):

- VM hosts: ~$2-5/hour
- Azure IoT Operations: ~$1-2/hour
- Networking (NAT Gateway): ~$0.50/hour
- Storage and monitoring: ~$0.25/hour

**Total**: ~$4-8/hour per deployment

## Additional Resources

- [Blueprint README](../README.md) - Complete blueprint documentation and deployment guide
- [Test Utilities Package](../../../src/900-tools-utilities/904-test-utilities/) - Shared testing utilities and functions
- [Terraform Implementation](../terraform/) - Terraform IaC configuration
- [Bicep Implementation](../bicep/) - Bicep IaC configuration
- [Terratest Documentation](https://terratest.gruntwork.io/) - Underlying test framework documentation

# Blueprint Test Utilities

Shared testing utilities for all edge-ai blueprints providing reusable, framework-agnostic functions for validating and deploying infrastructure as code.

## Package: `testutil`

**Import path:** `github.com/microsoft/edge-ai/src/900-tools-utilities/904-test-utilities`

**Purpose:** Standardized testing primitives for blueprint validation across both Terraform and Bicep implementations.

## Key Features

### 1. Contract Testing

Static validation of IaC output declarations without deployment:

- ⚡ **Fast** - Completes in seconds
- 💰 **Zero Cost** - No Azure resources created
- 🔒 **Type Safe** - Enforces contract between test code and IaC
- 🐛 **Early Detection** - Catches drift before deployment

### 2. Deployment Functions

Unified deployment and output retrieval:

- 🔄 **Framework Agnostic** - Consistent interface for Terraform and Bicep
- 🧹 **Automatic Cleanup** - Optional resource teardown after tests
- 📊 **Output Normalization** - Converts outputs to common format
- 🔧 **Configuration Driven** - Environment variable support

---

## Contract Testing

Contract testing validates that all outputs required by test code are properly declared in the IaC configuration, preventing runtime failures during expensive deployments.

### How It Works

1. **Extract Declarations:** Parse IaC files to find declared outputs
2. **Compare Contracts:** Match declared outputs against required outputs
3. **Report Drift:** Fail fast if any required output is missing

### Benefits

- ⚡ **Fast** - Runs in seconds without Azure authentication
- 💰 **Zero Cost** - No Azure resources created
- 🔒 **Type Safety** - Enforces contract between tests and IaC
- 🐛 **Early Detection** - Catches missing outputs before deployment
- 🔄 **CI/CD Ready** - Perfect for pre-deployment validation gates

### Functions

#### `GetTerraformDeclaredOutputs(t, terraformDir) []string`

Extracts declared output names from Terraform configuration using `terraform-docs`.

**Parameters:**

- `t *testing.T` - Test context for error reporting
- `terraformDir string` - Absolute or relative path to directory containing `.tf` files

**Returns:** List of output names declared in Terraform configuration

**Requirements:** `terraform-docs` installed and in PATH, valid `.tf` files in directory

**See:** [contract_terraform_test.go](../../../blueprints/full-single-node-cluster/tests/contract_terraform_test.go) for usage example

#### `GetBicepDeclaredOutputs(t, bicepDir) []string`

Extracts declared output names from Bicep configuration using `az bicep build`.

**Parameters:**

- `t *testing.T` - Test context for error reporting
- `bicepDir string` - Absolute or relative path to directory containing `main.bicep`

**Returns:** List of output names declared in Bicep configuration

**Requirements:** Azure CLI with Bicep installed, `main.bicep` file in directory

**See:** [contract_bicep_test.go](../../../blueprints/full-single-node-cluster/tests/contract_bicep_test.go) for usage example

#### `ValidateOutputContract(t, declaredOutputs, requiredOutputs, framework)`

Validates that all required outputs are declared in IaC configuration. Fails test with detailed error reporting if any outputs are missing.

**Parameters:**

- `t *testing.T` - Test context for error reporting
- `declaredOutputs []string` - Outputs declared in IaC (from `GetTerraform/BicepDeclaredOutputs`)
- `requiredOutputs []string` - Outputs required by tests (from `BlueprintOutputs.GetRequiredOutputKeys()`)
- `framework string` - Framework name for error messages

**Behavior:** Passes if all required outputs are declared, fails with detailed report if any are missing

**See:** [contract_terraform_test.go](../../../blueprints/full-single-node-cluster/tests/contract_terraform_test.go) and [validation.go](../../../blueprints/full-single-node-cluster/tests/validation.go) for implementation

#### `ValidateTerraformContract(t, terraformDir, requiredOutputs)`

Convenience function combining `GetTerraformDeclaredOutputs` and `ValidateOutputContract`.

**Parameters:** Test context, Terraform directory path, required output names list

**Equivalent to:** Calling `GetTerraformDeclaredOutputs` followed by `ValidateOutputContract`

**See:** [contract_terraform_test.go](../../../blueprints/full-single-node-cluster/tests/contract_terraform_test.go) for usage

#### `ValidateBicepContract(t, bicepDir, requiredOutputs)`

Convenience function combining `GetBicepDeclaredOutputs` and `ValidateOutputContract`.
Automatically converts required output names from snake_case to camelCase for Bicep comparison.

**Parameters:**

- `t *testing.T` - Test context for error reporting
- `bicepDir string` - Absolute or relative path to directory containing `main.bicep`
- `requiredOutputs []string` - Output names in snake_case (automatically converted to camelCase)

**Naming Convention Conversion:**

- `deployment_summary` → `deploymentSummary`
- `azure_iot_operations` → `azureIotOperations`
- `acr_network_posture` → `acrNetworkPosture`

**Behavior:** Converts required outputs to camelCase, then validates against Bicep declarations

**See:** [contract_bicep_test.go](../../../blueprints/full-single-node-cluster/tests/contract_bicep_test.go) for usage

#### `SnakeToCamelCase(s string) string`

Converts a snake_case string to camelCase. Used internally by `ValidateBicepContract` to transform output names from Terraform convention to Bicep convention.

**Parameters:** `s string` - Input string in snake_case format

**Returns:** String converted to camelCase

**Examples:**

- `"deployment_summary"` → `"deploymentSummary"`
- `"azure_iot_operations"` → `"azureIotOperations"`
- `"nat_gateway_public_ips"` → `"natGatewayPublicIps"`

#### `CamelToSnakeCase(s string) string`

Converts a camelCase string to snake_case. Used internally by `ParseBicepOutputsFromMap` to transform map keys from Bicep convention to Terraform convention.

**Parameters:** `s string` - Input string in camelCase format

**Returns:** String converted to snake_case

**Examples:**

- `"resourceGroup"` → `"resource_group"`
- `"keyVaultName"` → `"key_vault_name"`
- `"aioIdentity"` → `"aio_identity"`

#### `GetOutputKeysFromStruct(outputStruct any) []string`

Extracts all output names defined in a struct using reflection. Reads `output` tags from struct fields.

**Parameters:** `outputStruct` - Struct instance (value or pointer) with `output` tags

**Returns:** Slice of output names extracted from struct tags

**Usage:** Called by `BlueprintOutputs.GetRequiredOutputKeys()` to get list of required outputs for contract validation.

---

## Output Parsing Functions

These functions convert raw deployment outputs to strongly-typed structs for use in validation code.

### `ParseTerraformOutputsFromMap(t, raw, outputStruct)`

Converts raw Terraform deployment outputs to a strongly-typed output struct using reflection.

**Parameters:**

- `t *testing.T` - Test context for error reporting
- `raw map[string]any` - Raw output map from `terraform.OutputAll()`
- `outputStruct any` - Pointer to struct with `output` tags

**Behavior:** Maps outputs by matching `output` struct tag to raw map keys. Fails test if any required output is missing.

### `ParseBicepOutputsFromMap(t, raw, outputStruct)`

Converts raw Bicep deployment outputs to a strongly-typed output struct.

**Parameters:**

- `t *testing.T` - Test context for error reporting
- `raw map[string]any` - Raw output map from Bicep deployment
- `outputStruct any` - Pointer to struct with `output` tags (snake_case)

**Key Differences from Terraform:**

1. **Output name conversion:** Converts snake_case struct tags to camelCase for Bicep lookup
   - Struct tag `output:"deployment_summary"` → looks up `deploymentSummary` in raw outputs
2. **Recursive map key transformation:** Converts all map keys from camelCase to snake_case
   - Bicep returns `{"resourceGroup": "my-rg"}` → becomes `{"resource_group": "my-rg"}`
   - This allows validation code to use consistent snake_case keys regardless of framework

**Why This Matters:** Validation code can use the same key names (snake_case) for both Terraform and Bicep outputs:

```go
// Works for both frameworks:
outputs.DeploymentSummary["resource_group"]
outputs.SecurityIdentity["key_vault_name"]
```

---

## Deployment Functions

These functions handle deployment and output retrieval for both Terraform and Bicep.

### Terraform Deployment

#### `DeployTerraform(t, terraformDir, vars, shouldCleanup) map[string]any`

Executes complete Terraform deployment workflow: init, apply, and optional destroy.

**Parameters:**

- `t *testing.T` - Test context
- `terraformDir string` - Path to directory containing `.tf` files
- `vars map[string]any` - Terraform input variables
- `shouldCleanup bool` - Register automatic cleanup via `t.Cleanup()`

**Returns:** All Terraform outputs as map

**Behavior:** Runs init/apply, retrieves outputs, optionally registers destroy cleanup handler

**Requirements:** Terraform CLI in PATH, `ARM_SUBSCRIPTION_ID` set, Azure authenticated

**Note:** Read `shouldCleanup` from `CLEANUP_RESOURCES` environment variable to avoid accidental deletion

**See:** [deploy_terraform_test.go](../../../blueprints/full-single-node-cluster/tests/deploy_terraform_test.go) for complete usage pattern

### Bicep Deployment

#### DeployBicep

**Signature:**

```go
DeployBicep(
    t *testing.T,
    bicepDir string,
    subscriptionID string,
    deploymentName string,
    resourceGroupName string,
    params map[string]any,
    shouldCleanup bool,
) map[string]any
```

Executes complete Bicep deployment workflow at subscription scope with optional resource group cleanup.

**Parameters:**

- `t *testing.T` - Test context for logging and error reporting
- `bicepDir string` - Path to directory containing `main.bicep`
- `subscriptionID string` - Azure subscription ID (get via `az account show --query id -o tsv`)
- `deploymentName string` - Unique deployment name (visible in Azure Portal deployments)
- `resourceGroupName string` - Resource group name to delete during cleanup
- `params map[string]any` - Bicep parameters as nested map structure
- `shouldCleanup bool` - If `true`, registers resource group deletion via `t.Cleanup()`

**Returns:** `map[string]any` - All Bicep outputs converted to flat key-value pairs (Terraform-compatible format)

**Behavior:** Writes temp parameters file, runs subscription-level deployment, retrieves and flattens outputs, optionally registers resource group deletion cleanup

**Requirements:** Azure CLI authenticated, Bicep installed, subscription-level deployment permissions

**Important Notes:**

- Creates temporary `test-parameters.json` (auto-cleaned)
- Cleanup deletes **entire resource group** and all resources
- Converts Bicep output format to flat key-value pairs for compatibility

**See:** [deploy_bicep_test.go](../../../blueprints/full-single-node-cluster/tests/deploy_bicep_test.go) for complete usage pattern

#### `GetBicepOutputs(t, deploymentName) map[string]any`

Retrieves outputs from an existing Bicep deployment without redeploying. Useful for validating existing infrastructure or skipping deployment in tests.

**Parameters:**

- `t *testing.T` - Test context for error reporting
- `deploymentName string` - Name of existing subscription-level deployment

**Returns:** `map[string]any` - All deployment outputs in flattened format

#### Skip Deployment Pattern

Use `SKIP_BICEP_DEPLOYMENT=true` and `BICEP_DEPLOYMENT_NAME=<name>` environment variables to query existing deployment instead of creating new one.

**Requirements:** Azure CLI authenticated, deployment exists at subscription level, exact deployment name

**See:** [deploy_bicep_test.go](../../../blueprints/full-single-node-cluster/tests/deploy_bicep_test.go) for conditional deployment pattern

---

## Resource Cleanup Functions

These functions handle resource teardown after testing. **Typically called automatically** via `t.Cleanup()` when `shouldCleanup=true` in deployment functions.

### `DestroyTerraform(t, terraformOptions)`

Executes `terraform destroy` to remove all resources in Terraform state.

**Behavior:** Runs destroy with auto-approve, uses same variables as deployment, retries on transient failures

**Typically called automatically** via `t.Cleanup()` when `DeployTerraform` has `shouldCleanup=true`

### `DestroyBicep(t, subscriptionID, resourceGroupName)`

Executes `az group delete` to remove resource group and all contained resources.

**Behavior:** Deletes entire resource group asynchronously (no wait), more aggressive than Terraform destroy

**Typically called automatically** via `t.Cleanup()` when `DeployBicep` has `shouldCleanup=true`

**Important Notes:**

- ⚠️ Bicep cleanup deletes entire resource group (all resources)
- ⚠️ No confirmation prompt when called
- 🔄 Automatic when using Deploy functions with `shouldCleanup=true`
- 🧹 Manual cleanup required if test fails before cleanup registration

---

## Usage in Blueprint Tests

The [full-single-node-cluster tests](../../../blueprints/full-single-node-cluster/tests/) directory provides a complete reference implementation.

### Step 1: Define Blueprint Outputs

Create `outputs.go` with struct using `tf` and `bicep` tags to map framework-specific output names.

**See:** [outputs.go](../../../blueprints/full-single-node-cluster/tests/outputs.go) for struct definition pattern

### Step 2: Create Contract Tests

Create test files calling `ValidateTerraformContract` and `ValidateBicepContract` with required output keys.

**See:** [contract_terraform_test.go](../../../blueprints/full-single-node-cluster/tests/contract_terraform_test.go) and [contract_bicep_test.go](../../../blueprints/full-single-node-cluster/tests/contract_bicep_test.go)

### Step 3: Create Deployment Tests

Create test files using `DeployTerraform` and `DeployBicep` with variables/parameters, then run validations.

**See:** [deploy_terraform_test.go](../../../blueprints/full-single-node-cluster/tests/deploy_terraform_test.go) and [deploy_bicep_test.go](../../../blueprints/full-single-node-cluster/tests/deploy_bicep_test.go)

---

## Dependencies

### Required Tools

For contract testing:

- `terraform-docs` - Install: `brew install terraform-docs`
- `az bicep` - Install: `az bicep install`

For deployment testing:

- Terraform (for Terraform deployments)
- Azure CLI authenticated (`az login`)

### Go Modules

Add to your blueprint's `go.mod`:

```go
require (
    github.com/microsoft/edge-ai/src/900-tools-utilities/904-test-utilities v0.0.0-00010101000000-000000000000
    github.com/gruntwork-io/terratest v0.54.0
    github.com/stretchr/testify v1.11.1
)
```

---

## Best Practices

### 1. Run Contract Tests First

Run fast contract tests (`go test -run Contract`) before expensive deployment tests to catch configuration errors early.

### 2. Control Resource Cleanup

Tests preserve resources by default for inspection. Set `CLEANUP_RESOURCES=true` to enable automatic cleanup.

### 3. Use Struct Tags for Output Mapping

Define framework-specific output names using `tf` and `bicep` struct tags mapping to same field.

**See:** [outputs.go](../../../blueprints/full-single-node-cluster/tests/outputs.go) for tag pattern

### 4. Naming Convention Handling

Use snake_case for output struct tags (matching Terraform convention). The test utilities automatically handle conversion for Bicep:

- **Output names:** `ValidateBicepContract` converts snake_case tags to camelCase for lookup
- **Map keys:** `ParseBicepOutputsFromMap` recursively converts camelCase keys to snake_case

This allows validation code to use consistent snake_case keys regardless of framework:

```go
// Same validation code works for both Terraform and Bicep:
outputs.DeploymentSummary["resource_group"]      // Terraform: resource_group, Bicep: resourceGroup → resource_group
outputs.SecurityIdentity["key_vault_name"]       // Terraform: key_vault_name, Bicep: keyVaultName → key_vault_name
```

**Framework conventions:**

- **Terraform outputs:** snake_case (e.g., `deployment_summary`)
- **Bicep outputs:** camelCase (e.g., `deploymentSummary`)
- **Struct tags:** Use snake_case, automatic conversion handles Bicep

**See:** [outputs.tf](../../../blueprints/full-single-node-cluster/terraform/outputs.tf) and [main.bicep](../../../blueprints/full-single-node-cluster/bicep/main.bicep)

### 5. Implement Reusable Validation Functions

Create shared validation functions for common infrastructure testing patterns.

**See:** [validation.go](../../../blueprints/full-single-node-cluster/tests/validation.go) and [setup.go](../../../blueprints/full-single-node-cluster/tests/setup.go)

---

## Troubleshooting

### Contract Test Failures

**Missing outputs error:** Add outputs to IaC configuration or remove from `BlueprintOutputs` struct to match

### Tool Installation

**terraform-docs not found:** Install via package manager (e.g., `brew install terraform-docs`)

**az bicep not found:** Run `az bicep install`

### Bicep Output Format

`GetBicepOutputs` automatically converts Azure CLI's nested output format to flat key-value pairs compatible with Terraform output format.

---

## Complete Working Example

The [full-single-node-cluster tests](../../../blueprints/full-single-node-cluster/tests/) directory provides a complete, production-ready reference implementation.

### File Structure

```text
blueprints/full-single-node-cluster/tests/
├── outputs.go                     # BlueprintOutputs struct with tf/bicep tags
├── contract_terraform_test.go     # Terraform contract validation
├── contract_bicep_test.go         # Bicep contract validation
├── deploy_terraform_test.go       # Terraform end-to-end deployment test
├── deploy_bicep_test.go           # Bicep end-to-end deployment test
├── validation.go                  # Reusable validation functions
├── setup.go                       # Post-deployment setup (Arc proxy, RBAC)
├── run-contract-tests.sh          # Contract test helper script
└── run-deployment-tests.sh        # Deployment test helper script
```

**Use these files as templates** when creating tests for your own blueprints.

---

## Additional Resources

- [Blueprint Test README](../../../blueprints/full-single-node-cluster/tests/README.md) - Complete testing guide
- [Terratest Documentation](https://terratest.gruntwork.io/) - Underlying test framework
- [Azure CLI Bicep Reference](https://learn.microsoft.com/cli/azure/bicep) - Bicep CLI commands

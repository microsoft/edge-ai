// Package testutil provides reusable testing utilities for blueprint deployment and validation.
// Functions in this file handle deployment and output retrieval for both Terraform and Bicep.
package testutil

import (
	"encoding/json"
	"os"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/gruntwork-io/terratest/modules/shell"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/require"
)

// DeployTerraform executes 'terraform init' and 'terraform apply' with the provided variables.
//
// Parameters:
//   - t: Test context for assertions and logging
//   - terraformDir: Absolute or relative path to directory containing Terraform files
//   - vars: Terraform input variables as key-value map
//   - shouldCleanup: If true, automatically destroys resources via t.Cleanup after test
//
// Returns:
//   - map[string]any: All deployment outputs where keys are output names
//
// Behavior:
//   - Configures retry logic for common transient errors
//   - Disables colored output for cleaner log readability
//   - Registers cleanup function if shouldCleanup is true
//   - Runs terraform init and apply in sequence
//   - Retrieves all outputs after successful deployment
//
// Requirements:
//   - Terraform must be installed and available on PATH
//   - Valid Terraform configuration in terraformDir
//   - Azure authentication configured (ARM_SUBSCRIPTION_ID, etc.)
func DeployTerraform(t *testing.T, terraformDir string, vars map[string]any, shouldCleanup bool) map[string]any {
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: terraformDir,
		Vars:         vars,
		NoColor:      true,
		Lock:         true,
	})

	// Defer cleanup of deployed resources only if shouldCleanup is true
	if shouldCleanup {
		t.Cleanup(func() {
			DestroyTerraform(t, terraformOptions)
		})
	} else {
		t.Log("Skipping resource cleanup: shouldCleanup is false")
	}

	// Run terraform init and apply
	terraform.InitAndApply(t, terraformOptions)

	// Retrieve and return outputs
	outputOptions := &terraform.Options{
		TerraformDir: terraformDir,
		Vars:         vars,
		NoColor:      true,
		Logger:       logger.Discard,
	}
	return terraform.OutputAll(t, outputOptions)
}

// DeployBicep executes 'az deployment sub create' for subscription-level Bicep deployment.
//
// Parameters:
//   - t: Test context for assertions and logging
//   - bicepDir: Absolute or relative path to directory containing main.bicep
//   - subscriptionID: Azure subscription ID for deployment
//   - deploymentName: Name for the Azure deployment (must be unique per subscription)
//   - resourceGroupName: Name of resource group to delete during cleanup
//   - params: Bicep input parameters as key-value map
//   - shouldCleanup: If true, deletes resource group via t.Cleanup after test
//
// Returns:
//   - map[string]any: All deployment outputs converted to Terraform-compatible format
//
// Behavior:
//   - Creates temporary parameters JSON file in Azure format
//   - Converts params to {"$schema": ..., "parameters": {"key": {"value": val}}} format
//   - Executes az deployment sub create at subscription scope
//   - Registers resource group deletion if shouldCleanup is true
//   - Cleans up temporary parameters file automatically
//   - Retrieves outputs and converts from Azure to Terraform format
//
// Requirements:
//   - Azure CLI must be installed with Bicep extension
//   - User must be authenticated (az login)
//   - Sufficient subscription permissions for deployment
//
// Note: Cleanup deletes the entire resource group, not just the deployment.
func DeployBicep(t *testing.T, bicepDir, subscriptionID, deploymentName string, resourceGroupName string, params map[string]any, shouldCleanup bool) map[string]any {
	// Create temporary parameters JSON file
	tmpFile, err := os.CreateTemp("", "bicep-params-*.json")
	require.NoError(t, err, "Failed to create temporary parameters file")
	paramsFile := tmpFile.Name()
	tmpFile.Close()

	// Ensure cleanup of temporary file
	defer os.Remove(paramsFile)

	// Convert parameters to Azure parameter format
	azureParams := map[string]any{
		"$schema":        "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
		"contentVersion": "1.0.0.0",
		"parameters":     make(map[string]any),
	}

	paramMap := azureParams["parameters"].(map[string]any)
	for key, value := range params {
		paramMap[key] = map[string]any{"value": value}
	}

	paramsJSON, err := json.MarshalIndent(azureParams, "", "  ")
	require.NoError(t, err, "Failed to marshal parameters")

	err = os.WriteFile(paramsFile, paramsJSON, 0644)
	require.NoError(t, err, "Failed to write parameters file")

	// Deploy Bicep template
	bicepFile := bicepDir + "/main.bicep"
	cmd := shell.Command{
		Command: "az",
		Args: []string{"deployment", "sub", "create",
			"--no-prompt",
			"--verbose",
			"--name", deploymentName,
			"--template-file", bicepFile,
			"--parameters", paramsFile,
			"--subscription", subscriptionID},
	}

	// Defer cleanup of deployed resources only if shouldCleanup is true
	if shouldCleanup {
		t.Cleanup(func() {
			DestroyBicep(t, subscriptionID, resourceGroupName)
		})
	} else {
		t.Log("Skipping resource cleanup: shouldCleanup is false")
	}

	retry.DoWithRetry(t, "Bicep deployment", 3, 5*time.Second, func() (string, error) {
		return shell.RunCommandAndGetOutputE(t, cmd)
	})

	// Retrieve and return outputs
	return GetBicepOutputs(t, deploymentName)
}

// GetBicepOutputs retrieves outputs from an existing Bicep deployment without redeploying.
//
// Parameters:
//   - t: Test context for assertions and logging
//   - deploymentName: Name of existing Azure deployment to query
//
// Returns:
//   - map[string]any: Deployment outputs in Terraform-compatible format
//
// Behavior:
//   - Executes 'az deployment sub show' to query deployment outputs
//   - Retries on transient failures (3 attempts, 5 second delay)
//   - Converts Azure output format to Terraform-compatible format
//
// Output Format Conversion:
//
//	Azure CLI returns: {"outputName": {"type": "string", "value": "actual_value"}}
//	This function returns: {"outputName": "actual_value"}
//
// Requirements:
//   - Azure CLI must be installed and authenticated
//   - Deployment must exist in the current subscription
//
// Use Case:
//
//	Fetch outputs from existing deployment when SKIP_BICEP_DEPLOYMENT=true
func GetBicepOutputs(t *testing.T, deploymentName string) map[string]any {
	// Get deployment outputs using Azure CLI
	cmd := shell.Command{
		Command: "az",
		Args: []string{"deployment", "sub", "show",
			"--name", deploymentName,
			"--query", "properties.outputs",
			"-o", "json"},
	}

	output := retry.DoWithRetry(t, "Get Bicep outputs", 3, 5*time.Second, func() (string, error) {
		return shell.RunCommandAndGetOutputE(t, cmd)
	})

	outputBytes := []byte(output)

	var azureOutputs map[string]map[string]any
	err := json.Unmarshal(outputBytes, &azureOutputs)
	require.NoError(t, err, "Failed to parse Bicep outputs")

	// Convert Azure CLI output format to Terraform-compatible format
	// Azure outputs are in format: {"outputName": {"type": "string", "value": "actual_value"}}
	// Terraform outputs are in format: {"outputName": "actual_value"}
	terraformCompatible := make(map[string]any)
	for key, outputObj := range azureOutputs {
		if val, ok := outputObj["value"]; ok {
			terraformCompatible[key] = val
		}
	}

	return terraformCompatible
}

// DestroyTerraform executes 'terraform destroy' to tear down all deployed resources.
//
// Parameters:
//   - t: Test context for logging
//   - terraformOptions: Terraform options used during deployment (must match original)
//
// Behavior:
//   - Uses terraformOptions to ensure proper resource identification
//   - Terratest's built-in retry logic handles transient errors
//   - Blocks until all resources are destroyed
//
// Requirements:
//   - Terraform must be installed and available on PATH
//   - Azure authentication must be configured
//   - terraformOptions must match those used for deployment
//
// Note: Typically called automatically by DeployTerraform when shouldCleanup=true.
func DestroyTerraform(t *testing.T, terraformOptions *terraform.Options) {
	t.Log("Destroying Terraform-managed resources...")

	terraform.Destroy(t, terraformOptions)
}

// DestroyBicep executes 'az group delete' to tear down the resource group and all resources.
//
// Parameters:
//   - t: Test context for logging
//   - subscriptionID: Azure subscription ID containing the resource group
//   - resourceGroupName: Name of resource group to delete
//
// Behavior:
//   - Deletes resource group without confirmation prompt (--yes)
//   - Returns immediately without waiting for completion (--no-wait)
//   - Retries on transient failures (3 attempts, 5 second delay)
//
// Requirements:
//   - Azure CLI must be installed and authenticated
//   - Sufficient permissions to delete resource groups
//
// Warning: Deletes ALL resources in the resource group, not just those from deployment.
// Note: Typically called automatically by DeployBicep when shouldCleanup=true.
func DestroyBicep(t *testing.T, subscriptionID, resourceGroupName string) {
	t.Log("Destroying Bicep-managed resources...")

	cmd := shell.Command{
		Command: "az",
		Args: []string{"group", "delete",
			"--name", resourceGroupName,
			"--subscription", subscriptionID,
			"--yes",
			"--no-wait"},
	}

	retry.DoWithRetry(t, "Destroy Bicep resources", 3, 5*time.Second, func() (string, error) {
		return shell.RunCommandAndGetOutputE(t, cmd)
	})
}

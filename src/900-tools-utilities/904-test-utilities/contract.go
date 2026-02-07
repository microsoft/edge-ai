// Package testutil provides reusable testing utilities for blueprint deployment and validation.
// Functions in this file handle output contract validation between IaC and test code.
package testutil

import (
	"encoding/json"
	"os/exec"
	"path/filepath"
	"reflect"
	"strings"
	"testing"

	"github.com/stretchr/testify/require"
)

// GetTerraformDeclaredOutputs extracts all declared output names from Terraform configuration.
// Uses 'terraform-docs json' to parse outputs.tf without requiring terraform init or plan.
//
// Parameters:
//   - t: Test context for assertions and logging
//   - terraformDir: Absolute or relative path to directory containing Terraform files
//
// Returns:
//   - []string: Output names in the order they appear in outputs.tf
//
// Requirements:
//   - terraform-docs must be installed and available on PATH
//   - terraformDir must contain valid Terraform configuration files
//
// This is a static analysis tool - no deployment or Azure authentication required.
func GetTerraformDeclaredOutputs(t *testing.T, terraformDir string) []string {
	// Run terraform-docs to get output schema
	cmd := exec.Command("terraform-docs", "json", terraformDir)
	output, err := cmd.CombinedOutput()
	require.NoError(t, err, "Failed to run terraform-docs: %s\nOutput: %s", err, string(output))

	// Parse JSON output - terraform-docs returns outputs as an array of objects with "name" fields
	var result struct {
		Outputs []struct {
			Name string `json:"name"`
		} `json:"outputs"`
	}
	err = json.Unmarshal(output, &result)
	require.NoError(t, err, "Failed to parse terraform-docs JSON output: %s", string(output))

	// Extract output names
	keys := make([]string, 0, len(result.Outputs))
	for _, output := range result.Outputs {
		keys = append(keys, output.Name)
	}

	return keys
}

// GetBicepDeclaredOutputs extracts all declared output names from Bicep configuration.
// Uses 'az bicep build' to compile Bicep to ARM template JSON, then parses outputs.
//
// Parameters:
//   - t: Test context for assertions and logging
//   - bicepDir: Absolute or relative path to directory containing main.bicep
//
// Returns:
//   - []string: Output names extracted from compiled ARM template
//
// Requirements:
//   - Azure CLI with Bicep extension must be installed (az bicep install)
//   - bicepDir must contain valid main.bicep file
//
// Note: Output order may differ from declaration order due to ARM template compilation.
// This is a static analysis tool - no deployment or Azure authentication required.
func GetBicepDeclaredOutputs(t *testing.T, bicepDir string) []string {
	// Build Bicep to ARM template JSON
	// Use separate stdout/stderr to avoid warnings polluting JSON output
	bicepFile := filepath.Join(bicepDir, "main.bicep")
	cmd := exec.Command("az", "bicep", "build", "--file", bicepFile, "--stdout")
	stdout, err := cmd.Output()
	require.NoError(t, err, "Failed to compile Bicep: %v", err)

	// Parse ARM template JSON from stdout only
	var armTemplate struct {
		Outputs map[string]interface{} `json:"outputs"`
	}
	err = json.Unmarshal(stdout, &armTemplate)
	require.NoError(t, err, "Failed to parse ARM template JSON: %s", string(stdout))

	// Extract output keys
	keys := make([]string, 0, len(armTemplate.Outputs))
	for k := range armTemplate.Outputs {
		keys = append(keys, k)
	}

	return keys
}

// ValidateTerraformContract is a convenience function for validating Terraform output contracts.
// Combines GetTerraformDeclaredOutputs and ValidateOutputContract into a single call.
//
// Parameters:
//   - t: Test context for assertions and logging
//   - terraformDir: Absolute or relative path to directory containing Terraform files
//   - requiredOutputs: List of output names required by test code (from BlueprintOutputs)
//
// Fails the test if any required outputs are missing from Terraform configuration.
// This is the recommended way for blueprints to implement Terraform contract tests.
func ValidateTerraformContract(t *testing.T, terraformDir string, requiredOutputs []string) {
	declaredOutputs := GetTerraformDeclaredOutputs(t, terraformDir)
	ValidateOutputContract(t, declaredOutputs, requiredOutputs, "terraform")
}

// ValidateBicepContract is a convenience function for validating Bicep output contracts.
// Combines GetBicepDeclaredOutputs and ValidateOutputContract into a single call.
// Automatically converts required output names from snake_case to camelCase since
// Bicep uses camelCase for output names while test structs use snake_case tags.
//
// Parameters:
//   - t: Test context for assertions and logging
//   - bicepDir: Absolute or relative path to directory containing main.bicep
//   - requiredOutputs: List of output names required by test code (from BlueprintOutputs)
//     These should be in snake_case format and will be converted to camelCase
//
// Fails the test if any required outputs are missing from Bicep configuration.
// This is the recommended way for blueprints to implement Bicep contract tests.
func ValidateBicepContract(t *testing.T, bicepDir string, requiredOutputs []string) {
	declaredOutputs := GetBicepDeclaredOutputs(t, bicepDir)

	// Convert required outputs from snake_case to camelCase for Bicep comparison
	camelCaseRequiredOutputs := make([]string, len(requiredOutputs))
	for i, output := range requiredOutputs {
		camelCaseRequiredOutputs[i] = SnakeToCamelCase(output)
	}

	ValidateOutputContract(t, declaredOutputs, camelCaseRequiredOutputs, "bicep")
}

// ValidateOutputContract verifies all required outputs are declared in IaC configuration.
// Compares declared outputs (from IaC) against required outputs (from test struct).
//
// Parameters:
//   - t: Test context for assertions and logging
//   - declaredOutputs: Output names extracted from IaC (Terraform or Bicep)
//   - requiredOutputs: Output names required by test code
//   - framework: Framework name for error messages ("terraform" or "bicep")
//
// Behavior:
//   - Logs all declared and required outputs for transparency
//   - Identifies missing outputs by comparing slices
//   - Reports detailed error with missing output names if validation fails
//   - Fails test immediately if any required outputs are missing
//
// This validation ensures compile-time contract between IaC and test code.
func ValidateOutputContract(t *testing.T, declaredOutputs, requiredOutputs []string, framework string) {
	t.Logf("Declared outputs in %s: %v", framework, declaredOutputs)
	t.Logf("Required outputs by tests: %v", requiredOutputs)

	// Track missing outputs
	missing := []string{}
	declaredMap := make(map[string]bool)
	for _, declared := range declaredOutputs {
		declaredMap[declared] = true
	}

	for _, required := range requiredOutputs {
		if !declaredMap[required] {
			missing = append(missing, required)
		}
	}

	// Report results
	if len(missing) > 0 {
		t.Errorf("❌ Missing %d required outputs in %s: %v", len(missing), framework, missing)
		if framework == "terraform" {
			t.Errorf("   Ensure these outputs are declared in terraform/outputs.tf")
		} else if framework == "bicep" {
			t.Errorf("   Ensure these outputs are declared in bicep/main.bicep")
		}
	} else {
		t.Logf("✅ All %d required outputs are declared in %s", len(requiredOutputs), framework)
	}

	require.Empty(t, missing, "Output contract validation failed")
}

// ParseTerraformOutputsFromMap converts raw Terraform deployment outputs to a strongly-typed output struct using reflection.
// Uses struct field tags with `output` key to map output names to struct fields.
// Fails test immediately if any required output (with `output` tag) is missing from raw outputs.
// Note: This validates presence of output keys, not their values. Outputs can be nil/null.
//
// Parameters:
//   - t: Test context for assertions and logging
//   - raw: Raw output map from Terraform deployment (e.g., terraform.OutputAll)
//   - outputStruct: Pointer to struct with `output` tags defining expected outputs
//
// Example usage:
//
//	type MyOutputs struct {
//	    ResourceGroup string `output:"resource_group_name"`
//	    Location      string `output:"location"`
//	}
//	outputs := &MyOutputs{}
//	ParseTerraformOutputsFromMap(t, rawOutputs, outputs)
func ParseTerraformOutputsFromMap(t *testing.T, raw map[string]any, outputStruct any) {
	parseOutputsFromMap(t, raw, outputStruct, "terraform", func(key string) string { return key }, false)
}

// ParseBicepOutputsFromMap converts raw Bicep deployment outputs to a strongly-typed output struct.
// Similar to ParseTerraformOutputsFromMap but converts snake_case output tags to camelCase for Bicep lookup.
// Bicep outputs use camelCase while struct tags use snake_case for consistency with Terraform.
// Also recursively transforms map keys from camelCase to snake_case so validation code works unchanged.
//
// Parameters:
//   - t: Test context for assertions and logging
//   - raw: Raw output map from Bicep deployment
//   - outputStruct: Pointer to struct with `output` tags defining expected outputs (in snake_case)
//
// Example usage:
//
//	type MyOutputs struct {
//	    ResourceGroup string `output:"resource_group_name"`  // Maps to "resourceGroupName" in Bicep
//	    Location      string `output:"location"`
//	}
//	outputs := &MyOutputs{}
//	ParseBicepOutputsFromMap(t, rawOutputs, outputs)
func ParseBicepOutputsFromMap(t *testing.T, raw map[string]any, outputStruct any) {
	parseOutputsFromMap(t, raw, outputStruct, "bicep", SnakeToCamelCase, true)
}

// parseOutputsFromMap is the internal implementation for parsing deployment outputs.
// It uses a keyTransform function to convert output tag names before lookup.
// If transformMapKeys is true, it also recursively transforms map keys from camelCase to snake_case.
func parseOutputsFromMap(t *testing.T, raw map[string]any, outputStruct any, framework string, keyTransform func(string) string, transformMapKeys bool) {
	v := reflect.ValueOf(outputStruct)
	if v.Kind() != reflect.Ptr || v.Elem().Kind() != reflect.Struct {
		require.Fail(t, "outputStruct must be a pointer to a struct")
		return
	}

	v = v.Elem()
	typ := v.Type()

	var missingOutputs []string
	for i := 0; i < v.NumField(); i++ {
		field := typ.Field(i)
		outputKey := field.Tag.Get("output")

		if outputKey == "" {
			continue
		}

		lookupKey := keyTransform(outputKey)
		value, exists := raw[lookupKey]
		if !exists {
			missingOutputs = append(missingOutputs, lookupKey)
			continue
		}

		// Transform map keys from camelCase to snake_case for Bicep outputs
		if transformMapKeys {
			value = transformMapKeysRecursive(value)
		}

		fieldValue := v.Field(i)
		valueType := reflect.TypeOf(value)
		if value == nil || !fieldValue.CanSet() || !valueType.AssignableTo(fieldValue.Type()) {
			require.Fail(t, "Type mismatch for output",
				"Output key '%s' has a type mismatch: expected %s but got %v",
				lookupKey, fieldValue.Type(), valueType)
		}
		fieldValue.Set(reflect.ValueOf(value))
	}

	if len(missingOutputs) > 0 {
		var fileHint string
		if framework == "terraform" {
			fileHint = "terraform/outputs.tf"
		} else {
			fileHint = "bicep/main.bicep"
		}
		require.Fail(t, "Missing required deployment outputs",
			"The following %d output(s) are missing from deployment outputs: %v\n"+
				"Ensure these outputs are declared in %s",
			len(missingOutputs), missingOutputs, fileHint)
	}
}

// transformMapKeysRecursive recursively transforms map keys from camelCase to snake_case.
// This allows Bicep outputs (camelCase keys) to work with validation code that expects snake_case keys.
func transformMapKeysRecursive(value any) any {
	if value == nil {
		return nil
	}

	switch v := value.(type) {
	case map[string]any:
		result := make(map[string]any, len(v))
		for key, val := range v {
			snakeKey := CamelToSnakeCase(key)
			result[snakeKey] = transformMapKeysRecursive(val)
		}
		return result
	case []any:
		result := make([]any, len(v))
		for i, item := range v {
			result[i] = transformMapKeysRecursive(item)
		}
		return result
	default:
		return value
	}
}

// GetOutputKeysFromStruct extracts all output names defined in a struct using reflection.
// Uses struct field tags with `output` key to extract output names.
// Returns output names in the order they appear in the struct.
// Used by contract tests to validate IaC output declarations.
//
// Parameters:
//   - outputStruct: Struct instance (value or pointer) with `output` tags
//
// Returns: Slice of output names extracted from struct tags
//
// Example usage:
//
//	type MyOutputs struct {
//	    ResourceGroup string `output:"resource_group_name"`
//	    Location      string `output:"location"`
//	}
//	keys := GetOutputKeysFromStruct(MyOutputs{})
//	// Returns: []string{"resource_group_name", "location"}
func GetOutputKeysFromStruct(outputStruct any) []string {
	v := reflect.ValueOf(outputStruct)
	if v.Kind() == reflect.Ptr {
		v = v.Elem()
	}
	typ := v.Type()

	keys := make([]string, 0, typ.NumField())
	for i := 0; i < typ.NumField(); i++ {
		field := typ.Field(i)
		key := field.Tag.Get("output")
		if key != "" {
			keys = append(keys, key)
		}
	}
	return keys
}

// SnakeToCamelCase converts a snake_case string to camelCase.
// Used to transform output names from Terraform convention (snake_case) to Bicep convention (camelCase).
//
// Examples:
//
//	"deployment_summary" -> "deploymentSummary"
//	"azure_iot_operations" -> "azureIotOperations"
//	"acr_network_posture" -> "acrNetworkPosture"
//	"nat_gateway_public_ips" -> "natGatewayPublicIps"
func SnakeToCamelCase(s string) string {
	if s == "" {
		return s
	}

	parts := strings.Split(s, "_")
	if len(parts) == 1 {
		return strings.ToLower(s)
	}

	var result strings.Builder

	for i, part := range parts {
		if part == "" {
			continue
		}
		if i == 0 {
			result.WriteString(strings.ToLower(part))
		} else {
			result.WriteString(strings.ToUpper(part[:1]) + strings.ToLower(part[1:]))
		}
	}

	return result.String()
}

// CamelToSnakeCase converts a camelCase string to snake_case.
// Used to transform map keys from Bicep convention (camelCase) to Terraform convention (snake_case).
//
// Examples:
//
//	"resourceGroup" -> "resource_group"
//	"keyVaultName" -> "key_vault_name"
//	"aioIdentity" -> "aio_identity"
func CamelToSnakeCase(s string) string {
	if s == "" {
		return s
	}

	var result strings.Builder

	for i, r := range s {
		if i > 0 && r >= 'A' && r <= 'Z' {
			result.WriteByte('_')
		}
		result.WriteRune(r)
	}

	return strings.ToLower(result.String())
}

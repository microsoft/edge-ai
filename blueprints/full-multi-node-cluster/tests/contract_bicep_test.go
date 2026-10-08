package test

import (
	"testing"

	testutil "github.com/microsoft/edge-ai/src/900-tools-utilities/904-test-utilities"
)

// TestBicepOutputsContract validates Bicep output declarations against test requirements.
//
// Purpose:
//
//	Ensures all outputs defined in BlueprintOutputs struct are declared in bicep/main.bicep
//
// Behavior:
//   - Static analysis only - no deployment or Azure authentication required
//   - Uses az bicep build to compile Bicep to ARM template
//   - Extracts outputs from compiled ARM template JSON
//   - Automatically converts required output names from snake_case to camelCase
//     since Bicep uses camelCase convention while test structs use snake_case tags
//   - Compares against BlueprintOutputs.GetRequiredOutputKeys() (converted to camelCase)
//   - Fails if any required outputs are missing from main.bicep
//
// Naming Convention:
//   - BlueprintOutputs uses snake_case tags (e.g., "deployment_summary")
//   - Bicep outputs must use camelCase (e.g., "deploymentSummary")
//   - ValidateBicepContract handles the automatic conversion
//
// Requirements:
//   - Azure CLI with Bicep extension (az bicep install)
//   - Valid Bicep configuration in ../bicep
//
// Runtime: Typically completes in < 2 seconds
func TestBicepOutputsContract(t *testing.T) {
	var blueprint BlueprintOutputs
	testutil.ValidateBicepContract(t, "../bicep", blueprint.GetRequiredOutputKeys())
}

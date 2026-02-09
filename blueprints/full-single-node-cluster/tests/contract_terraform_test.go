package test

import (
	"testing"

	testutil "github.com/microsoft/edge-ai/src/900-tools-utilities/904-test-utilities"
)

// TestTerraformOutputsContract validates Terraform output declarations against test requirements.
//
// Purpose:
//
//	Ensures all outputs defined in BlueprintOutputs struct are declared in terraform/outputs.tf
//
// Behavior:
//   - Static analysis only - no deployment or Azure authentication required
//   - Uses terraform-docs to extract output declarations
//   - Compares against BlueprintOutputs.GetRequiredOutputKeys()
//   - Fails if any required outputs are missing from outputs.tf
//
// Requirements:
//   - terraform-docs must be installed (brew install terraform-docs)
//   - Valid Terraform configuration in ../terraform
//
// Runtime: Typically completes in < 1 second
func TestTerraformOutputsContract(t *testing.T) {
	var blueprint BlueprintOutputs
	testutil.ValidateTerraformContract(t, "../terraform", blueprint.GetRequiredOutputKeys())
}

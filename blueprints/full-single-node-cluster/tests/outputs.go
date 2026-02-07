// Package test provides validation and testing utilities for the full-single-node-cluster blueprint.
// This file defines the strongly-typed output contract between IaC and tests.
package test

import (
	"testing"

	testutil "github.com/microsoft/edge-ai/src/900-tools-utilities/904-test-utilities"
)

// BlueprintOutputs defines the complete contract between IaC outputs and test code.
// Every field must have an `output` tag matching the IaC output name.
// To add a new output: add field with tag, then declare output in both terraform/outputs.tf and bicep/main.bicep.
// Contract tests (terraform_outputs_contract_test.go and bicep_outputs_contract_test.go) enforce this at compile time.
type BlueprintOutputs struct {
	DeploymentSummary   map[string]any `output:"deployment_summary"`
	SecurityIdentity    map[string]any `output:"security_identity"`
	Observability       map[string]any `output:"observability"`
	NatGateway          any            `output:"nat_gateway"`
	NatGatewayPublicIps any            `output:"nat_gateway_public_ips"`
	DataStorage         map[string]any `output:"data_storage"`
	ContainerRegistry   map[string]any `output:"container_registry"`
	Messaging           map[string]any `output:"messaging"`
	VmHost              any            `output:"vm_host"`
	ArcConnectedCluster map[string]any `output:"arc_connected_cluster"`
	ClusterConnection   map[string]any `output:"cluster_connection"`
	AzureIotOperations  map[string]any `output:"azure_iot_operations"`
	Assets              map[string]any `output:"assets"`
	ACRNetworkPosture   any            `output:"acr_network_posture"`
}

// ParseTerraformBlueprintOutputs converts raw Terraform deployment outputs to strongly-typed BlueprintOutputs.
// Uses reflection to map outputs based on struct field tags.
// Fails test immediately if any required output is missing from raw outputs.
// Note: This validates presence of output keys, not their values. Outputs can be nil/null.
func ParseTerraformBlueprintOutputs(t *testing.T, raw map[string]any) *BlueprintOutputs {
	outputs := &BlueprintOutputs{}
	testutil.ParseTerraformOutputsFromMap(t, raw, outputs)
	return outputs
}

// ParseBicepBlueprintOutputs converts raw Bicep deployment outputs to strongly-typed BlueprintOutputs.
// Bicep outputs use camelCase while struct tags use snake_case.
// Uses reflection to map outputs based on struct field tags after converting to camelCase.
// Fails test immediately if any required output is missing from raw outputs.
func ParseBicepBlueprintOutputs(t *testing.T, raw map[string]any) *BlueprintOutputs {
	outputs := &BlueprintOutputs{}
	testutil.ParseBicepOutputsFromMap(t, raw, outputs)
	return outputs
}

// GetRequiredOutputKeys returns all output names defined in BlueprintOutputs struct.
// Uses reflection on struct tags to extract output names.
// Used by contract tests to validate IaC output declarations.
func (BlueprintOutputs) GetRequiredOutputKeys() []string {
	return testutil.GetOutputKeysFromStruct(BlueprintOutputs{})
}

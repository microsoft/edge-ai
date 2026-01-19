package test

import (
	"os"
	"testing"

	testutil "github.com/microsoft/edge-ai/src/900-tools-utilities/904-test-utilities"
	"github.com/stretchr/testify/require"
)

// TestTerraformFullSingleNodeClusterDeploy performs full Terraform deployment and validation.
//
// WARNING: Deploys real Azure resources that incur costs.
//
// Configuration via environment variables:
//
//	Required:
//	  ARM_SUBSCRIPTION_ID, TEST_ENVIRONMENT, TEST_LOCATION,
//	  TEST_RESOURCE_PREFIX, TEST_RESOURCE_GROUP_NAME
func TestTerraformFullSingleNodeClusterDeploy(t *testing.T) {
	t.Parallel()

	terraformDir := "../terraform"

	// Get test configuration from environment variables (set in run-deployment-tests.sh)
	environment := os.Getenv("TEST_ENVIRONMENT")
	require.NotEmpty(t, environment, "TEST_ENVIRONMENT environment variable must be set")

	location := os.Getenv("TEST_LOCATION")
	require.NotEmpty(t, location, "TEST_LOCATION environment variable must be set")

	resourcePrefix := os.Getenv("TEST_RESOURCE_PREFIX")
	require.NotEmpty(t, resourcePrefix, "TEST_RESOURCE_PREFIX environment variable must be set")

	resourceGroupName := os.Getenv("TEST_RESOURCE_GROUP_NAME")
	require.NotEmpty(t, resourceGroupName, "TEST_RESOURCE_GROUP_NAME environment variable must be set")

	// Required variables for deployment
	vars := map[string]any{
		"environment":                    environment,
		"location":                       location,
		"resource_prefix":                resourcePrefix,
		"resource_group_name":            resourceGroupName,
		"should_enable_opc_ua_simulator": true,
	}

	// Get subscription ID for Azure module functions
	subscriptionID := os.Getenv("ARM_SUBSCRIPTION_ID")
	require.NotEmpty(t, subscriptionID, "ARM_SUBSCRIPTION_ID environment variable must be set")

	// Check if resources should be cleaned up after test (defaults to false)
	shouldCleanup := os.Getenv("CLEANUP_RESOURCES") == "true"

	// Deploy using Terraform and get outputs
	rawOutputs := testutil.DeployTerraform(t, terraformDir, vars, shouldCleanup)

	// Parse outputs and setup permissions/proxy
	ctx := prepareTerraformOutputsAndSetup(t, rawOutputs, subscriptionID, resourceGroupName)

	// Validate deployment and run all tests (including Event Hub validation for Terraform)
	validateDeploymentWithMessaging(t, ctx, subscriptionID, resourceGroupName, resourcePrefix, location)
}

package test

import (
	"os"
	"testing"

	testutil "github.com/microsoft/edge-ai/src/900-tools-utilities/904-test-utilities"
	"github.com/stretchr/testify/require"
)

// TestBicepFullSingleNodeClusterDeploy performs full Bicep deployment and validation.
//
// WARNING: Deploys real Azure resources that incur costs.
//
// Configuration via environment variables:
//
//	Required (always):
//	  ARM_SUBSCRIPTION_ID, TEST_RESOURCE_GROUP_NAME, TEST_ENVIRONMENT,
//	  TEST_LOCATION, TEST_RESOURCE_PREFIX, TEST_INSTANCE
//
//	Required (for deployment):
//	  ADMIN_PASSWORD, CUSTOM_LOCATIONS_OID
//
//	Optional:
//	  SKIP_BICEP_DEPLOYMENT=true (use existing deployment outputs)
//	  BICEP_DEPLOYMENT_NAME=<name> (defaults to "bicep-deployment-test")
func TestBicepFullSingleNodeClusterDeploy(t *testing.T) {
	t.Parallel()

	bicepDir := "../bicep"

	// Get subscription ID for deployment
	subscriptionID := os.Getenv("ARM_SUBSCRIPTION_ID")
	require.NotEmpty(t, subscriptionID, "ARM_SUBSCRIPTION_ID environment variable must be set")

	// Check if we should skip deployment and use existing
	skipDeployment := os.Getenv("SKIP_BICEP_DEPLOYMENT") == "true"
	deploymentName := os.Getenv("BICEP_DEPLOYMENT_NAME")
	if deploymentName == "" {
		deploymentName = "bicep-deployment-test"
	}

	// Get test configuration from environment variables (set in run-deployment-tests.sh)
	resourceGroupName := os.Getenv("TEST_RESOURCE_GROUP_NAME")
	require.NotEmpty(t, resourceGroupName, "TEST_RESOURCE_GROUP_NAME environment variable must be set")

	environment := os.Getenv("TEST_ENVIRONMENT")
	require.NotEmpty(t, environment, "TEST_ENVIRONMENT environment variable must be set")

	location := os.Getenv("TEST_LOCATION")
	require.NotEmpty(t, location, "TEST_LOCATION environment variable must be set")

	resourcePrefix := os.Getenv("TEST_RESOURCE_PREFIX")
	require.NotEmpty(t, resourcePrefix, "TEST_RESOURCE_PREFIX environment variable must be set")

	instance := os.Getenv("TEST_INSTANCE")
	require.NotEmpty(t, instance, "TEST_INSTANCE environment variable must be set")

	var rawOutputs map[string]any

	if skipDeployment {
		// Use existing deployment - no password/OID required
		t.Logf("Skipping deployment, fetching outputs from existing deployment: %s", deploymentName)
		rawOutputs = testutil.GetBicepOutputs(t, deploymentName)
	} else {
		// Run full deployment
		adminPassword := os.Getenv("ADMIN_PASSWORD")
		require.NotEmpty(t, adminPassword, "ADMIN_PASSWORD environment variable must be set")

		customLocationsOid := os.Getenv("CUSTOM_LOCATIONS_OID")
		require.NotEmpty(t, customLocationsOid, "CUSTOM_LOCATIONS_OID environment variable must be set")

		// Required parameters for deployment (Bicep format)
		params := map[string]any{
			"common": map[string]any{
				"environment":    environment,
				"location":       location,
				"resourcePrefix": resourcePrefix,
				"instance":       instance,
			},
			"resourceGroupName":  resourceGroupName,
			"adminPassword":      adminPassword,
			"customLocationsOid": customLocationsOid,
		}

		// Check if resources should be cleaned up after test (defaults to false)
		shouldCleanup := os.Getenv("CLEANUP_RESOURCES") == "true"

		// Deploy using Bicep and get outputs
		rawOutputs = testutil.DeployBicep(t, bicepDir, subscriptionID, deploymentName, resourceGroupName, params, shouldCleanup)
	}

	// Parse outputs and setup permissions/proxy
	ctx := prepareBicepOutputsAndSetup(t, rawOutputs, subscriptionID, resourceGroupName)

	// Validate deployment and run all tests
	validateDeploymentWithoutMessaging(t, ctx, subscriptionID, resourceGroupName, resourcePrefix, location)
}

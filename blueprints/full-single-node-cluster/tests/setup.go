// Package test provides validation and testing utilities for the full-single-node-cluster blueprint.
// This file contains post-deployment setup functions for permissions and connectivity.
package test

import (
	"context"
	"fmt"
	"os/exec"
	"strings"
	"testing"
	"time"

	"github.com/Azure/azure-sdk-for-go/sdk/azcore/to"
	"github.com/Azure/azure-sdk-for-go/sdk/azidentity"
	"github.com/Azure/azure-sdk-for-go/sdk/resourcemanager/authorization/armauthorization/v2"
	"github.com/google/uuid"
	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/retry"
	msgraphsdk "github.com/microsoftgraph/msgraph-sdk-go"
	"github.com/stretchr/testify/require"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// setupEventHubPermissions assigns Event Hub Data Receiver role to the current user.
// This enables Event Hub message consumption in validation tests.
// Skips gracefully if Event Hub is not deployed or if permissions cannot be determined.
func setupEventHubPermissions(t *testing.T, outputs *BlueprintOutputs, subscriptionID, resourceGroupName string) {
	t.Helper()

	// Get Event Hub namespace name from outputs
	eventhubNamespace, ok := outputs.Messaging["eventhub_namespace_name"].(string)
	if !ok || eventhubNamespace == "" || eventhubNamespace == "Not deployed" {
		t.Log("Event Hub namespace not deployed, skipping role assignment")
		return
	}

	t.Logf("Configuring Event Hub permissions for namespace: %s", eventhubNamespace)

	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()

	// Create Azure credential
	cred, err := azidentity.NewDefaultAzureCredential(nil)
	if err != nil {
		t.Fatalf("Failed to create Azure credential: %v", err)
	}

	// Create Microsoft Graph client to get current user's principal ID
	graphClient, err := msgraphsdk.NewGraphServiceClientWithCredentials(cred, []string{"https://graph.microsoft.com/.default"})
	if err != nil {
		t.Logf("Failed to create Microsoft Graph client: %v", err)
		t.Log("⚠️  Skipping Event Hub role assignment")
		return
	}

	// Get current signed-in user
	user, err := graphClient.Me().Get(ctx, nil)
	if err != nil {
		t.Logf("Failed to get signed-in user from Microsoft Graph: %v", err)
		t.Log("⚠️  Skipping Event Hub role assignment. Please ensure you're signed in with proper permissions")
		return
	}

	if user.GetId() == nil {
		t.Log("⚠️  Unable to get user principal ID, skipping role assignment")
		return
	}

	principalID := *user.GetId()
	t.Logf("Current user principal ID: %s", principalID)

	// Azure Event Hubs Data Receiver role definition ID (built-in role, same across all tenants)
	roleDefinitionID := fmt.Sprintf("/subscriptions/%s/providers/Microsoft.Authorization/roleDefinitions/a638d3c7-ab3a-418d-83e6-5f17a39d4fde", subscriptionID)

	// Construct Event Hub namespace scope
	scope := fmt.Sprintf("/subscriptions/%s/resourceGroups/%s/providers/Microsoft.EventHub/namespaces/%s",
		subscriptionID, resourceGroupName, eventhubNamespace)

	// Create role assignments client
	roleClient, err := armauthorization.NewRoleAssignmentsClient(subscriptionID, cred, nil)
	if err != nil {
		t.Fatalf("Failed to create role assignments client: %v", err)
	}

	// Generate a unique name for the role assignment
	roleAssignmentName := uuid.New().String()

	// Create role assignment parameters
	params := armauthorization.RoleAssignmentCreateParameters{
		Properties: &armauthorization.RoleAssignmentProperties{
			PrincipalID:      to.Ptr(principalID),
			RoleDefinitionID: to.Ptr(roleDefinitionID),
			PrincipalType:    to.Ptr(armauthorization.PrincipalTypeUser),
		},
	}

	t.Log("Creating role assignment...")
	_, err = roleClient.Create(ctx, scope, roleAssignmentName, params, nil)
	if err != nil {
		// Role assignment might already exist, which is fine
		if strings.Contains(err.Error(), "RoleAssignmentExists") {
			t.Log("✓ Role assignment already exists")
		} else {
			t.Logf("⚠️  Failed to create role assignment: %v", err)
			t.Log("Tests may fail if Event Hub permissions are not configured")
		}
		return
	}

	t.Log("✓ Successfully assigned 'Azure Event Hubs Data Receiver' role")
}

// setupArcProxy establishes connectivity to the Arc-connected Kubernetes cluster.
// Starts 'az connectedk8s proxy' command and waits for connection to be ready.
// Returns proxy command (caller must terminate) and kubectl options configured for the proxy.
func setupArcProxy(t *testing.T, outputs *BlueprintOutputs) (*exec.Cmd, *k8s.KubectlOptions) {
	t.Helper()

	clusterConnection := outputs.ClusterConnection
	arcClusterName := clusterConnection["arc_cluster_name"].(string)
	arcResourceGroup := clusterConnection["arc_cluster_resource_group"].(string)

	proxyCmd := exec.Command("az",
		"connectedk8s",
		"proxy",
		"--name", arcClusterName,
		"--resource-group", arcResourceGroup,
	)

	err := proxyCmd.Start()
	require.NoError(t, err, "Failed to start Arc proxy")

	t.Logf("Arc proxy started (PID: %d)", proxyCmd.Process.Pid)

	t.Logf("Waiting for Arc proxy to establish connection...")
	kubectlOptions := k8s.NewKubectlOptions("", "", "")
	retry.DoWithRetry(t, "Wait for proxy", 6, 5*time.Second, func() (string, error) {
		_, err := k8s.ListNamespacesE(t, kubectlOptions, metav1.ListOptions{})
		if err != nil {
			return "", fmt.Errorf("proxy not ready yet: %v", err)
		}
		return "Proxy is ready", nil
	})

	t.Log("✓ Arc proxy connection established")
	return proxyCmd, kubectlOptions
}

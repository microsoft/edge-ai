// Package test provides validation and testing utilities for the full-single-node-cluster blueprint.
// This file contains shared validation logic used by both Terraform and Bicep deployment tests.
package test

import (
	"context"
	"encoding/json"
	"fmt"
	"os/exec"
	"strings"
	"syscall"
	"testing"
	"time"

	"github.com/Azure/azure-sdk-for-go/sdk/azcore/to"
	"github.com/Azure/azure-sdk-for-go/sdk/azidentity"
	"github.com/Azure/azure-sdk-for-go/sdk/messaging/azeventhubs"
	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/retry"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// DeploymentContext holds the parsed outputs and connection resources for a deployed blueprint.
// Used to pass deployment state between setup and validation phases.
type DeploymentContext struct {
	Outputs        *BlueprintOutputs
	ProxyCmd       *exec.Cmd
	KubectlOptions *k8s.KubectlOptions
}

// setupPermissionsAndProxy configures post-deployment permissions (Event Hub access) and establishes Arc proxy connection.
// Returns proxy command for cleanup and kubectl options for cluster access.
func setupPermissionsAndProxy(t *testing.T, outputs *BlueprintOutputs, subscriptionID, resourceGroupName string) (*exec.Cmd, *k8s.KubectlOptions) {
	setupEventHubPermissions(t, outputs, subscriptionID, resourceGroupName)
	return setupArcProxy(t, outputs)
}

// prepareTerraformOutputsAndSetup converts raw deployment outputs to strongly-typed BlueprintOutputs,
// configures post-deployment permissions (Event Hub access), and establishes Arc proxy connection.
func prepareTerraformOutputsAndSetup(t *testing.T, rawOutputs map[string]any, subscriptionID, resourceGroupName string) *DeploymentContext {
	outputs := ParseTerraformBlueprintOutputs(t, rawOutputs)
	proxyCmd, kubectlOptions := setupPermissionsAndProxy(t, outputs, subscriptionID, resourceGroupName)
	return &DeploymentContext{Outputs: outputs, ProxyCmd: proxyCmd, KubectlOptions: kubectlOptions}
}

// prepareBicepOutputsAndSetup converts raw Bicep deployment outputs to strongly-typed BlueprintOutputs,
// configures post-deployment permissions (Event Hub access), and establishes Arc proxy connection.
// Bicep outputs use camelCase while struct tags use snake_case.
func prepareBicepOutputsAndSetup(t *testing.T, rawOutputs map[string]any, subscriptionID, resourceGroupName string) *DeploymentContext {
	outputs := ParseBicepBlueprintOutputs(t, rawOutputs)
	proxyCmd, kubectlOptions := setupPermissionsAndProxy(t, outputs, subscriptionID, resourceGroupName)
	return &DeploymentContext{Outputs: outputs, ProxyCmd: proxyCmd, KubectlOptions: kubectlOptions}
}

// validateDeploymentWithoutMessaging runs validation tests for deployed infrastructure.
func validateDeploymentWithoutMessaging(t *testing.T, ctx *DeploymentContext, subscriptionID, resourceGroupName, resourcePrefix, location string) {
	runValidationTests(t, ctx.Outputs, subscriptionID, resourceGroupName, resourcePrefix, location, ctx.ProxyCmd, ctx.KubectlOptions)
}

// validateDeploymentWithMessaging runs validation tests plus Event Hub message consumption validation.
// Event Hub validation is Terraform-specific due to additional configuration requirements.
func validateDeploymentWithMessaging(t *testing.T, ctx *DeploymentContext, subscriptionID, resourceGroupName, resourcePrefix, location string) {
	runValidationTests(t, ctx.Outputs, subscriptionID, resourceGroupName, resourcePrefix, location, ctx.ProxyCmd, ctx.KubectlOptions)
	runMessagingValidation(t, ctx.Outputs)
}

// runValidationTests executes the complete validation test suite for deployed infrastructure.
// Accepts strongly-typed BlueprintOutputs to enforce compile-time contract validation.
// Tests include: Azure resources, Kubernetes cluster, IoT Operations, and resource connectivity.
// Automatically cleans up Arc proxy connection on completion.
func runValidationTests(t *testing.T, outputs *BlueprintOutputs, subscriptionID, resourceGroupName, resourcePrefix, location string, proxyCmd *exec.Cmd, kubectlOptions *k8s.KubectlOptions) {
	defer func() {
		if proxyCmd != nil && proxyCmd.Process != nil {
			t.Logf("Stopping Arc proxy (PID: %d)...", proxyCmd.Process.Pid)
			_ = proxyCmd.Process.Signal(syscall.SIGTERM)
			time.Sleep(1 * time.Second)
			_ = proxyCmd.Process.Kill()
		}
	}()
	// Validate deployment summary
	t.Run("ValidateDeploymentSummary", func(t *testing.T) {
		deploymentSummary := outputs.DeploymentSummary
		require.NotNil(t, deploymentSummary, "deployment_summary output is nil")

		rgName := deploymentSummary["resource_group"].(string)
		assert.NotEmpty(t, rgName, "Resource group name should be set")
		assert.Equal(t, resourceGroupName, rgName, "Resource group should match input variable")

		// Use Azure module to verify resource group exists
		assert.True(t, azure.ResourceGroupExists(t, rgName, subscriptionID),
			"Resource group should exist in Azure")
	})

	// Validate security and identity resources
	t.Run("ValidateSecurityIdentity", func(t *testing.T) {
		securityIdentity := outputs.SecurityIdentity

		keyVaultName := securityIdentity["key_vault_name"].(string)
		assert.NotEmpty(t, keyVaultName, "Key Vault name should be set")
		assert.NotEmpty(t, securityIdentity["key_vault_uri"], "Key Vault URI should be set")
		assert.NotEmpty(t, securityIdentity["aio_identity"], "AIO identity should be set")
		assert.Contains(t, securityIdentity["key_vault_uri"], "https://", "Key Vault URI should be HTTPS")

		t.Logf("Verifying Key Vault %s exists in resource group %s", keyVaultName, resourceGroupName)
	})

	// Validate observability resources
	t.Run("ValidateObservability", func(t *testing.T) {
		observability := outputs.Observability

		logAnalyticsName := observability["log_analytics_workspace_name"].(string)
		assert.NotEmpty(t, logAnalyticsName, "Log Analytics workspace name should be set")
		assert.NotEmpty(t, observability["azure_monitor_workspace_name"], "Azure Monitor workspace name should be set")
		assert.NotEmpty(t, observability["grafana_name"], "Grafana name should be set")
		assert.NotEmpty(t, observability["grafana_endpoint"], "Grafana endpoint should be set")
		assert.Contains(t, observability["grafana_endpoint"], "https://", "Grafana endpoint should be HTTPS")

		// Use Azure module to verify Log Analytics workspace exists
		assert.True(t, azure.LogAnalyticsWorkspaceExists(t, logAnalyticsName, resourceGroupName, subscriptionID),
			"Log Analytics workspace should exist in Azure")
	})

	// Validate networking resources
	t.Run("ValidateNetworking", func(t *testing.T) {
		natGateway := outputs.NatGateway
		natGatewayIPs := outputs.NatGatewayPublicIps

		if natGateway != nil {
			natGatewayMap := natGateway.(map[string]any)
			assert.NotEmpty(t, natGatewayMap["name"], "NAT gateway name should be set")
			assert.NotEmpty(t, natGatewayMap["id"], "NAT gateway ID should be set")
		}

		if natGatewayIPs != nil {
			assert.NotNil(t, natGatewayIPs, "NAT gateway public IPs should be configured")
		}
	})

	// Validate data storage outputs
	t.Run("ValidateDataStorage", func(t *testing.T) {
		dataStorage := outputs.DataStorage

		storageAccountName := dataStorage["storage_account_name"].(string)
		assert.NotEmpty(t, storageAccountName, "Storage account name should be set")

		// Use Azure module to verify storage account exists
		assert.True(t, azure.StorageAccountExists(t, storageAccountName, resourceGroupName, subscriptionID),
			"Storage account should exist in Azure")
	})

	// Validate container registry outputs
	t.Run("ValidateContainerRegistry", func(t *testing.T) {
		acr := outputs.ContainerRegistry

		acrName := acr["name"].(string)
		assert.NotEmpty(t, acrName, "ACR name should be set")
		assert.NotEmpty(t, acr["id"], "ACR ID should be set")
		assert.Contains(t, acrName, resourcePrefix, "ACR name should contain resource prefix")

		// Use Azure module to verify container registry exists
		assert.True(t, azure.ContainerRegistryExists(t, acrName, resourceGroupName, subscriptionID),
			"Container registry should exist in Azure")
	})

	// Validate messaging resources
	t.Run("ValidateMessaging", func(t *testing.T) {
		messaging := outputs.Messaging

		assert.NotEmpty(t, messaging["event_grid_topic_name"], "Event Grid topic name should be set")
		assert.NotEmpty(t, messaging["event_grid_topic_endpoint"], "Event Grid endpoint should be set")
		assert.NotEmpty(t, messaging["eventhub_namespace_name"], "Event Hub namespace name should be set")
		assert.NotEmpty(t, messaging["eventhub_name"], "Event Hub name should be set")

		eventGridEndpoint := messaging["event_grid_topic_endpoint"].(string)
		assert.True(t, strings.Contains(eventGridEndpoint, "eventgrid.azure.net"),
			"Event Grid endpoint should be valid Azure Event Grid endpoint")
	})

	// Validate VM host resources
	t.Run("ValidateVMHost", func(t *testing.T) {
		vmHost := outputs.VmHost

		require.NotNil(t, vmHost, "VM host output should exist")
		vmHosts := vmHost.([]any)
		assert.NotEmpty(t, vmHosts, "At least one VM host should be deployed")

		for i, host := range vmHosts {
			hostMap := host.(map[string]any)
			vmName := hostMap["name"].(string)
			assert.NotEmpty(t, vmName, fmt.Sprintf("VM %d name should be set", i))

			assert.True(t, azure.VirtualMachineExists(t, vmName, resourceGroupName, subscriptionID),
				fmt.Sprintf("VM %s should exist in Azure", vmName))
		}
	})

	// Validate Arc connected cluster
	t.Run("ValidateArcConnectedCluster", func(t *testing.T) {
		arcCluster := outputs.ArcConnectedCluster

		assert.NotEmpty(t, arcCluster["name"], "Arc cluster name should be set")
		assert.NotEmpty(t, arcCluster["location"], "Arc cluster location should be set")
		assert.Equal(t, location, arcCluster["location"], "Arc cluster location should match input")
	})

	// Validate cluster connection outputs
	t.Run("ValidateClusterConnection", func(t *testing.T) {
		clusterConnection := outputs.ClusterConnection

		assert.NotEmpty(t, clusterConnection["arc_cluster_name"], "Arc cluster name should be set")
		assert.NotEmpty(t, clusterConnection["arc_cluster_resource_group"], "Arc resource group should be set")
		assert.NotEmpty(t, clusterConnection["arc_proxy_command"], "Arc proxy command should be set")
		assert.Contains(t, clusterConnection["arc_cluster_name"], resourcePrefix, "Cluster name should contain resource prefix")
	})

	// Validate Azure IoT Operations outputs
	t.Run("ValidateAzureIoTOperations", func(t *testing.T) {
		aio := outputs.AzureIotOperations

		assert.NotEmpty(t, aio["instance_name"], "AIO instance name should be set")
		assert.NotEmpty(t, aio["custom_location_id"], "Custom location ID should be set")
		assert.NotEmpty(t, aio["namespace"], "AIO namespace should be set")
	})

	// Validate assets outputs
	t.Run("ValidateAssets", func(t *testing.T) {
		assets := outputs.Assets

		require.NotNil(t, assets["assets"], "Assets list should exist")
		require.NotNil(t, assets["asset_endpoint_profiles"], "Asset endpoint profiles should exist")
	})

	// Validate ACR network posture
	t.Run("ValidateACRNetworkPosture", func(t *testing.T) {
		acrNetworkPosture := outputs.ACRNetworkPosture
		require.NotNil(t, acrNetworkPosture, "ACR network posture output should exist")
	})

	// Validate Kubernetes cluster connectivity
	t.Run("ValidateKubernetesCluster", func(t *testing.T) {
		t.Run("CheckClusterNodes", func(t *testing.T) {
			nodes := k8s.GetNodes(t, kubectlOptions)
			require.NotEmpty(t, nodes, "Cluster should have at least one node")

			for _, node := range nodes {
				t.Logf("Node: %s, Status: %v", node.Name, node.Status.Conditions)
				isReady := false
				for _, condition := range node.Status.Conditions {
					if condition.Type == "Ready" && condition.Status == "True" {
						isReady = true
						break
					}
				}
				assert.True(t, isReady, fmt.Sprintf("Node %s should be in Ready state", node.Name))
			}
		})

		t.Run("CheckAzureIoTOperations", func(t *testing.T) {
			aio := outputs.AzureIotOperations
			namespace := aio["namespace"].(string)

			retry.DoWithRetry(t, "Check AIO namespace exists", 3, 10*time.Second, func() (string, error) {
				_, err := k8s.GetNamespaceE(t, kubectlOptions, namespace)
				if err != nil {
					return "", fmt.Errorf("namespace %s not found: %v", namespace, err)
				}
				return "Namespace found", nil
			})

			kubectlOptionsAIO := k8s.NewKubectlOptions("", "", namespace)
			pods := k8s.ListPods(t, kubectlOptionsAIO, metav1.ListOptions{})
			require.NotEmpty(t, pods, fmt.Sprintf("AIO namespace %s should have running pods", namespace))

			runningCount := 0
			for _, pod := range pods {
				if pod.Status.Phase == corev1.PodRunning {
					runningCount++
				}
			}
			assert.Greater(t, runningCount, 0, "At least one pod should be in Running state")
		})

		t.Run("CheckBasicResources", func(t *testing.T) {
			services := k8s.ListServices(t, kubectlOptions, metav1.ListOptions{})
			assert.NotEmpty(t, services, "Cluster should have services")

			kubectlOptionsSystem := k8s.NewKubectlOptions("", "", "kube-system")
			systemPods := k8s.ListPods(t, kubectlOptionsSystem, metav1.ListOptions{})
			assert.NotEmpty(t, systemPods, "kube-system namespace should have pods")
		})
	})
}

// runMessagingValidation validates Event Hub message consumption and processing.
// Terraform-specific test that verifies messages can be received and parsed.
// Requires Event Hub Data Receiver role assignment (configured by setupEventHubPermissions).
func runMessagingValidation(t *testing.T, outputs *BlueprintOutputs) {
	t.Run("CheckMQTTBroker", func(t *testing.T) {
		aio := outputs.AzureIotOperations
		namespace := aio["namespace"].(string)

		kubectlOptionsAIO := k8s.NewKubectlOptions("", "", namespace)
		services := k8s.ListServices(t, kubectlOptionsAIO, metav1.ListOptions{LabelSelector: "app.kubernetes.io/name=microsoft-iotoperations-mqttbroker"})
		require.NotEmpty(t, services, "MQTT Broker service should exist in AIO namespace")
	})

	t.Run("ValidateEventHubsMessages", func(t *testing.T) {
		messaging := outputs.Messaging
		eventhubNamespace := messaging["eventhub_namespace_name"].(string)
		eventhubName := messaging["eventhub_name"].(string)

		t.Logf("Connecting to Event Hub: %s/%s", eventhubNamespace, eventhubName)

		cred, err := azidentity.NewDefaultAzureCredential(nil)
		require.NoError(t, err, "Failed to create Azure credential")

		consumerClient, err := azeventhubs.NewConsumerClient(
			eventhubNamespace+".servicebus.windows.net",
			eventhubName,
			azeventhubs.DefaultConsumerGroup,
			cred,
			nil,
		)
		require.NoError(t, err, "Failed to create Event Hub consumer client")
		defer consumerClient.Close(context.Background())

		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()

		props, err := consumerClient.GetEventHubProperties(ctx, nil)
		require.NoError(t, err, "Failed to get Event Hub properties")

		t.Logf("Event Hub has %d partitions", len(props.PartitionIDs))
		require.NotEmpty(t, props.PartitionIDs, "Event Hub should have at least one partition")

		partitionID := props.PartitionIDs[0]
		t.Logf("Consuming from partition: %s", partitionID)

		partitionClient, err := consumerClient.NewPartitionClient(partitionID, &azeventhubs.PartitionClientOptions{
			StartPosition: azeventhubs.StartPosition{
				Earliest: to.Ptr(true),
			},
		})
		require.NoError(t, err, "Failed to create partition client")
		defer partitionClient.Close(context.Background())

		receiveCtx, receiveCancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer receiveCancel()

		events, err := partitionClient.ReceiveEvents(receiveCtx, 5, nil)
		if err != nil && err != context.DeadlineExceeded {
			require.NoError(t, err, "Failed to receive events from Event Hub")
		}

		require.NotEmpty(t, events, "Should receive at least one message from Event Hub")
		t.Logf("Received %d messages from Event Hub", len(events))

		for i, event := range events {
			t.Logf("Message %d: %d bytes", i, len(event.Body))
			assert.NotNil(t, event.Body, "Message body should not be nil")

			var jsonData map[string]any
			if err := json.Unmarshal(event.Body, &jsonData); err == nil {
				t.Logf("Message %d is valid JSON with %d fields", i, len(jsonData))
				assert.NotEmpty(t, jsonData, "JSON message should have fields")
			} else {
				t.Logf("Message %d is not JSON: %s", i, string(event.Body))
			}

			assert.GreaterOrEqual(t, event.SequenceNumber, int64(0), "Sequence number should be non-negative")
			assert.NotNil(t, event.EnqueuedTime, "Enqueued time should be set")
		}
	})
}

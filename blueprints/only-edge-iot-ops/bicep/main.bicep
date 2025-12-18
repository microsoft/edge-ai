metadata name = 'Only Edge IoT Ops Blueprint'
metadata description = 'Deploys Azure IoT Operations on an existing Arc-enabled Kubernetes cluster without setting up cloud resources.'

import * as core from './types.core.bicep'
import * as assetTypes from '../../../src/100-edge/111-assets/bicep/types.bicep'
/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

@description('Whether to opt-out of telemetry. Set to true to disable telemetry.')
param telemetry_opt_out bool = false

/*
  Custom Location Parameters
*/

@description('The name for the Custom Locations resource.')
param customLocationName string = '${arcConnectedClusterName}-cl'

/*
  Trust Configuration Parameters
*/

// Currently disable setting shouldDeployAioDeploymentScripts, remove when DeploymentScripts supports AZ CLI 2.71+ (post May 4)
// @description('The trust issuer settings for Customer Managed Azure IoT Operations Settings.')
// param trustIssuerSettings types.TrustIssuerConfig = { trustSource: 'SelfSigned' }
var trustIssuerSettings = { trustSource: 'SelfSigned' }

/*
  Secret Sync and Key Vault Parameters
*/

@description('The name of the User Assigned Managed Identity for Secret Sync Extension.')
param sseIdentityName string = 'id-${common.resourcePrefix}-sse-${common.environment}-${common.instance}'

@description('The name of the Key Vault for Secret Sync Extension. Required when providing sseIdentityName.')
param sseKeyVaultName string = 'kv-${common.resourcePrefix}-${common.environment}-${common.instance}'

@description('The name of the Resource Group for the Key Vault for Secret Sync Extension. Required when providing sseIdentityName.')
param sseKeyVaultResourceGroupName string = resourceGroup().name

@description('Whether to assign roles for Key Vault to the provided Secret Sync Identity.')
param shouldAssignSseKeyVaultRoles bool = true

/*
  Deployment Identity and Script Parameters
*/

@description('The name of the Key Vault that will have scripts and secrets for deployment.')
param deployKeyVaultName string = sseKeyVaultName

@description('The resource name for a managed identity that will be given deployment admin permissions.')
param deployIdentityName string = 'id-${common.resourcePrefix}-deploy-${common.environment}-${common.instance}'

@description('The resource group name where the Key Vault is located. Defaults to the current resource group.')
param deployKeyVaultResourceGroupName string = sseKeyVaultResourceGroupName

@description('The name of the secret in Key Vault that has the token for the deploy user with cluster-admin role.')
param deployUserTokenSecretName string?

@description('The prefix used with constructing the secret name that will have the deployment script.')
param deploymentScriptsSecretNamePrefix string = '${common.resourcePrefix}-${common.environment}-${common.instance}'

// Currently disable setting shouldDeployAioDeploymentScripts, remove when DeploymentScripts supports AZ CLI 2.71+ (post May 4)
// @description('Whether to deploy DeploymentScripts for Azure IoT Operations.')
// param shouldDeployAioDeploymentScripts bool = false
var shouldDeployAioDeploymentScripts = false

@description('Whether to assign roles to the deploy identity.')
param shouldAssignDeployIdentityRoles bool = true

/*
  Azure IoT Operations Init Parameters
*/

@description('Whether to init Azure IoT Operations. (For debugging)')
param shouldInitAio bool = true

/*
  Azure IoT Operations Instance Parameters
*/

@description('The name of the User Assigned Managed Identity for Azure IoT Operations.')
param aioIdentityName string = 'id-${common.resourcePrefix}-aio-${common.environment}-${common.instance}'

@description('The name for the Azure IoT Operations Instance resource.')
param aioInstanceName string = '${arcConnectedClusterName}-ops-instance'

@description('The resource name for the Arc-enabled Kubernetes cluster.')
param arcConnectedClusterName string = 'arck-${common.resourcePrefix}-${common.environment}-${common.instance}'

@description('The resource name for the Azure Data Registry Schema Registry for Azure IoT Operations.')
param schemaRegistryName string = 'sr-${common.resourcePrefix}-${common.environment}-${common.instance}'

@description('The resource name for the ADR Namespace for Azure IoT Operations. Optional parameter for referencing an existing ADR namespace.')
param adrNamespaceName string?

@description('Whether to deploy Azure IoT Operations. (For debugging)')
param shouldDeployAio bool = true

@description('Whether to enable an insecure anonymous Azure IoT Operations MQ Broker Listener. Should only be used for dev or test environments.')
param shouldCreateAnonymousBrokerListener bool = false

@description('Whether to deploy Custom Locations Resource Sync Rules for the Azure IoT Operations resources.')
param shouldDeployResourceSyncRules bool = true

// Currently disable setting shouldDeployAioDeploymentScripts, remove when DeploymentScripts supports AZ CLI 2.71+ (post May 4)
// @description('Whether or not to enable the Open Telemetry Collector for Azure IoT Operations.')
// param shouldEnableOtelCollector bool = true
var shouldEnableOtelCollector = false

// Currently disable setting shouldDeployAioDeploymentScripts, remove when DeploymentScripts supports AZ CLI 2.71+ (post May 4)
// @description('Whether or not to enable the OPC UA Simulator and deploy ADR Asset for Azure IoT Operations.')
// param shouldEnableOpcUaSimulator bool = true
var shouldEnableOpcUaSimulator = false

/*
  Device Configuration Parameters
*/

@description('List of namespaced devices to create.')
param namespacedDevices assetTypes.NamespacedDevice[] = []

/*
  Legacy Asset Configuration Parameters
*/

@description('List of asset endpoint profiles to create.')
param assetEndpointProfiles assetTypes.AssetEndpointProfile[] = []

@description('List of legacy assets to create.')
param legacyAssets assetTypes.LegacyAsset[] = []

/*
  Namespaced Asset Configuration Parameters
*/

@description('List of namespaced assets to create.')
param namespacedAssets assetTypes.NamespacedAsset[] = []

/*
  Resources
*/

resource attribution 'Microsoft.Resources/deployments@2020-06-01' = if (!telemetry_opt_out) {
  name: 'pid-acce1e78-0375-4637-a593-86aa36dcfeac'
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
}

/*
  Modules
*/

module edgeIotOps '../../../src/100-edge/110-iot-ops/bicep/main.bicep' = {
  name: '${deployment().name}-eio0'
  params: {
    common: common

    // Azure IoT Operations Instance Parameters
    aioIdentityName: aioIdentityName
    aioInstanceName: aioInstanceName
    arcConnectedClusterName: arcConnectedClusterName
    schemaRegistryName: schemaRegistryName
    adrNamespaceName: adrNamespaceName
    shouldCreateAnonymousBrokerListener: shouldCreateAnonymousBrokerListener
    shouldDeployAio: shouldDeployAio
    shouldDeployResourceSyncRules: shouldDeployResourceSyncRules
    shouldEnableOpcUaSimulator: shouldEnableOpcUaSimulator
    shouldEnableOtelCollector: shouldEnableOtelCollector

    // Azure IoT Operations Init Parameters
    shouldInitAio: shouldInitAio

    // Custom Location Parameters
    customLocationName: customLocationName

    // Trust Configuration Parameters
    trustIssuerSettings: trustIssuerSettings

    // Secret Sync and Key Vault Parameters
    shouldAssignSseKeyVaultRoles: shouldAssignSseKeyVaultRoles
    sseIdentityName: sseIdentityName
    sseKeyVaultName: sseKeyVaultName
    sseKeyVaultResourceGroupName: sseKeyVaultResourceGroupName

    // Deployment Identity and Script Parameters
    deployIdentityName: deployIdentityName
    deployKeyVaultName: deployKeyVaultName
    deployKeyVaultResourceGroupName: deployKeyVaultResourceGroupName
    deployUserTokenSecretName: deployUserTokenSecretName
    deploymentScriptsSecretNamePrefix: deploymentScriptsSecretNamePrefix
    shouldAssignDeployIdentityRoles: shouldAssignDeployIdentityRoles
    shouldDeployAioDeploymentScripts: shouldDeployAioDeploymentScripts
  }
}

module edgeAssets '../../../src/100-edge/111-assets/bicep/main.bicep' = {
  name: '${deployment().name}-ea1'
  params: {
    common: common
    customLocationId: edgeIotOps.outputs.customLocationId
    adrNamespaceName: adrNamespaceName!
    shouldCreateDefaultNamespacedAsset: shouldEnableOpcUaSimulator
    namespacedDevices: namespacedDevices
    assetEndpointProfiles: assetEndpointProfiles
    legacyAssets: legacyAssets
    namespacedAssets: namespacedAssets
  }
}

/*
  Outputs
*/

@description('The ID of the Azure IoT Operations Cert-Manager Extension.')
output aioCertManagerExtensionId string = edgeIotOps.outputs.aioCertManagerExtensionId

@description('The name of the Azure IoT Operations Cert-Manager Extension.')
output aioCertManagerExtensionName string = edgeIotOps.outputs.aioCertManagerExtensionName

@description('The ID of the Secret Store Extension.')
output secretStoreExtensionId string = edgeIotOps.outputs.secretStoreExtensionId

@description('The name of the Secret Store Extension.')
output secretStoreExtensionName string = edgeIotOps.outputs.secretStoreExtensionName

@description('The ID of the deployed Custom Location.')
output customLocationId string = edgeIotOps.outputs.customLocationId

@description('The name of the deployed Custom Location.')
output customLocationName string = edgeIotOps.outputs.customLocationName

@description('The ID of the deployed Azure IoT Operations instance.')
output aioInstanceId string = edgeIotOps.outputs.aioInstanceId

@description('The name of the deployed Azure IoT Operations instance.')
output aioInstanceName string = edgeIotOps.outputs.aioInstanceName

@description('The ID of the deployed Azure IoT Operations Data Flow Profile.')
output dataFlowProfileId string = edgeIotOps.outputs.dataFlowProfileId

@description('The name of the deployed Azure IoT Operations Data Flow Profile.')
output dataFlowProfileName string = edgeIotOps.outputs.dataFlowProfileName

@description('The ID of the deployed Azure IoT Operations Data Flow Endpoint.')
output dataFlowEndpointId string = edgeIotOps.outputs.dataFlowEndpointId

@description('The name of the deployed Azure IoT Operations Data Flow Endpoint.')
output dataFlowEndpointName string = edgeIotOps.outputs.dataFlowEndpointName

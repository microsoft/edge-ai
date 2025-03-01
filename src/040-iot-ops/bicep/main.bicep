import * as core from './types.core.bicep'
import * as types from './types.bicep'

@description('The common component configuration.')
param common core.Common

@description('The resource name for the Arc connected cluster.')
param arcConnectedClusterName string

/*
  Azure IoT Operations Init Parameters
*/

@description('The settings for the Azure IoT Operations Platform Extension.')
param aioPlatformConfig types.AioPlatformExtension = types.aioPlatformExtensionDefaults

@description('The settings for the Azure Container Store for Azure Arc Extension.')
param containerStorageConfig types.ContainerStorageExtension = types.containerStorageExtensionDefaults

@description('The settings for the Open Service Mesh Extension.')
param openServiceMeshConfig types.OpenServiceMeshExtension = types.openServiceMeshExtensionDefaults

@description('The settings for the Secret Store Extension.')
#disable-next-line secure-secrets-in-params
param secretStoreConfig types.SecretStoreExtension = types.secretStoreExtensionDefaults

/*
  Azure IoT Operations Instance Parameters
*/

@description('The settings for the Azure IoT Operations Extension.')
param aioExtensionConfig types.AioExtension = types.aioExtensionDefaults

@description('Whether or not to deploy the Custom Locations Resource Sync Rules for the Azure IoT Operations resources.')
param shouldDeployResourceSyncRules bool = true

@description('The settings for the Azure IoT Operations MQ Broker.')
param aioMqBrokerConfig types.AioMqBroker = types.aioMqBrokerDefaults

@description('The settings for Azure IoT Operations Data Flow Instances.')
param aioDataFlowInstanceConfig types.AioDataFlowInstance = types.aioDataFlowInstanceDefaults

@description('The name for the Custom Locations resource.')
param customLocationName string = '${arcConnectedClusterName}-cl'

@description('The name for the Azure IoT Operations Instance resource.')
param aioInstanceName string = '${arcConnectedClusterName}-ops-instance'

@description('The name of the User Assigned Managed Identity for Azure IoT Operations.')
param aioUserAssignedIdentityName string?

@description('The resource ID for the User Assigned Identity for Azure IoT Operations.')
param aioUserAssignedIdentityId string?

@description('The resource ID for the ADR Schema Registry for Azure IoT Operations.')
param schemaRegistryId string

@description('Whether or not to enable the Open Telemetry Collector for Azure IoT Operations.')
param shouldEnableOtelCollector bool = false

@description('The source for trust for Azure IoT Operations.')
param trustSource types.TrustSource = 'SelfSigned'

/*
  Additional Azure IoT Operations Post Install Parameters
*/

@description('The name of the User Assigned Managed Identity for Secret Sync.')
param sseUserAssignedIdentityName string?

@description('The name of the Key Vault for Secret Sync. (Required when providing sseUserManagedIdentityName)')
param sseKeyVaultName string?

/*
  Modules
*/

module iotOpsInit 'modules/iot-ops-init.bicep' = {
  name: '${common.resourcePrefix}-iotOpsInit'
  params: {
    aioPlatformConfig: aioPlatformConfig
    arcConnectedClusterName: arcConnectedClusterName
    containerStorageConfig: containerStorageConfig
    openServiceMeshConfig: openServiceMeshConfig
    secretStoreConfig: secretStoreConfig
  }
}

module iotOpsInstance 'modules/iot-ops-instance.bicep' = {
  name: '${common.resourcePrefix}-iotOpsInstance'
  params: {
    aioDataFlowInstanceConfig: aioDataFlowInstanceConfig
    aioExtensionConfig: aioExtensionConfig
    aioInstanceName: aioInstanceName
    aioMqBrokerConfig: aioMqBrokerConfig
    aioPlatformExtensionId: iotOpsInit.outputs.aioPlatformExtensionId
    aioUserAssignedIdentityId: aioUserAssignedIdentityId
    arcConnectedClusterName: arcConnectedClusterName
    common: common
    customLocationName: customLocationName
    schemaRegistryId: schemaRegistryId
    secretStoreExtensionId: iotOpsInit.outputs.secretStoreExtensionId
    shouldDeployResourceSyncRules: shouldDeployResourceSyncRules
    shouldEnableOtelCollector: shouldEnableOtelCollector
    trustSource: trustSource
  }
}

module iotOpsInstancePost 'modules/iot-ops-instance-post.bicep' = {
  name: '${common.resourcePrefix}-iotOpsInstancePost'
  params: {
    aioNamespace: aioExtensionConfig.settings.namespace
    aioUserManagedIdentityName: aioUserAssignedIdentityName
    arcConnectedClusterName: arcConnectedClusterName
    common: common
    customLocationId: iotOpsInstance.outputs.customLocationId
    sseKeyVaultName: sseKeyVaultName
    sseUserManagedIdentityName: sseUserAssignedIdentityName
  }
}

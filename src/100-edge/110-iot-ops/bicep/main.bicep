metadata name = 'Azure IoT Operations'
metadata description = 'Deploys Azure IoT Operations extensions, instances, and configurations on Azure Arc-enabled Kubernetes clusters.'

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

@description('Whether to enable an insecure anonymous AIO MQ Broker Listener. (Should only be used for dev or test environments)')
param shouldCreateAnonymousBrokerListener bool = false

@description('Configuration for the insecure anonymous AIO MQ Broker Listener.')
param brokerListenerAnonymousConfig types.AioMqBrokerAnonymous = types.aioMqBrokerAnonymousDefaults

@description('The settings for Azure IoT Operations Data Flow Instances.')
param aioDataFlowInstanceConfig types.AioDataFlowInstance = types.aioDataFlowInstanceDefaults

@description('The name for the Custom Locations resource.')
param customLocationName string = '${arcConnectedClusterName}-cl'

@description('The name for the Azure IoT Operations Instance resource.')
param aioInstanceName string = '${arcConnectedClusterName}-ops-instance'

@description('The name of the User Assigned Managed Identity for Azure IoT Operations.')
param aioIdentityName string

@description('The resource name for the ADR Schema Registry for Azure IoT Operations.')
param schemaRegistryName string

@description('Whether or not to enable the Open Telemetry Collector for Azure IoT Operations.')
param shouldEnableOtelCollector bool = false

@description('The source for trust for Azure IoT Operations.')
param trustSource types.TrustSource = 'SelfSigned'

/*
  Azure IoT Operations Post Install and Role Assignment Parameters
*/

@description('Whether to assign roles for Key Vault to the provided Secret Sync Identity.')
param shouldAssignKeyVaultRoles bool = true

@description('The name of the User Assigned Managed Identity for Secret Sync.')
param sseIdentityName string

@description('The name of the Key Vault for Secret Sync. (Required when providing sseUserManagedIdentityName)')
param sseKeyVaultName string

/*
  Modules
*/

module roleAssignment 'modules/role-assignment.bicep' = if (shouldAssignKeyVaultRoles) {
  name: '${deployment().name}-roleAssignment'
  params: {
    keyVaultName: sseKeyVaultName
    sseUserAssignedIdentityName: sseIdentityName
  }
}

module iotOpsInit 'modules/iot-ops-init.bicep' = {
  name: '${deployment().name}-iotOpsInit'
  params: {
    aioPlatformConfig: aioPlatformConfig
    arcConnectedClusterName: arcConnectedClusterName
    containerStorageConfig: containerStorageConfig
    openServiceMeshConfig: openServiceMeshConfig
    secretStoreConfig: secretStoreConfig
  }
}

module iotOpsInstance 'modules/iot-ops-instance.bicep' = {
  name: '${deployment().name}-iotOpsInstance'
  params: {
    aioDataFlowInstanceConfig: aioDataFlowInstanceConfig
    aioExtensionConfig: aioExtensionConfig
    aioInstanceName: aioInstanceName
    aioMqBrokerConfig: aioMqBrokerConfig
    aioPlatformExtensionId: iotOpsInit.outputs.aioPlatformExtensionId
    arcConnectedClusterName: arcConnectedClusterName
    brokerListenerAnonymousConfig: brokerListenerAnonymousConfig
    common: common
    customLocationName: customLocationName
    secretStoreExtensionId: iotOpsInit.outputs.secretStoreExtensionId
    shouldCreateAnonymousBrokerListener: shouldCreateAnonymousBrokerListener
    shouldDeployResourceSyncRules: shouldDeployResourceSyncRules
    shouldEnableOtelCollector: shouldEnableOtelCollector
    trustSource: trustSource
    aioIdentityName: aioIdentityName
    schemaRegistryName: schemaRegistryName
  }
}

module iotOpsInstancePost 'modules/iot-ops-instance-post.bicep' = {
  name: '${deployment().name}-iotOpsInstancePost'
  params: {
    aioNamespace: aioExtensionConfig.settings.namespace
    aioIdentityName: aioIdentityName
    arcConnectedClusterName: arcConnectedClusterName
    common: common
    customLocationId: iotOpsInstance.outputs.customLocationId
    sseKeyVaultName: sseKeyVaultName
    sseIdentityName: sseIdentityName
  }
}

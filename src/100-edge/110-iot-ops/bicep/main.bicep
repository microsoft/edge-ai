metadata name = 'Azure IoT Operations'
metadata description = 'Deploys Azure IoT Operations extensions, instances, and configurations on Azure Arc-enabled Kubernetes clusters.'

import * as core from './types.core.bicep'
import * as types from './types.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

@description('The resource name for the Arc connected cluster.')
param arcConnectedClusterName string

/*
  Azure IoT Operations Init Parameters
*/

@description('The settings for the Azure Container Store for Azure Arc Extension.')
param containerStorageConfig types.ContainerStorageExtension = types.containerStorageExtensionDefaults

@description('The settings for the Azure IoT Operations Platform Extension.')
param aioPlatformConfig types.AioPlatformExtension = types.aioPlatformExtensionDefaults

@description('The settings for the Secret Store Extension.')
#disable-next-line secure-secrets-in-params
param secretStoreConfig types.SecretStoreExtension = types.secretStoreExtensionDefaults

@description('Whether to deploy the Azure IoT Operations initial connected cluster resources, Secret Sync, ACSA, OSM, AIO Platform.')
param shouldInitAio bool = true

/*
  Azure IoT Operations Instance Parameters
*/

@description('The name of the User Assigned Managed Identity for Azure IoT Operations.')
param aioIdentityName string

@description('The settings for the Azure IoT Operations Extension.')
param aioExtensionConfig types.AioExtension = types.aioExtensionDefaults

@description('AIO Instance features.')
param aioFeatures types.AioFeatures?

@description('The name for the Azure IoT Operations Instance resource.')
param aioInstanceName string = '${arcConnectedClusterName}-ops-instance'

@description('The settings for Azure IoT Operations Data Flow Instances.')
param aioDataFlowInstanceConfig types.AioDataFlowInstance = types.aioDataFlowInstanceDefaults

@description('The settings for the Azure IoT Operations MQ Broker.')
param aioMqBrokerConfig types.AioMqBroker = types.aioMqBrokerDefaults

@description('Configuration for the insecure anonymous AIO MQ Broker Listener.')
param brokerListenerAnonymousConfig types.AioMqBrokerAnonymous = types.aioMqBrokerAnonymousDefaults

@description('The resource name for the ADR Schema Registry for Azure IoT Operations.')
param schemaRegistryName string

@description('Whether to deploy an Azure IoT Operations Instance and all of its required components into the connected cluster.')
param shouldDeployAio bool = true

@description('Whether or not to deploy the Custom Locations Resource Sync Rules for the Azure IoT Operations resources.')
param shouldDeployResourceSyncRules bool = true

@description('Whether to enable an insecure anonymous AIO MQ Broker Listener. (Should only be used for dev or test environments)')
param shouldCreateAnonymousBrokerListener bool = false

@description('Whether or not to enable the Open Telemetry Collector for Azure IoT Operations.')
param shouldEnableOtelCollector bool = true

@description('Whether or not to enable the OPC UA Simulator for Azure IoT Operations.')
param shouldEnableOpcUaSimulator bool = true

@description('Whether or not to create the OPC UA Simulator ADR Asset for Azure IoT Operations.')
param shouldEnableOpcUaSimulatorAsset bool = shouldEnableOpcUaSimulator

/*
  Custom Location Parameters
*/

@description('The name for the Custom Locations resource.')
param customLocationName string = '${arcConnectedClusterName}-cl'

/*
  Trust Configuration Parameters
*/

@description('The trust issuer settings for Customer Managed Azure IoT Operations Settings.')
param trustIssuerSettings types.TrustIssuerConfig = { trustSource: 'SelfSigned' }

/*
  Secret Sync and Key Vault Parameters
*/

@description('The name of the Key Vault for Secret Sync. (Required when providing sseIdentityName)')
param sseKeyVaultName string

@description('The name of the User Assigned Managed Identity for Secret Sync.')
param sseIdentityName string

@description('The name of the Resource Group for the Key Vault for Secret Sync. (Required when providing sseIdentityName)')
param sseKeyVaultResourceGroupName string = resourceGroup().name

@description('Whether to assign roles for Key Vault to the provided Secret Sync Identity.')
param shouldAssignSseKeyVaultRoles bool = true

/*
  Deployment Identity and Script Parameters
*/

@description('Whether to assign roles to the deploy identity.')
param shouldAssignDeployIdentityRoles bool = !empty(deployIdentityName)

@description('The resource name for a managed identity that will be given deployment admin permissions.')
param deployIdentityName string?

@description('Whether to deploy DeploymentScripts for Azure IoT Operations.')
param shouldDeployAioDeploymentScripts bool = false

@description('The name of the Key Vault that will have scripts and secrets for deployment.')
param deployKeyVaultName string = sseKeyVaultName

@description('The resource group name where the Key Vault is located. Defaults to the current resource group.')
param deployKeyVaultResourceGroupName string = sseKeyVaultResourceGroupName

@description('The name for the deploy user token secret in Key Vault.')
param deployUserTokenSecretName string = 'deploy-user-token'

@description('The prefix used with constructing the secret name that will have the deployment script.')
param deploymentScriptsSecretNamePrefix string = '${common.resourcePrefix}-${common.environment}-${common.instance}'

@description('Whether to add the deploy scripts for DeploymentScripts to Key Vault as secrets. (Required for DeploymentScripts)')
param shouldAddDeployScriptsToKeyVault bool = false

/*
  Local Variables
*/

var trustSource = contains(trustIssuerSettings.trustSource, 'CustomerManaged') ? 'CustomerManaged' : 'SelfSigned'

@description('Whether to opt out of telemetry data collection.')
param telemetry_opt_out bool = false

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

resource deployIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = if (!empty(deployIdentityName)) {
  name: deployIdentityName!
}

resource sseIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: sseIdentityName
}

/*
  Modules
*/

/*
  Identity and Role Assignment Modules
*/

module deployArcK8sRoleAssignments 'modules/deploy-arc-k8s-role-assignments.bicep' = if (shouldAssignDeployIdentityRoles) {
  name: '${deployment().name}-arc0'
  params: {
    arcConnectedClusterName: arcConnectedClusterName
    deployIdentityPrincipalId: deployIdentity.properties.principalId
  }
}

module deployKeyVaultRoleAssignments 'modules/deploy-key-vault-role-assignments.bicep' = if (shouldAssignDeployIdentityRoles) {
  name: '${deployment().name}-kv0'
  scope: resourceGroup(deployKeyVaultResourceGroupName)
  params: {
    deployKeyVaultName: deployKeyVaultName
    deployIdentityPrincipalId: deployIdentity.properties.principalId
  }
}

module sseKeyVaultRoleAssignments 'modules/sse-key-vault-role-assignments.bicep' = if (shouldAssignSseKeyVaultRoles) {
  name: '${deployment().name}-sse0'
  scope: resourceGroup(sseKeyVaultResourceGroupName)
  params: {
    keyVaultName: deployKeyVaultName
    sseIdentityPrincipalId: sseIdentity.properties.principalId
  }
}

/*
  IoT Operations Initialization Modules
*/

module iotOpsInit 'modules/iot-ops-init.bicep' = if (shouldInitAio) {
  name: '${deployment().name}-init0'
  dependsOn: [
    deployArcK8sRoleAssignments
    sseKeyVaultRoleAssignments
    deployKeyVaultRoleAssignments
  ]
  params: {
    aioPlatformConfig: aioPlatformConfig
    arcConnectedClusterName: arcConnectedClusterName
    containerStorageConfig: containerStorageConfig
    secretStoreConfig: secretStoreConfig
  }
}

/*
  Post Initialization Script Modules
*/

module postInitScriptsSecrets 'modules/iot-ops-init-post-deploy-script-secrets.bicep' = if (shouldAddDeployScriptsToKeyVault) {
  name: '${deployment().name}-initp1'
  dependsOn: [
    iotOpsInit
  ]
  params: {
    aioNamespace: aioExtensionConfig.settings.namespace
    arcConnectedClusterName: arcConnectedClusterName
    deployKeyVaultName: deployKeyVaultName
    deployKeyVaultResourceGroupName: deployKeyVaultResourceGroupName
    deploySecretNamePrefix: '${deploymentScriptsSecretNamePrefix}-0'
    deployUserTokenSecretName: deployUserTokenSecretName
    resourceGroupName: resourceGroup().name
    shouldEnableOtelCollector: shouldEnableOtelCollector
    sseIdentityName: sseIdentityName
    sseKeyVaultName: sseKeyVaultName
    trustIssuerSettings: trustIssuerSettings
  }
}

module postInitScripts 'modules/apply-scripts.bicep' = if (shouldDeployAioDeploymentScripts) {
  name: '${deployment().name}-as2'
  params: {
    common: common
    deployIdentityId: deployIdentity.?id
    deployKeyVaultName: deployKeyVaultName
    deploymentScriptsSecretNamePrefix: '${deploymentScriptsSecretNamePrefix}-0'
    scriptSecretNames: [
      postInitScriptsSecrets.?outputs.?scriptSecretName
    ]
    environmentVariableSecretNames: [
      postInitScriptsSecrets.?outputs.?environmentVariablesSecretName
    ]
    includeFileSecretNames: [
      postInitScriptsSecrets.?outputs.?includeFilesSecretName
    ]
  }
}

/*
  IoT Operations Instance Modules
*/

module iotOpsInstance 'modules/iot-ops-instance.bicep' = if (shouldDeployAio) {
  name: '${deployment().name}-ioi3'
  dependsOn: [
    postInitScripts
  ]
  params: {
    aioDataFlowInstanceConfig: aioDataFlowInstanceConfig
    aioExtensionConfig: aioExtensionConfig
    aioIdentityName: aioIdentityName
    aioInstanceName: aioInstanceName
    aioFeatures: aioFeatures
    aioMqBrokerConfig: aioMqBrokerConfig
    aioPlatformExtensionId: iotOpsInit.outputs.aioPlatformExtensionId
    arcConnectedClusterName: arcConnectedClusterName
    brokerListenerAnonymousConfig: brokerListenerAnonymousConfig
    common: common
    customLocationName: customLocationName
    schemaRegistryName: schemaRegistryName
    secretStoreExtensionId: iotOpsInit.outputs.secretStoreExtensionId
    shouldCreateAnonymousBrokerListener: shouldCreateAnonymousBrokerListener
    shouldDeployResourceSyncRules: shouldDeployResourceSyncRules
    shouldEnableOtelCollector: shouldEnableOtelCollector
    trustIssuerSettings: trustIssuerSettings.?trustSettings
    trustSource: trustSource
  }
}

module iotOpsInstancePost 'modules/iot-ops-instance-post.bicep' = if (shouldDeployAio) {
  name: '${deployment().name}-ioip4'
  params: {
    aioIdentityName: aioIdentityName
    aioNamespace: aioExtensionConfig.settings.namespace
    arcConnectedClusterName: arcConnectedClusterName
    common: common
    customLocationId: iotOpsInstance.outputs.customLocationId
    sseIdentityName: sseIdentityName
    sseKeyVaultName: sseKeyVaultName
  }
}

/*
  Post Instance Script Modules
*/

module postInstanceScriptsSecrets 'modules/iot-ops-instance-post-deploy-script-secrets.bicep' = if (shouldAddDeployScriptsToKeyVault) {
  name: '${deployment().name}-ioips5'
  dependsOn: [
    iotOpsInit
  ]
  params: {
    aioNamespace: aioExtensionConfig.settings.namespace
    arcConnectedClusterName: arcConnectedClusterName
    deployKeyVaultName: deployKeyVaultName
    deployKeyVaultResourceGroupName: deployKeyVaultResourceGroupName
    deploySecretNamePrefix: '${deploymentScriptsSecretNamePrefix}-1'
    deployUserTokenSecretName: deployUserTokenSecretName
    resourceGroupName: resourceGroup().name
    shouldEnableOpcUaSimulator: shouldEnableOpcUaSimulator
  }
}

module postInstanceScripts 'modules/apply-scripts.bicep' = if (shouldDeployAioDeploymentScripts) {
  name: '${deployment().name}-as6'
  params: {
    common: common
    deployIdentityId: deployIdentity.?id
    deployKeyVaultName: deployKeyVaultName
    deploymentScriptsSecretNamePrefix: '${deploymentScriptsSecretNamePrefix}-1'
    scriptSecretNames: [
      postInstanceScriptsSecrets.?outputs.?scriptSecretName
    ]
    environmentVariableSecretNames: [
      postInstanceScriptsSecrets.?outputs.?environmentVariablesSecretName
    ]
    includeFileSecretNames: [
      postInstanceScriptsSecrets.?outputs.?includeFilesSecretName
    ]
  }
}

/*
  OPC UA Simulator Modules
*/

module opcUaSimulator 'modules/opc-ua-simulator-asset.bicep' = if (shouldEnableOpcUaSimulatorAsset) {
  name: '${deployment().name}-opc7'
  dependsOn: [
    postInstanceScripts
  ]
  params: {
    common: common
    customLocationId: iotOpsInstance.outputs.customLocationId
  }
}

/*
  Outputs
*/

@description('The ID of the Container Storage Extension.')
output containerStorageExtensionId string = iotOpsInit.outputs.containerStorageExtensionId

@description('The name of the Container Storage Extension.')
output containerStorageExtensionName string = iotOpsInit.outputs.containerStorageExtensionName

@description('The ID of the Azure IoT Operations Platform Extension.')
output aioPlatformExtensionId string = iotOpsInit.outputs.aioPlatformExtensionId

@description('The name of the Azure IoT Operations Platform Extension.')
output aioPlatformExtensionName string = iotOpsInit.outputs.aioPlatformExtensionName

@description('The ID of the Secret Store Extension.')
output secretStoreExtensionId string = iotOpsInit.outputs.secretStoreExtensionId

@description('The name of the Secret Store Extension.')
output secretStoreExtensionName string = iotOpsInit.outputs.secretStoreExtensionName

@description('The ID of the deployed Custom Location.')
output customLocationId string = iotOpsInstance.outputs.customLocationId

@description('The name of the deployed Custom Location.')
output customLocationName string = iotOpsInstance.outputs.customLocationName

@description('The ID of the deployed Azure IoT Operations instance.')
output aioInstanceId string = iotOpsInstance.outputs.aioInstanceId

@description('The name of the deployed Azure IoT Operations instance.')
output aioInstanceName string = iotOpsInstance.outputs.aioInstanceName

@description('The ID of the deployed Azure IoT Operations Data Flow Profile.')
output dataFlowProfileId string = shouldDeployResourceSyncRules ? iotOpsInstance.outputs.dataFlowProfileId : ''

@description('The name of the deployed Azure IoT Operations Data Flow Profile.')
output dataFlowProfileName string = shouldDeployResourceSyncRules ? iotOpsInstance.outputs.dataFlowProfileName : ''

@description('The ID of the deployed Azure IoT Operations Data Flow Endpoint.')
output dataFlowEndpointId string = shouldDeployResourceSyncRules ? iotOpsInstance.outputs.dataFlowEndpointId : ''

@description('The name of the deployed Azure IoT Operations Data Flow Endpoint.')
output dataFlowEndpointName string = shouldDeployResourceSyncRules ? iotOpsInstance.outputs.dataFlowEndpointName : ''

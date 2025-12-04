metadata name = 'Full Single Cluster Blueprint'
metadata description = 'Deploys a complete end-to-end environment for Azure IoT Operations on a single-node, Arc-enabled Kubernetes cluster.'

import * as core from './types.core.bicep'

targetScope = 'subscription'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

@description('The name for the resource group. If not provided, a default name will be generated.')
param resourceGroupName string = 'rg-${common.resourcePrefix}-${common.environment}-${common.instance}'

@description('Whether to use an existing resource group instead of creating a new one.')
param useExistingResourceGroup bool = false

@description('Whether to opt-out of telemetry. Set to true to disable telemetry.')
param telemetry_opt_out bool = false

/*
  Virtual Machine Parameters
*/

@secure()
@description('Password used for the host VM.')
param adminPassword string

/*
  Container Registry Parameters
*/

@description('Whether to create a private endpoint for the Azure Container Registry.')
param shouldCreateAcrPrivateEndpoint bool = false

/*
  Azure Kubernetes Service Parameters
*/

@description('Whether to create an Azure Kubernetes Service cluster.')
param shouldCreateAks bool = false

/*
  CNCF Arc cluster parameters
*/

@description('''
The object id of the Custom Locations Entra ID application for your tenant.
Can be retrieved using:

  ```sh
  az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv
  ```
''')
param customLocationsOid string

/*
  IoT Operations Parameters
*/

// Currently disable setting shouldDeployAioDeploymentScripts, remove when DeploymentScripts supports AZ CLI 2.71+ (post May 4)
// @description('The trust issuer settings for Customer Managed Azure IoT Operations Settings.')
// param trustIssuerSettings iotOpsTypes.TrustIssuerConfig = { trustSource: 'SelfSigned' }
var trustIssuerSettings = { trustSource: 'SelfSigned' }

@description('Whether to enable an insecure anonymous AIO MQ Broker Listener. (Should only be used for dev or test environments)')
param shouldCreateAnonymousBrokerListener bool = false

@description('Whether to deploy the Azure IoT Operations initial connected cluster resources, Secret Sync, ACSA, OSM, AIO Platform.')
param shouldInitAio bool = true

@description('Whether to deploy an Azure IoT Operations Instance and all of its required components into the connected cluster.')
param shouldDeployAio bool = true

// Currently disable setting shouldDeployAioDeploymentScripts, remove when DeploymentScripts supports AZ CLI 2.71+ (post May 4)
// @description('Whether to deploy DeploymentScripts for Azure IoT Operations.')
// param shouldDeployAioDeploymentScripts bool = false
var shouldDeployAioDeploymentScripts = false

// No additional resource group parameters needed

// Currently disable setting shouldDeployAioDeploymentScripts, remove when DeploymentScripts supports AZ CLI 2.71+ (post May 4)
// @description('Whether or not to enable the Open Telemetry Collector for Azure IoT Operations.')
// param shouldEnableOtelCollector bool = true
var shouldEnableOtelCollector = false

// Currently disable setting shouldDeployAioDeploymentScripts, remove when DeploymentScripts supports AZ CLI 2.71+ (post May 4)
// @description('Whether or not to enable the OPC UA Simulator and deploy ADR Asset for Azure IoT Operations.')
// param shouldEnableOpcUaSimulator bool = true
var shouldEnableOpcUaSimulator = false

/*
  Resources
*/

resource attribution 'Microsoft.Resources/deployments@2020-06-01' = if (!telemetry_opt_out) {
  name: 'pid-acce1e78-0375-4637-a593-86aa36dcfeac'
  location: common.location
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

module cloudResourceGroup '../../../src/000-cloud/000-resource-group/bicep/main.bicep' = {
  name: '${deployment().name}-crg0'
  params: {
    common: common
    useExistingResourceGroup: useExistingResourceGroup
    resourceGroupName: !empty(resourceGroupName) ? resourceGroupName : null
  }
}

module cloudSecurityIdentity '../../../src/000-cloud/010-security-identity/bicep/main.bicep' = {
  name: '${deployment().name}-csi1'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [cloudResourceGroup]
  params: {
    common: common
  }
}

module cloudObservability '../../../src/000-cloud/020-observability/bicep/main.bicep' = {
  name: '${deployment().name}-cloudObservability'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [cloudResourceGroup]
  params: {
    common: common
  }
}

module cloudData '../../../src/000-cloud/030-data/bicep/main.bicep' = {
  name: '${deployment().name}-cd2'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [cloudResourceGroup]
  params: {
    common: common
    shouldCreateAdrNamespace: true
  }
}

module cloudMessaging '../../../src/000-cloud/040-messaging/bicep/main.bicep' = {
  name: '${deployment().name}-cm4'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [cloudResourceGroup]
  params: {
    common: common
    aioIdentityName: cloudSecurityIdentity.outputs.aioIdentityName
  }
}

module cloudNetworking '../../../src/000-cloud/050-networking/bicep/main.bicep' = {
  name: '${deployment().name}-cn3'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [cloudResourceGroup]
  params: {
    common: common
  }
}

module cloudVmHost '../../../src/000-cloud/051-vm-host/bicep/main.bicep' = {
  name: '${deployment().name}-cvh4'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [cloudResourceGroup]
  params: {
    common: common
    adminPassword: adminPassword
    arcOnboardingIdentityName: cloudSecurityIdentity.outputs.arcOnboardingIdentityName!
    subnetId: cloudNetworking.outputs.subnetId
  }
}

module cloudAcr '../../../src/000-cloud/060-acr/bicep/main.bicep' = {
  name: '${deployment().name}-caa5'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [cloudResourceGroup]
  params: {
    common: common
    virtualNetworkName: cloudNetworking.outputs.virtualNetworkName
    networkSecurityGroupName: cloudNetworking.outputs.networkSecurityGroupName
    shouldCreateAcrPrivateEndpoint: shouldCreateAcrPrivateEndpoint
  }
}

module cloudKubernetes '../../../src/000-cloud/070-kubernetes/bicep/main.bicep' = {
  name: '${deployment().name}-ck6'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [cloudResourceGroup]
  params: {
    common: common
    virtualNetworkName: cloudNetworking.outputs.virtualNetworkName
    networkSecurityGroupName: cloudNetworking.outputs.networkSecurityGroupName
    containerRegistryName: cloudAcr.outputs.acrName
    shouldCreateAks: shouldCreateAks
  }
}

module edgeCncfCluster '../../../src/100-edge/100-cncf-cluster/bicep/main.bicep' = {
  name: '${deployment().name}-ecc4'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [cloudResourceGroup]
  params: {
    arcOnboardingIdentityName: cloudSecurityIdentity.outputs.arcOnboardingIdentityName!
    clusterNodeVirtualMachineNames: skip(cloudVmHost.outputs.vmNames, 1)
    clusterServerIp: cloudVmHost.outputs.privateIpAddresses[0]
    clusterServerVirtualMachineName: cloudVmHost.outputs.vmNames[0]
    common: common
    customLocationsOid: customLocationsOid
    deployKeyVaultName: cloudSecurityIdentity.outputs.keyVaultName!
  }
}

module edgeIotOps '../../../src/100-edge/110-iot-ops/bicep/main.bicep' = {
  name: '${deployment().name}-eio5'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [cloudResourceGroup]
  params: {
    // Common Parameters
    common: common
    arcConnectedClusterName: edgeCncfCluster.outputs.connectedClusterName

    // Azure IoT Operations Init Parameters
    shouldInitAio: shouldInitAio

    // Azure IoT Operations Instance Parameters
    aioIdentityName: cloudSecurityIdentity.outputs.aioIdentityName
    schemaRegistryName: cloudData.outputs.schemaRegistryName
    adrNamespaceName: cloudData.outputs.adrNamespaceName
    shouldDeployAio: shouldDeployAio
    shouldCreateAnonymousBrokerListener: shouldCreateAnonymousBrokerListener
    shouldEnableOtelCollector: shouldEnableOtelCollector
    shouldEnableOpcUaSimulator: shouldEnableOpcUaSimulator

    // Trust Configuration Parameters
    trustIssuerSettings: trustIssuerSettings

    // Secret Sync and Key Vault Parameters
    sseIdentityName: cloudSecurityIdentity.outputs.sseIdentityName
    sseKeyVaultName: cloudSecurityIdentity.outputs.keyVaultName!

    // Deployment Identity and Script Parameters
    deployIdentityName: cloudSecurityIdentity.outputs.deployIdentityName
    shouldDeployAioDeploymentScripts: shouldDeployAioDeploymentScripts
  }
}
module edgeAssets '../../../src/100-edge/111-assets/bicep/main.bicep' = {
  name: '${deployment().name}-ea1'
  scope: resourceGroup(resourceGroupName)
  params: {
    common: common
    customLocationId: edgeIotOps.outputs.customLocationId
    adrNamespaceName: cloudData.outputs.adrNamespaceName
    shouldCreateDefaultNamespacedAsset: true
  }
}

module edgeObservability '../../../src/100-edge/120-observability/bicep/main.bicep' = {
  name: '${deployment().name}-eo6'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [cloudResourceGroup, edgeIotOps]
  params: {
    arcConnectedClusterName: edgeCncfCluster.outputs.connectedClusterName
    azureMonitorWorkspaceName: cloudObservability.outputs.monitorWorkspaceName
    logAnalyticsWorkspaceName: cloudObservability.outputs.logAnalyticsName
    azureManagedGrafanaName: cloudObservability.outputs.grafanaName
    metricsDataCollectionRuleName: cloudObservability.outputs.metricsDataCollectionRuleName
    logsDataCollectionRuleName: cloudObservability.outputs.logsDataCollectionRuleName
  }
}

module edgeMessaging '../../../src/100-edge/130-messaging/bicep/main.bicep' = {
  name: '${deployment().name}-em7'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [cloudResourceGroup]
  params: {
    // Common parameters
    common: common

    // Resource references
    aioIdentityName: cloudSecurityIdentity.outputs.aioIdentityName
    aioCustomLocationName: edgeIotOps.outputs.customLocationName
    aioInstanceName: edgeIotOps.outputs.aioInstanceName
    aioDataflowProfileName: edgeIotOps.outputs.dataFlowProfileName
    adrNamespaceName: cloudData.outputs.adrNamespaceName

    // Optional event hub and event grid parameters passed from cloud messaging
    eventHub: cloudMessaging.outputs.eventHubConfig
    eventGrid: cloudMessaging.outputs.eventGridConfig
  }
}

/*
  Outputs
*/

@description('The name of the Arc-enabled Kubernetes cluster that was connected to Azure. This can be used to reference the cluster in other deployments.')
output arcConnectedClusterName string = edgeCncfCluster.outputs.connectedClusterName

@description('The administrative username that can be used to SSH into the deployed virtual machines.')
output vmUsername string = cloudVmHost.outputs.adminUsername

@description('An array containing the names of all virtual machines that were deployed as part of this blueprint.')
output vmNames array = cloudVmHost.outputs.vmNames

@description('The AKS cluster name.')
output aksName string? = cloudKubernetes.outputs.?aksName

@description('The Azure Container Registry name.')
output acrName string = cloudAcr.outputs.acrName

@description('The ID of the Azure IoT Operations Platform Extension.')
output aioPlatformExtensionId string = edgeIotOps.outputs.aioPlatformExtensionId

@description('The name of the Azure IoT Operations Platform Extension.')
output aioPlatformExtensionName string = edgeIotOps.outputs.aioPlatformExtensionName

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

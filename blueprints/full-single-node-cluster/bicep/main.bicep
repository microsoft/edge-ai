metadata name = 'Full Single Cluster Blueprint'
metadata description = 'Deploys a complete end-to-end environment for Azure IoT Operations on a single-node, Arc-enabled Kubernetes cluster.'

import * as core from './types.core.bicep'
import * as types from '../../../src/100-edge/110-iot-ops/bicep/types.bicep'
import * as assetTypes from '../../../src/100-edge/111-assets/bicep/types.bicep'
import * as aiFoundryTypes from '../../../src/000-cloud/085-ai-foundry/bicep/types.bicep'
import * as vpnGatewayTypes from '../../../src/000-cloud/055-vpn-gateway/bicep/types.bicep'

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
  AI Foundry Parameters
*/

@description('Whether to deploy AI Foundry resources.')
param shouldDeployAiFoundry bool = false

@description('The AI Foundry configuration settings.')
param aiFoundryConfig aiFoundryTypes.AiFoundryConfig = aiFoundryTypes.aiFoundryConfigDefaults

@description('Array of AI Foundry projects to create.')
param aiFoundryProjects aiFoundryTypes.AiProject[] = []

@description('Array of RAI policies to create.')
param aiFoundryRaiPolicies aiFoundryTypes.RaiPolicy[] = []

@description('Array of model deployments to create.')
param aiFoundryModelDeployments aiFoundryTypes.ModelDeployment[] = []

@description('Whether to create a private endpoint for AI Foundry.')
param shouldCreateAiFoundryPrivateEndpoint bool = false

/*
  NAT Gateway Parameters
*/

@description('Whether to enable managed outbound access via NAT gateway instead of platform default internet access.')
param shouldEnableManagedOutboundAccess bool = true

@description('Number of public IP addresses for NAT Gateway (1-16).')
@minValue(1)
@maxValue(16)
param natGatewayPublicIpCount int = 1

@description('Idle timeout in minutes for NAT gateway connections (4-120).')
@minValue(4)
@maxValue(120)
param natGatewayIdleTimeoutMinutes int = 4

@description('Availability zones for NAT Gateway. Empty array for regional deployment.')
param natGatewayZones string[] = []

/*
  Private Endpoint and DNS Parameters
*/

@description('Whether to enable private endpoints across Key Vault, storage, and observability resources.')
param shouldEnablePrivateEndpoints bool = false

@description('Whether to enable Azure Private Resolver for VPN client DNS resolution of private endpoints.')
param shouldEnablePrivateResolver bool = false

@description('Address prefix for the private resolver subnet; must be /28 or larger and not overlap with other subnets.')
param resolverSubnetAddressPrefix string = '10.0.9.0/28'

@description('Whether to enable public network access for the Key Vault.')
param shouldEnableKeyVaultPublicNetworkAccess bool = true

@description('Whether to enable public network access for the storage account.')
param shouldEnableStoragePublicNetworkAccess bool = true

/*
  Subnet Configuration Parameters
*/

@description('Address prefix for the ACR subnet.')
param subnetAddressPrefixAcr string = '10.0.4.0/24'

@description('Address prefix for the AKS subnet.')
param subnetAddressPrefixAks string = '10.0.5.0/24'

@description('Address prefix for the AKS pod subnet.')
param subnetAddressPrefixAksPod string = '10.0.6.0/24'

/*
  VPN Gateway Parameters
*/

@description('Whether to deploy VPN Gateway for remote access.')
param shouldEnableVpnGateway bool = false

@description('VPN Gateway configuration settings.')
param vpnGatewayConfig vpnGatewayTypes.VpnGatewayConfig = vpnGatewayTypes.vpnGatewayConfigDefaults

@description('Azure AD authentication configuration for VPN Gateway.')
param vpnGatewayAzureAdConfig vpnGatewayTypes.AzureAdConfig = vpnGatewayTypes.azureAdConfigDefaults

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
  Akri Connectors Parameters
*/

@description('Deploy Akri REST HTTP Connector template to the IoT Operations instance.')
param shouldEnableAkriRestConnector bool = false

@description('Deploy Akri Media Connector template to the IoT Operations instance.')
param shouldEnableAkriMediaConnector bool = false

@description('Deploy Akri ONVIF Connector template to the IoT Operations instance.')
param shouldEnableAkriOnvifConnector bool = false

@description('Deploy Akri SSE Connector template to the IoT Operations instance.')
param shouldEnableAkriSseConnector bool = false

@description('List of custom Akri connector templates with user-defined endpoint types and container images.')
param customAkriConnectors types.AkriConnectorTemplate[] = []

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
    shouldCreateKeyVaultPrivateEndpoint: shouldEnablePrivateEndpoints
    shouldEnableKeyVaultPublicNetworkAccess: shouldEnableKeyVaultPublicNetworkAccess
    keyVaultPrivateEndpointSubnetId: shouldEnablePrivateEndpoints ? cloudNetworking.outputs.subnetId : null
    keyVaultVirtualNetworkId: shouldEnablePrivateEndpoints ? cloudNetworking.outputs.virtualNetworkId : null
  }
}

module cloudObservability '../../../src/000-cloud/020-observability/bicep/main.bicep' = {
  name: '${deployment().name}-cloudObservability'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [cloudResourceGroup]
  params: {
    common: common
    shouldEnablePrivateEndpoints: shouldEnablePrivateEndpoints
    privateEndpointSubnetId: shouldEnablePrivateEndpoints ? cloudNetworking.outputs.subnetId : null
    virtualNetworkId: shouldEnablePrivateEndpoints ? cloudNetworking.outputs.virtualNetworkId : null
  }
}

module cloudData '../../../src/000-cloud/030-data/bicep/main.bicep' = {
  name: '${deployment().name}-cd2'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [cloudResourceGroup]
  params: {
    common: common
    shouldCreateAdrNamespace: true
    shouldEnableStoragePrivateEndpoint: shouldEnablePrivateEndpoints
    shouldEnableStoragePublicNetworkAccess: shouldEnableStoragePublicNetworkAccess
    storagePrivateEndpointSubnetId: shouldEnablePrivateEndpoints ? cloudNetworking.outputs.subnetId : null
    storageVirtualNetworkId: shouldEnablePrivateEndpoints ? cloudNetworking.outputs.virtualNetworkId : null
    shouldCreateBlobPrivateDnsZone: !shouldEnablePrivateEndpoints
    blobPrivateDnsZoneId: shouldEnablePrivateEndpoints ? cloudObservability.outputs.?monitorPrivateDnsZoneBlobId : null
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
    natGatewayConfig: {
      shouldEnable: shouldEnableManagedOutboundAccess
      publicIpCount: natGatewayPublicIpCount
      idleTimeoutMinutes: natGatewayIdleTimeoutMinutes
      zones: natGatewayZones
    }
    privateResolverConfig: {
      shouldEnable: shouldEnablePrivateResolver
      subnetAddressPrefix: resolverSubnetAddressPrefix
    }
    defaultOutboundAccessEnabled: !shouldEnableManagedOutboundAccess
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

module cloudVpnGateway '../../../src/000-cloud/055-vpn-gateway/bicep/main.bicep' = if (shouldEnableVpnGateway) {
  name: '${deployment().name}-cvg5'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [cloudResourceGroup, cloudVmHost, cloudAcr]
  params: {
    common: common
    virtualNetworkName: cloudNetworking.outputs.virtualNetworkName
    vpnGatewayConfig: vpnGatewayConfig
    azureAdConfig: vpnGatewayAzureAdConfig
  }
}

module cloudAcr '../../../src/000-cloud/060-acr/bicep/main.bicep' = {
  name: '${deployment().name}-caa6'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [cloudResourceGroup]
  params: {
    common: common
    virtualNetworkName: cloudNetworking.outputs.virtualNetworkName
    networkSecurityGroupName: cloudNetworking.outputs.networkSecurityGroupName
    shouldCreateAcrPrivateEndpoint: shouldCreateAcrPrivateEndpoint
    natGatewayId: shouldEnableManagedOutboundAccess ? cloudNetworking.outputs.?natGatewayId : null
    acrNetworkConfig: {
      subnetAddressPrefix: subnetAddressPrefixAcr
      defaultOutboundAccessEnabled: !shouldEnableManagedOutboundAccess
      shouldEnableNatGateway: shouldEnableManagedOutboundAccess
    }
  }
}

module cloudAiFoundry '../../../src/000-cloud/085-ai-foundry/bicep/main.bicep' = if (shouldDeployAiFoundry) {
  name: '${deployment().name}-caf7'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [cloudResourceGroup]
  params: {
    common: common
    aiFoundryConfig: aiFoundryConfig
    aiProjects: aiFoundryProjects
    raiPolicies: aiFoundryRaiPolicies
    modelDeployments: aiFoundryModelDeployments
    shouldCreatePrivateEndpoint: shouldCreateAiFoundryPrivateEndpoint
    privateEndpointSubnetId: shouldCreateAiFoundryPrivateEndpoint ? cloudNetworking.outputs.subnetId : ''
    virtualNetworkId: shouldCreateAiFoundryPrivateEndpoint ? cloudNetworking.outputs.virtualNetworkId : ''
    tags: {}
  }
}

module cloudKubernetes '../../../src/000-cloud/070-kubernetes/bicep/main.bicep' = {
  name: '${deployment().name}-ck8'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [cloudResourceGroup]
  params: {
    common: common
    virtualNetworkName: cloudNetworking.outputs.virtualNetworkName
    networkSecurityGroupName: cloudNetworking.outputs.networkSecurityGroupName
    containerRegistryName: cloudAcr.outputs.acrName
    shouldCreateAks: shouldCreateAks
    natGatewayId: shouldEnableManagedOutboundAccess ? cloudNetworking.outputs.?natGatewayId : null
    aksNetworkConfig: {
      subnetAddressPrefixAks: subnetAddressPrefixAks
      subnetAddressPrefixAksPod: subnetAddressPrefixAksPod
      defaultOutboundAccessEnabled: !shouldEnableManagedOutboundAccess
      shouldEnableNatGateway: shouldEnableManagedOutboundAccess
    }
    aksPrivateClusterConfig: {
      shouldEnablePrivateCluster: shouldEnablePrivateEndpoints
      shouldEnablePrivateClusterPublicFqdn: false
      shouldEnablePrivateEndpoint: shouldEnablePrivateEndpoints
    }
    privateEndpointSubnetId: shouldEnablePrivateEndpoints ? cloudNetworking.outputs.subnetId : null
    virtualNetworkId: shouldEnablePrivateEndpoints ? cloudNetworking.outputs.virtualNetworkId : null
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

    // Akri Connectors Parameters
    shouldEnableAkriRestConnector: shouldEnableAkriRestConnector
    shouldEnableAkriMediaConnector: shouldEnableAkriMediaConnector
    shouldEnableAkriOnvifConnector: shouldEnableAkriOnvifConnector
    shouldEnableAkriSseConnector: shouldEnableAkriSseConnector
    customAkriConnectors: customAkriConnectors
  }
}

module edgeAssets '../../../src/100-edge/111-assets/bicep/main.bicep' = {
  name: '${deployment().name}-ea1'
  scope: resourceGroup(resourceGroupName)
  params: {
    common: common
    customLocationId: edgeIotOps.outputs.customLocationId
    adrNamespaceName: cloudData.outputs.adrNamespaceName
    shouldCreateDefaultNamespacedAsset: shouldEnableOpcUaSimulator
    namespacedDevices: namespacedDevices
    assetEndpointProfiles: assetEndpointProfiles
    legacyAssets: legacyAssets
    namespacedAssets: namespacedAssets
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

@description('The AI Foundry account name.')
output aiFoundryName string? = shouldDeployAiFoundry ? cloudAiFoundry.?outputs.?aiFoundryName : null

@description('The AI Foundry account endpoint.')
output aiFoundryEndpoint string? = shouldDeployAiFoundry ? cloudAiFoundry.?outputs.?aiFoundryEndpoint : null

@description('The AI Foundry account principal ID.')
output aiFoundryPrincipalId string? = shouldDeployAiFoundry ? cloudAiFoundry.?outputs.?aiFoundryPrincipalId : null

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

/*
  NAT Gateway Outputs
*/

@description('The NAT Gateway ID (if enabled).')
output natGatewayId string? = shouldEnableManagedOutboundAccess ? cloudNetworking.outputs.?natGatewayId : null

@description('The NAT Gateway name (if enabled).')
output natGatewayName string? = shouldEnableManagedOutboundAccess ? cloudNetworking.outputs.?natGatewayName : null

@description('Whether default outbound access is enabled (inverse of managed outbound).')
output defaultOutboundAccessEnabled bool = !shouldEnableManagedOutboundAccess

/*
  Private Resolver Outputs
*/

@description('The Private DNS Resolver ID (if enabled).')
output privateResolverId string? = shouldEnablePrivateResolver ? cloudNetworking.outputs.?privateResolverId : null

@description('The Private DNS Resolver name (if enabled).')
output privateResolverName string? = shouldEnablePrivateResolver ? cloudNetworking.outputs.?privateResolverName : null

@description('The DNS server IP from Private Resolver (if enabled).')
output dnsServerIp string? = shouldEnablePrivateResolver ? cloudNetworking.outputs.?dnsServerIp : null

/*
  Private Endpoint Outputs
*/

@description('Whether private endpoints are enabled.')
output privateEndpointsEnabled bool = shouldEnablePrivateEndpoints

@description('The Key Vault private endpoint ID (if enabled).')
output keyVaultPrivateEndpointId string? = shouldEnablePrivateEndpoints
  ? cloudSecurityIdentity.outputs.?keyVaultPrivateEndpointId
  : null

@description('The storage account blob private endpoint ID (if enabled).')
output storageBlobPrivateEndpointId string? = shouldEnablePrivateEndpoints
  ? cloudData.outputs.?storageBlobPrivateEndpointId
  : null

/*
  VPN Gateway Outputs
*/

@description('The VPN Gateway ID (if enabled).')
output vpnGatewayId string? = shouldEnableVpnGateway ? cloudVpnGateway.?outputs.?vpnGatewayId : null

@description('The VPN Gateway name (if enabled).')
output vpnGatewayName string? = shouldEnableVpnGateway ? cloudVpnGateway.?outputs.?vpnGatewayName : null

@description('The VPN Gateway public IP address (if enabled).')
output vpnGatewayPublicIp string? = shouldEnableVpnGateway ? cloudVpnGateway.?outputs.?vpnGatewayPublicIp : null

@description('VPN client connection information (if enabled).')
output vpnClientConnectionInfo object? = shouldEnableVpnGateway ? cloudVpnGateway.?outputs.?clientConnectionInfo : null

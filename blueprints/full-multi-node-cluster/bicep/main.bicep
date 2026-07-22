metadata name = 'Full Multi-node Cluster Blueprint'
metadata description = 'Deploys a complete end-to-end environment for Azure IoT Operations on a multi-node, Arc-enabled Kubernetes cluster.'

import * as core from './types.core.bicep'
import * as types from '../../../src/100-edge/110-iot-ops/bicep/types.bicep'
import * as assetTypes from '../../../src/100-edge/111-assets/bicep/types.bicep'
import * as messagingTypes from '../../../src/100-edge/130-messaging/bicep/types.bicep'
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
@description('Password used for the host VM. (Required when not targeting pre-existing Arc machines)')
param adminPassword string?

@description('The number of host VMs to create for the cluster. (The first host VM will be the cluster server)')
@minValue(1)
param hostMachineCount int = 1

/*
  Arc Machine Parameters
*/

@description('Whether to target pre-existing Azure Arc-enabled machines instead of creating host VMs.')
param shouldUseArcMachines bool = false

@description('The number of pre-existing Arc-enabled machines to target. (The first Arc machine will be the cluster server)')
@minValue(1)
param arcMachineCount int = 1

@description('The name prefix for the pre-existing Arc-enabled machines. Machines are resolved as "{prefix}{1..N}". Defaults to the resource prefix.')
param arcMachineNamePrefix string?

@description('The exact name of a single pre-existing Arc-enabled machine. (Honored only when arcMachineCount is 1; overrides the prefix model)')
param arcMachineName string?

@description('The resource group name containing the pre-existing Arc-enabled machines. Defaults to the deployment resource group.')
param arcMachineResourceGroupName string?

@description('Username for the cluster server host machine that receives kube-config settings on setup. Defaults to the resource prefix.')
param clusterServerHostMachineUsername string?

@description('The IP address for the cluster server. (Required for multi-node Arc clusters; derived from the host VM for VM-based clusters)')
param clusterServerIp string?

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

@description('The token that will be given to the server for the cluster or used by agent nodes. (Required for multi-node clusters where hostMachineCount > 1)')
@secure()
param serverToken string?

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
  VPN Gateway Parameters
*/

@description('Whether to deploy VPN Gateway for remote access.')
param shouldEnableVpnGateway bool = false

@description('VPN Gateway configuration settings.')
param vpnGatewayConfig vpnGatewayTypes.VpnGatewayConfig = vpnGatewayTypes.vpnGatewayConfigDefaults

@description('Azure AD authentication configuration for VPN Gateway.')
param vpnGatewayAzureAdConfig vpnGatewayTypes.AzureAdConfig = vpnGatewayTypes.azureAdConfigDefaults

/*
  Private Endpoint and DNS Parameters
*/

@description('Whether to enable private endpoints across Key Vault, storage, and observability resources.')
param shouldEnablePrivateEndpoints bool = false

@description('Override for Azure Monitor (observability) private endpoints. Defaults to shouldEnablePrivateEndpoints when null. Set false for Arc edge clusters where the managed Prometheus metrics addon cannot fetch its config or ingest over private link and would otherwise leave dashboards empty.')
param shouldEnableObservabilityPrivateEndpoints bool?

@description('Whether to enable Azure Private Resolver for VPN client DNS resolution of private endpoints.')
param shouldEnablePrivateResolver bool = false

@description('Address prefix for the private resolver subnet; must be /28 or larger and not overlap with other subnets.')
param resolverSubnetAddressPrefix string = '10.0.9.0/28'

@description('Whether to enable public network access for the Key Vault.')
param shouldEnableKeyVaultPublicNetworkAccess bool = true

@description('Whether to enable public network access for the storage account.')
param shouldEnableStoragePublicNetworkAccess bool = true

@description('Whether to secure the Key Vault and Storage Account with a Network Security Perimeter.')
param shouldUseNetworkSecurityPerimeter bool = false

@description('IPv4 or IPv6 CIDR prefixes allowed through the Network Security Perimeter. Required when shouldUseNetworkSecurityPerimeter is true.')
param networkSecurityPerimeterAllowedIpAddressPrefixes string[] = []

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
  Azure Kubernetes Service Parameters
*/

@description('Whether to create an Azure Kubernetes Service cluster.')
param shouldCreateAks bool = false

/*
  IoT Operations Parameters
*/

@description('The trust issuer settings for Customer Managed Azure IoT Operations Settings.')
param trustIssuerSettings types.TrustIssuerConfig = { trustSource: 'SelfSigned' }

@description('Whether to enable an insecure anonymous AIO MQ Broker Listener. (Should only be used for dev or test environments)')
param shouldCreateAnonymousBrokerListener bool = false

@description('Whether to deploy the Azure IoT Operations initial connected cluster resources, Secret Sync, ACSA, OSM, AIO Platform.')
param shouldInitAio bool = true

@description('Whether to deploy an Azure IoT Operations Instance and all of its required components into the connected cluster.')
param shouldDeployAio bool = true

@description('Whether to deploy DeploymentScripts for Azure IoT Operations.')
param shouldDeployAioDeploymentScripts bool = false

@description('Whether or not to enable the Open Telemetry Collector for Azure IoT Operations.')
param shouldEnableOtelCollector bool = true

@description('Whether or not to enable the OPC UA Simulator and deploy ADR Asset for Azure IoT Operations.')
param shouldEnableOpcUaSimulator bool = false

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

@description('Custom container registry endpoints to add alongside the default MCR endpoint.')
param registryEndpoints types.RegistryEndpointConfig[] = []

@description('Whether to include the deployed ACR as a registry endpoint with System Assigned Managed Identity authentication.')
param shouldIncludeAcrRegistryEndpoint bool = false

/*
  Dataflow Graph Parameters
*/

@description('The list of dataflow graphs to create.')
param dataflowGraphs messagingTypes.DataflowGraph[] = []

/*
  Dataflow Parameters
*/

@description('The list of dataflows to create.')
param dataflows messagingTypes.Dataflow[] = []

/*
  Dataflow Endpoint Parameters
*/

@description('The list of dataflow endpoints to create.')
param dataflowEndpoints messagingTypes.DataflowEndpoint[] = []

/*
  Notification Parameters (045-notification)
*/

@description('Whether to deploy the 045-notification Logic App for alert deduplication and Teams posting.')
param shouldDeployNotification bool = false

@description('Name of the Event Hub for inference alerts. Otherwise, \'evh-{resourcePrefix}-alerts-{environment}-{instance}\'.')
param alertEventHubName string = 'evh-${common.resourcePrefix}-alerts-${common.environment}-${common.instance}'

@description('JSON schema object for parsing Event Hub events in the Logic App Parse_Event action.')
param notificationEventSchema object = {}

@description('HTML template for new-event Teams notifications. Supports the `\${close_session_url}` placeholder and Logic App expression syntax for dynamic event fields.')
param notificationMessageTemplate string = '<p>New alert event detected.</p>'

@description('HTML message body for session-closure Teams notifications. Supports Logic App expression syntax for dynamic fields.')
param closureMessageTemplate string = '<p>Session closed for event.</p>'

@description('Event schema field name used as the Table Storage partition key for session state deduplication lookups.')
param notificationPartitionKeyField string = 'event_id'

@description('Teams chat or channel thread ID for posting event notifications.')
@secure()
param teamsRecipientId string = ''

@description('Microsoft 365 Group ID (Team ID) for posting to a Teams channel. Required when teamsPostLocation is \'Channel\'.')
param teamsGroupId string?

@description('Teams posting location: \'Channel\' or \'Group chat\'.')
param teamsPostLocation ('Channel' | 'Group chat') = 'Channel'

/*
  Local Variables
*/

var acrRegistryEndpoint = shouldIncludeAcrRegistryEndpoint
  ? [
      {
        name: 'acr-${common.resourcePrefix}'
        host: '${cloudAcr.outputs.acrName}.azurecr.io'
        acrResourceId: cloudAcr.outputs.acrId
        authentication: {
          method: 'SystemAssignedManagedIdentity'
          systemAssignedManagedIdentitySettings: {}
        }
      }
    ]
  : []

var combinedRegistryEndpoints = concat(registryEndpoints, acrRegistryEndpoint)

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

resource arcMachines 'Microsoft.HybridCompute/machines@2025-06-01' existing = [
  for machineName in arcMachineNames: if (shouldUseArcMachines) {
    name: machineName
    scope: resourceGroup(arcMachineResourceGroupName ?? resourceGroupName)
  }
]

/*
  Variables
*/

// Resolve the Arc machine names for either the exact-name override or the "{prefix}{1..N}" model.
var arcMachineNamePrefixResolved = arcMachineNamePrefix ?? common.resourcePrefix
var arcMachineNames = [
  for i in range(0, arcMachineCount): arcMachineCount == 1
    ? (arcMachineName ?? '${arcMachineNamePrefixResolved}1')
    : '${arcMachineNamePrefixResolved}${i + 1}'
]

// The total number of cluster machines for either targeting mode.
var clusterMachineCount = shouldUseArcMachines ? arcMachineCount : hostMachineCount

// Validate that serverToken is provided for multi-node clusters
var validatedServerToken = clusterMachineCount > 1 && serverToken == null
  ? fail('serverToken is required when the cluster has more than one node. Multi-node clusters require a token for agent nodes to join the cluster.')
  : serverToken

// Host-derived values guarded for the conditional VM host (empty in Arc mode).
var vmHostVmNames = cloudVmHost.?outputs.vmNames ?? []
var vmHostVmIds = cloudVmHost.?outputs.vmIds ?? []
var vmHostPrivateIps = cloudVmHost.?outputs.privateIpAddresses ?? []

// Cluster server/node selection across VM and Arc targeting modes.
var clusterServerMachineName = shouldUseArcMachines ? arcMachineNames[0] : concat(vmHostVmNames, [''])[0]
var clusterNodeMachineNames = shouldUseArcMachines ? skip(arcMachineNames, 1) : skip(vmHostVmNames, 1)
var clusterServerIpResolved = shouldUseArcMachines ? clusterServerIp : concat(vmHostPrivateIps, [''])[0]
var validatedNetworkSecurityPerimeterAllowedIpAddressPrefixes = shouldUseNetworkSecurityPerimeter && empty(networkSecurityPerimeterAllowedIpAddressPrefixes)
  ? fail('networkSecurityPerimeterAllowedIpAddressPrefixes must contain the deployment client CIDR when shouldUseNetworkSecurityPerimeter is true.')
  : networkSecurityPerimeterAllowedIpAddressPrefixes

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
    shouldCreateArcOnboardingUami: !shouldUseArcMachines
    shouldCreateKeyVaultPrivateEndpoint: shouldEnablePrivateEndpoints
    shouldEnableKeyVaultPublicNetworkAccess: shouldEnableKeyVaultPublicNetworkAccess
    keyVaultPrivateEndpointSubnetId: shouldEnablePrivateEndpoints ? cloudNetworking.outputs.subnetId : null
    keyVaultVirtualNetworkId: shouldEnablePrivateEndpoints ? cloudNetworking.outputs.virtualNetworkId : null
    shouldUseNetworkSecurityPerimeter: shouldUseNetworkSecurityPerimeter
    networkSecurityPerimeterAllowedIpAddressPrefixes: validatedNetworkSecurityPerimeterAllowedIpAddressPrefixes
  }
}

module cloudObservability '../../../src/000-cloud/020-observability/bicep/main.bicep' = {
  name: '${deployment().name}-cloudObservability'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [cloudResourceGroup]
  params: {
    common: common
    shouldEnablePrivateEndpoints: shouldEnableObservabilityPrivateEndpoints ?? shouldEnablePrivateEndpoints
    shouldCreateBlobDnsZone: shouldEnablePrivateEndpoints
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
    networkSecurityPerimeterName: shouldUseNetworkSecurityPerimeter
      ? last(split(cloudSecurityIdentity.outputs.?networkSecurityPerimeterId!, '/'))
      : null
    networkSecurityPerimeterResourceGroupName: shouldUseNetworkSecurityPerimeter
      ? cloudSecurityIdentity.outputs.?networkSecurityPerimeterResourceGroupName
      : null
    networkSecurityPerimeterProfileName: shouldUseNetworkSecurityPerimeter ? 'defaultprofile' : null
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

module cloudNotification '../../../src/000-cloud/045-notification/bicep/main.bicep' = if (shouldDeployNotification) {
  name: '${deployment().name}-cn45'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [cloudResourceGroup]
  params: {
    common: common
    eventhubNamespaceName: cloudMessaging.outputs.eventHubNamespaceName
    eventhubName: alertEventHubName
    storageAccountName: cloudData.outputs.storageAccountName
    eventSchema: notificationEventSchema
    notificationMessageTemplate: notificationMessageTemplate
    closureMessageTemplate: closureMessageTemplate
    partitionKeyField: notificationPartitionKeyField
    teamsRecipientId: teamsRecipientId
    teamsGroupId: teamsGroupId
    teamsPostLocation: teamsPostLocation
  }
}

module cloudNetworking '../../../src/000-cloud/050-networking/bicep/main.bicep' = {
  name: '${deployment().name}-cvn3'
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

module cloudVmHost '../../../src/000-cloud/051-vm-host/bicep/main.bicep' = if (!shouldUseArcMachines) {
  name: '${deployment().name}-cvh4'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [cloudResourceGroup]
  params: {
    common: common
    adminPassword: adminPassword ?? fail('adminPassword is required when not targeting pre-existing Arc machines.')
    vmCount: hostMachineCount
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
    arcOnboardingIdentityName: shouldUseArcMachines ? null : cloudSecurityIdentity.outputs.arcOnboardingIdentityName!
    arcOnboardingPrincipalIds: [
      for i in range(0, shouldUseArcMachines ? arcMachineCount : 0): arcMachines[i].?identity.?principalId ?? ''
    ]
    shouldDeployArcMachines: shouldUseArcMachines
    clusterNodeVirtualMachineNames: shouldUseArcMachines ? null : clusterNodeMachineNames
    clusterServerVirtualMachineName: shouldUseArcMachines ? null : clusterServerMachineName
    clusterNodeArcMachineNames: shouldUseArcMachines ? clusterNodeMachineNames : null
    clusterServerArcMachineName: shouldUseArcMachines ? clusterServerMachineName : null
    clusterServerHostMachineUsername: clusterServerHostMachineUsername ?? common.resourcePrefix
    clusterServerIp: clusterServerIpResolved
    common: common
    customLocationsOid: customLocationsOid
    deployKeyVaultName: cloudSecurityIdentity.outputs.keyVaultName!
    serverToken: validatedServerToken
  }
}

module edgeArcExtensions '../../../src/100-edge/109-arc-extensions/bicep/main.bicep' = {
  name: '${deployment().name}-eae4'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [cloudResourceGroup]
  params: {
    arcConnectedClusterName: edgeCncfCluster.outputs.connectedClusterName
  }
}

module edgeIotOps '../../../src/100-edge/110-iot-ops/bicep/main.bicep' = {
  name: '${deployment().name}-eio5'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [edgeArcExtensions]
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
    registryEndpoints: combinedRegistryEndpoints
  }
}

module edgeAssets '../../../src/100-edge/111-assets/bicep/main.bicep' = {
  name: '${deployment().name}-ea6'
  scope: resourceGroup(resourceGroupName)
  params: {
    common: common
    customLocationId: edgeIotOps.outputs.customLocationId
    adrNamespaceName: cloudData.outputs.adrNamespaceName
    namespacedDevices: namespacedDevices
    namespacedAssets: namespacedAssets
    assetEndpointProfiles: assetEndpointProfiles
    legacyAssets: legacyAssets
    shouldCreateDefaultNamespacedAsset: shouldEnableOpcUaSimulator
  }
}

module edgeObservability '../../../src/100-edge/120-observability/bicep/main.bicep' = {
  name: '${deployment().name}-edgeObservability'
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
  name: '${deployment().name}-edgeMessaging'
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

    // Dataflow parameters
    dataflowGraphs: dataflowGraphs
    dataflows: dataflows
    dataflowEndpoints: dataflowEndpoints
  }
}

/*
  Outputs
*/

/*
  Azure IoT Operations Outputs
*/
@description('Azure IoT Operations deployment details.')
output azureIotOperations object = {
  customLocationId: edgeIotOps.outputs.customLocationId
  instanceName: edgeIotOps.outputs.aioInstanceName
  namespace: edgeIotOps.outputs.aioNamespace
}

@description('IoT asset resources.')
output assets object = {
  assets: edgeAssets.outputs.namespacedAssets
  assetEndpointProfiles: edgeAssets.outputs.assetEndpointProfiles
}

/*
  Cluster Connection Outputs
*/

@description('Commands and information to connect to the deployed cluster.')
output clusterConnection object = {
  arcClusterName: edgeCncfCluster.outputs.connectedClusterName
  arcClusterResourceGroup: cloudResourceGroup.outputs.resourceGroupName
  arcProxyCommand: edgeCncfCluster.outputs.azureArcProxyCommand
}

/*
  Container Registry Outputs
*/

@description('Azure Container Registry resources.')
output containerRegistry object = {
  id: cloudAcr.outputs.acrId
  name: cloudAcr.outputs.acrName
}

@description('Azure Container Registry network posture metadata.')
output acrNetworkPosture object = {
  isNatGatewayEnabled: cloudAcr.outputs.isNatGatewayEnabled
}

@description('Azure Kubernetes Service resources.')
output kubernetes object? = shouldCreateAks
  ? {
      id: cloudKubernetes.outputs.?aksId
      name: cloudKubernetes.outputs.?aksName
      principalId: cloudKubernetes.outputs.?aksPrincipalId
    }
  : null

/*
  Data Storage Outputs
*/

@description('Data storage resources.')
output dataStorage object = {
  schemaRegistryName: cloudData.outputs.schemaRegistryName
  storageAccountName: cloudData.outputs.storageAccountName
}

/*
  Deployment Summary Outputs
*/

@description('Summary of the deployment configuration.')
output deploymentSummary object = {
  resourceGroup: cloudResourceGroup.outputs.resourceGroupName
}

/*
  Messaging Outputs
*/

@description('Cloud messaging resources.')
output messaging object = {
  eventGridTopicEndpoint: cloudMessaging.outputs.eventGridMqttEndpoint != ''
    ? cloudMessaging.outputs.eventGridMqttEndpoint
    : 'Not deployed'
  eventGridTopicName: cloudMessaging.outputs.eventGridTopicNames != ''
    ? cloudMessaging.outputs.eventGridTopicNames
    : 'Not deployed'
  eventhubName: length(cloudMessaging.outputs.eventHubNames) > 0
    ? cloudMessaging.outputs.eventHubNames[0]
    : 'Not deployed'
  eventhubNamespaceName: cloudMessaging.outputs.eventHubNamespaceName != ''
    ? cloudMessaging.outputs.eventHubNamespaceName
    : 'Not deployed'
}

@description('Alert notification pipeline resources.')
output notification object = {
  logicApp: shouldDeployNotification ? cloudNotification.?outputs.?logicApp ?? 'Not deployed' : 'Not deployed'
  closeLogicApp: shouldDeployNotification ? cloudNotification.?outputs.?closeLogicApp ?? 'Not deployed' : 'Not deployed'
  closeSessionEndpoint: shouldDeployNotification
    ? cloudNotification.?outputs.?closeSessionEndpoint ?? 'Not deployed'
    : 'Not deployed'
  storageAccount: shouldDeployNotification
    ? cloudNotification.?outputs.?storageAccount ?? 'Not deployed'
    : 'Not deployed'
}

@description('Map of dataflow graph resources by name.')
output dataflowGraphs string[] = edgeMessaging.outputs.dataflowGraphNames

@description('Map of dataflow resources by name.')
output dataflows string[] = edgeMessaging.outputs.dataflowNames

@description('Map of dataflow endpoint resources by name.')
output dataflowEndpoints string[] = edgeMessaging.outputs.dataflowEndpointNames

/*
  AI Foundry Outputs
*/

@description('Azure AI Foundry account resources.')
output aiFoundry object? = shouldDeployAiFoundry ? cloudAiFoundry.?outputs.?aiFoundry : null

@description('Azure AI Foundry project resources.')
output aiFoundryProjects array? = shouldDeployAiFoundry ? cloudAiFoundry.?outputs.?projectsArray : null

@description('Azure AI Foundry model deployments.')
output aiFoundryDeployments array? = shouldDeployAiFoundry ? cloudAiFoundry.?outputs.?deploymentsArray : null

/*
  Edge Infrastructure Outputs
*/

@description('Virtual machine host resources. (Empty when targeting pre-existing Arc machines)')
output vmHost array = [
  for i in range(0, shouldUseArcMachines ? 0 : hostMachineCount): {
    id: vmHostVmIds[i]
    location: common.location
    name: vmHostVmNames[i]
  }
]

@description('Azure Arc connected cluster resources.')
output arcConnectedCluster object = {
  name: edgeCncfCluster.outputs.connectedClusterName
  location: common.location
}

/*
  Observability Outputs
*/

@description('Monitoring and observability resources.')
output observability object = {
  azureMonitorWorkspaceName: cloudObservability.outputs.monitorWorkspaceName
  grafanaEndpoint: cloudObservability.outputs.grafanaEndpoint
  grafanaName: cloudObservability.outputs.grafanaName
  logAnalyticsWorkspaceName: cloudObservability.outputs.logAnalyticsName
}

/*
  Security and Identity Outputs
*/

@description('Security and identity resources.')
output securityIdentity object = {
  aioIdentity: cloudSecurityIdentity.outputs.aioIdentityName
  keyVaultName: cloudSecurityIdentity.outputs.?keyVaultName ?? 'Not deployed'
  keyVaultUri: cloudSecurityIdentity.outputs.?keyVaultName != null
    ? 'https://${cloudSecurityIdentity.outputs.?keyVaultName}${environment().suffixes.keyvaultDns}/'
    : 'Not deployed'
}

/*
  Networking Outputs
*/

@description('NAT gateway resource when managed outbound access is enabled.')
output natGateway object? = shouldEnableManagedOutboundAccess
  ? {
      id: cloudNetworking.outputs.?natGatewayId
      name: cloudNetworking.outputs.?natGatewayName
    }
  : null

@description('Public IP resources associated with the NAT gateway keyed by name.')
output natGatewayPublicIps array? = shouldEnableManagedOutboundAccess && cloudNetworking.outputs.?natGatewayPublicIps != null
  ? cloudNetworking.outputs.?natGatewayPublicIps
  : null

/*
  VPN Gateway Outputs
*/

@description('VPN Gateway configuration when enabled.')
output vpnGateway object? = shouldEnableVpnGateway
  ? {
      id: cloudVpnGateway.?outputs.?vpnGatewayId
      name: cloudVpnGateway.?outputs.?vpnGatewayName
    }
  : null

@description('VPN Gateway public IP address for client configuration.')
output vpnGatewayPublicIp string? = shouldEnableVpnGateway ? cloudVpnGateway.?outputs.?vpnGatewayPublicIp : null

@description('VPN client connection information including download URLs.')
output vpnClientConnectionInfo object? = shouldEnableVpnGateway ? cloudVpnGateway.?outputs.?clientConnectionInfo : null

@description('Private Resolver DNS IP address for VPN client configuration.')
output privateResolverDnsIp string? = cloudNetworking.outputs.?dnsServerIp

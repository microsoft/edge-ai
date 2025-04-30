metadata name = 'Full Single Cluster Blueprint'
metadata description = 'Deploys a complete end-to-end environment for Azure IoT Operations on a single-node, Arc-enabled Kubernetes cluster.'

import * as core from './types.core.bicep'
import * as iotOpsTypes from '../../../src/100-edge/110-iot-ops/bicep/types.bicep'

targetScope = 'subscription'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

@description('The name for the resource group. If not provided, a default name will be generated.')
param resourceGroupName string = 'rg-${common.resourcePrefix}-${common.environment}-${common.instance}'

/*
  Virtual Machine Parameters
*/

@secure()
@description('Password used for the host VM.')
param adminPassword string

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

// Currently disable setting shouldDeployAioDeploymentScripts, remove when DeploymentScripts supports AZ CLI 2.71+ (post May 4)
// @description('Whether or not to enable the Open Telemetry Collector for Azure IoT Operations.')
// param shouldEnableOtelCollector bool = true
var shouldEnableOtelCollector = false

// Currently disable setting shouldDeployAioDeploymentScripts, remove when DeploymentScripts supports AZ CLI 2.71+ (post May 4)
// @description('Whether or not to enable the OPC UA Simulator and deploy ADR Asset for Azure IoT Operations.')
// param shouldEnableOpcUaSimulator bool = true
var shouldEnableOpcUaSimulator = false

// Currently disable setting shouldDeployAioDeploymentScripts, remove when DeploymentScripts supports AZ CLI 2.71+ (post May 4)
// @description('Whether or not to enable the OPC UA Simulator Asset for Azure IoT Operations.')
// param shouldEnableOpcUaSimulatorAsset bool = true
var shouldEnableOpcUaSimulatorAsset = false

/*
  Modules
*/

module cloudResourceGroup '../../../src/000-cloud/000-resource-group/bicep/main.bicep' = {
  name: '${deployment().name}-crg0'
  params: {
    common: common
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
  }
}

module cloudVmHost '../../../src/000-cloud/050-vm-host/bicep/main.bicep' = {
  name: '${deployment().name}-cvh3'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [cloudResourceGroup]
  params: {
    common: common
    adminPassword: adminPassword
    arcOnboardingIdentityName: cloudSecurityIdentity.outputs.arcOnboardingIdentityName!
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
    shouldDeployAio: shouldDeployAio
    shouldCreateAnonymousBrokerListener: shouldCreateAnonymousBrokerListener
    shouldEnableOtelCollector: shouldEnableOtelCollector
    shouldEnableOpcUaSimulator: shouldEnableOpcUaSimulator
    shouldEnableOpcUaSimulatorAsset: shouldEnableOpcUaSimulatorAsset

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

/*
  Outputs
*/

@description('The name of the Arc-enabled Kubernetes cluster that was connected to Azure. This can be used to reference the cluster in other deployments.')
output arcConnectedClusterName string = edgeCncfCluster.outputs.connectedClusterName

@description('The administrative username that can be used to SSH into the deployed virtual machines.')
output vmUsername string = cloudVmHost.outputs.adminUsername

@description('An array containing the names of all virtual machines that were deployed as part of this blueprint.')
output vmNames array = cloudVmHost.outputs.vmNames

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

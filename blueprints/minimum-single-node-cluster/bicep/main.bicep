metadata name = 'Minimum Single Node Cluster Blueprint'
metadata description = 'Deploys the minimal set of resources required for Azure IoT Operations on a single-node, Arc-enabled Kubernetes cluster.'

import * as core from './types.core.bicep'

targetScope = 'subscription'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

@description('The name for the resource group. If not provided, a default name will be generated.')
param resourceGroupName string = 'rg-${common.resourcePrefix}-${common.environment}-${common.instance}'

@description('Whether to opt-out of telemetry. Set to true to disable telemetry.')
param telemetry_opt_out bool = false

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

@description('Whether to enable an insecure anonymous AIO MQ Broker Listener. (Should only be used for dev or test environments)')
param shouldCreateAnonymousBrokerListener bool = false

@description('Whether to deploy the Azure IoT Operations initial connected cluster resources, Secret Sync, ACSA, OSM, AIO Platform.')
param shouldInitAio bool = true

@description('Whether to deploy an Azure IoT Operations Instance and all of its required components into the connected cluster.')
param shouldDeployAio bool = true

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

module cloudResourceGroup '../../../src/000-cloud/000-resource-group/bicep/main.bicep' = {
  name: '${deployment().name}-crg0'
  params: {
    common: common
    tags: {
      blueprint: 'minimum-single-cluster'
    }
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

module cloudData '../../../src/000-cloud/030-data/bicep/main.bicep' = {
  name: '${deployment().name}-cd2'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [cloudResourceGroup]
  params: {
    common: common
    // Minimize resource usage
    storageAccountSettings: {
      tier: 'Standard'
      replicationType: 'LRS'
    }
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
    // Minimize resource usage - set smaller VM size
    vmSkuSize: 'Standard_D4s_v3'
    // Only create a single VM
    vmCount: 1
  }
}

module edgeCncfCluster '../../../src/100-edge/100-cncf-cluster/bicep/main.bicep' = {
  name: '${deployment().name}-ecc4'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [cloudResourceGroup]
  params: {
    arcOnboardingIdentityName: cloudSecurityIdentity.outputs.arcOnboardingIdentityName!
    clusterServerVirtualMachineName: cloudVmHost.outputs.vmNames[0]
    // No additional nodes for single node cluster
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

    // Minimize resource usage
    shouldEnableOpcUaSimulator: false
    shouldEnableOpcUaSimulatorAsset: false
    shouldEnableOtelCollector: false

    // Trust Configuration Parameters - use self-signed for simplicity
    trustIssuerSettings: { trustSource: 'SelfSigned' }

    // Secret Sync and Key Vault Parameters
    sseIdentityName: cloudSecurityIdentity.outputs.sseIdentityName
    sseKeyVaultName: cloudSecurityIdentity.outputs.keyVaultName!

    // Deployment Identity and Script Parameters - disable deployment scripts to minimize resources
    shouldDeployAioDeploymentScripts: false
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

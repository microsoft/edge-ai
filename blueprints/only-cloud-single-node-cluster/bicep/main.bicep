metadata name = 'Full Cloud Single Cluster Blueprint'
metadata description = 'Deploys a complete end-to-end cloud environment as preparation for Azure IoT Operations on a single-node.'

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
  name: '${deployment().name}-co2'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [cloudResourceGroup]
  params: {
    common: common
  }
}

module cloudData '../../../src/000-cloud/030-data/bicep/main.bicep' = {
  name: '${deployment().name}-cd3'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [cloudResourceGroup]
  params: {
    common: common
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
  name: '${deployment().name}-cvn3'
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

/*
  Outputs
*/

@description('The VM username for SSH access.')
output vmUsername string = cloudVmHost.outputs.adminUsername

@description('The names of all virtual machines deployed.')
output vmNames array = cloudVmHost.outputs.vmNames

@description('The AKS cluster name.')
output aksName string? = cloudKubernetes.outputs.?aksName

@description('The Azure Container Registry name.')
output acrName string = cloudAcr.outputs.acrName

@description('The name of the Secret Store Extension Key Vault.')
output keyVaultName string = cloudSecurityIdentity.outputs.keyVaultName!

@description('The Secret Store Extension User Assigned Managed Identity name.')
output sseIdentityName string = cloudSecurityIdentity.outputs.sseIdentityName

@description('The Azure IoT Operations User Assigned Managed Identity name.')
output aioIdentityName string = cloudSecurityIdentity.outputs.aioIdentityName

@description('The Deployment User Assigned Managed Identity name.')
output deployIdentityName string = cloudSecurityIdentity.outputs.deployIdentityName

@description('The User Assigned Managed Identity name with "Kubernetes Cluster - Azure Arc Onboarding" permissions.')
output arcOnboardingIdentityName string? = cloudSecurityIdentity.outputs.?arcOnboardingIdentityName

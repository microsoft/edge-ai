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

/*
  Virtual Machine Parameters
*/

@secure()
@description('Password used for the host VM.')
param adminPassword string

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

module cloudVmHost '../../../src/000-cloud/050-vm-host/bicep/main.bicep' = {
  name: '${deployment().name}-cvh5'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [cloudResourceGroup]
  params: {
    common: common
    adminPassword: adminPassword
    arcOnboardingIdentityName: cloudSecurityIdentity.outputs.arcOnboardingIdentityName!
  }
}

/*
  Outputs
*/

@description('The VM username for SSH access.')
output vmUsername string = cloudVmHost.outputs.adminUsername

@description('The names of all virtual machines deployed.')
output vmNames array = cloudVmHost.outputs.vmNames

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

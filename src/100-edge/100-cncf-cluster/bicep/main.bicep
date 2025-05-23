metadata name = 'CNCF Cluster Component'
metadata description = '''This module provisions and deploys automation scripts to a VM host that create and configure a K3s Kubernetes cluster with Arc connectivity.
The scripts handle primary and secondary node(s) setup, cluster administration, workload identity enablement, and installation of required Azure Arc extensions.'''

import * as core from './types.core.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

/*
  Azure Arc Parameters
*/

@description('The resource name for the Arc connected cluster.')
param arcConnectedClusterName string = 'arck-${common.resourcePrefix}-${common.environment}-${common.instance}'

@description('Service Principal Client ID with Kubernetes Cluster - Azure Arc Onboarding permissions.')
param arcOnboardingSpClientId string?

@description('The Service Principal Client Secret for Arc onboarding.')
@secure()
param arcOnboardingSpClientSecret string?

@description('Service Principal Object Id used when assigning roles for Arc onboarding.')
param arcOnboardingSpPrincipalId string?

@description('The resource name for the identity used for Arc onboarding.')
param arcOnboardingIdentityName string?

/*
  Arc Configuration Parameters
*/

@description('''
The object id of the Custom Locations Entra ID application for your tenant.
Can be retrieved using:

  ```sh
  az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv
  ```
''')
param customLocationsOid string

@description('Whether to add the current user as a cluster admin.')
param shouldAddCurrentUserClusterAdmin bool = true

@description('Whether to enable auto-upgrade for Azure Arc agents.')
param shouldEnableArcAutoUpgrade bool = common.environment != 'prod'

/*
  Cluster Parameters
*/

@description('The Object ID that will be given cluster-admin permissions.')
param clusterAdminOid string?

@description('The node virtual machines names.')
param clusterNodeVirtualMachineNames string[]?

@description('The server virtual machines name.')
@minLength(3)
param clusterServerVirtualMachineName string?

@description('Username used for the host machines that will be given kube-config settings on setup. (Otherwise, resource_prefix if it exists as a user)')
param clusterServerHostMachineUsername string = common.resourcePrefix

@description('The IP address for the server for the cluster. (Needed for mult-node cluster)')
param clusterServerIp string?

@description('The token that will be given to the server for the cluster or used by agent nodes.')
@secure()
param serverToken string?

/*
  Deployment Configuration Parameters
*/

@description('Whether to assign roles for Arc Onboarding.')
param shouldAssignRoles bool = true

@description('Whether to deploy the scripts to the VM.')
param shouldDeployScriptToVm bool = true

@description('Should skip downloading and installing Azure CLI on the server.')
param shouldSkipInstallingAzCli bool = false

@description('Should skip login process with Azure CLI on the server.')
param shouldSkipAzCliLogin bool = false

/*
  Key Vault Parameters
*/

@description('The name for the deploy user token secret in Key Vault.')
param deployUserTokenSecretName string = 'deploy-user-token'

@description('The name of the Key Vault that will have scripts and secrets for deployment.')
param deployKeyVaultName string

@description('The resource group name where the Key Vault is located. Defaults to the current resource group.')
param deployKeyVaultResourceGroupName string = resourceGroup().name

@description('The name for the K3s token secret in Key Vault.')
param k3sTokenSecretName string = 'k3s-server-token'

@description('The name for the node script secret in Key Vault.')
param nodeScriptSecretName string = 'cluster-node-ubuntu-k3s'

@description('The name for the server script secret in Key Vault.')
param serverScriptSecretName string = 'cluster-server-ubuntu-k3s'

@description('Whether to opt out of telemetry data collection.')
param telemetry_opt_out bool = false

/*
  Variables
*/

var arcOnboardingPrincipalId = arcOnboardingIdentity.?properties.principalId ?? arcOnboardingSpPrincipalId ?? fail('Either arcOnboardingIdentityName or arcOnboardingSpPrincipalId is required')

var clusterServerScriptSecretName = ubuntuK3s.outputs.clusterServerScriptSecretName
var clusterNodeScriptSecretName = ubuntuK3s.outputs.clusterNodeScriptSecretName

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

resource arcOnboardingIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' existing = if (!empty(arcOnboardingIdentityName)) {
  name: arcOnboardingIdentityName!
}

/*
  Modules
*/

module ubuntuK3s './modules/ubuntu-k3s.bicep' = {
  name: '${deployment().name}-uk0'
  scope: resourceGroup(deployKeyVaultResourceGroupName)
  params: {
    common: common
    arcResourceName: arcConnectedClusterName
    arcTenantId: tenant().tenantId
    clusterAdminOid: clusterAdminOid ?? (shouldAddCurrentUserClusterAdmin ? deployer().objectId : null)
    customLocationsOid: customLocationsOid
    shouldEnableArcAutoUpgrade: shouldEnableArcAutoUpgrade
    arcOnboardingSpClientId: arcOnboardingSpClientId
    arcOnboardingSpClientSecret: arcOnboardingSpClientSecret
    clusterServerIp: clusterServerIp ?? ''
    shouldSkipAzCliLogin: shouldSkipAzCliLogin
    shouldSkipInstallingAzCli: shouldSkipInstallingAzCli
    clusterServerHostMachineUsername: clusterServerHostMachineUsername
    keyVaultName: deployKeyVaultName
    serverScriptSecretName: serverScriptSecretName
    nodeScriptSecretName: nodeScriptSecretName
    k3sTokenSecretName: k3sTokenSecretName
    deployUserTokenSecretName: deployUserTokenSecretName
    serverToken: serverToken
  }
}

/*
  Role Assignments
*/

module roleAssignment './modules/arc-onboarding-role-assignment.bicep' = if (shouldAssignRoles) {
  name: '${deployment().name}-ra1'
  params: {
    arcOnboardingPrincipalId: arcOnboardingPrincipalId
  }
}

module keyVaultRoleAssignments './modules/key-vault-role-assignment.bicep' = if (shouldAssignRoles) {
  name: '${deployment().name}-ra2'
  scope: resourceGroup(deployKeyVaultResourceGroupName)
  params: {
    keyVaultName: deployKeyVaultName
    arcOnboardingPrincipalId: arcOnboardingPrincipalId
    serverScriptSecretName: clusterServerScriptSecretName
    nodeScriptSecretName: clusterNodeScriptSecretName
  }
}

/*
  Deploy Script
*/

module deployScriptsToVm './modules/deploy-scripts-to-vm.bicep' = if (shouldDeployScriptToVm) {
  name: '${deployment().name}-ds3'
  dependsOn: [
    roleAssignment
    keyVaultRoleAssignments
  ]
  params: {
    common: common
    clusterServerVirtualMachineName: clusterServerVirtualMachineName ?? fail('At least "clusterServerVirtualMachineName" required when "shouldDeployScriptToVm" is true')
    clusterNodeVirtualMachineNames: clusterNodeVirtualMachineNames ?? []
    clusterServerScript: ubuntuK3s.outputs.clusterServerScript
    clusterNodeScript: ubuntuK3s.outputs.clusterNodeScript
  }
}

/*
  Outputs
*/

@description('The connected cluster name')
output connectedClusterName string = arcConnectedClusterName

@description('The connected cluster resource group name')
output connectedClusterResourceGroupName string = resourceGroup().name

@description('Azure Arc proxy command for accessing the cluster')
output azureArcProxyCommand string = 'az connectedk8s proxy -n ${arcConnectedClusterName} -g ${resourceGroup().name}'

@description('The name of the Key Vault secret containing the server script')
output clusterServerScriptSecretName string = clusterServerScriptSecretName

@description('The name of the Key Vault secret containing the node script')
output clusterNodeScriptSecretName string = clusterNodeScriptSecretName

@description('The AZ CLI command to get the cluster server script from Key Vault')
output clusterServerScriptSecretShowCommand string = 'az keyvault secret show --name "${clusterServerScriptSecretName}" --vault-name "${deployKeyVaultName}" --query "value" -o tsv > ${clusterServerScriptSecretName}.sh && chmod +x ${clusterServerScriptSecretName}.sh'

@description('The AZ CLI command to get the cluster node script from Key Vault')
output clusterNodeScriptSecretShowCommand string = 'az keyvault secret show --name "${clusterNodeScriptSecretName}" --vault-name "${deployKeyVaultName}" --query "value" -o tsv > ${clusterNodeScriptSecretName}.sh && chmod +x ${clusterNodeScriptSecretName}.sh'

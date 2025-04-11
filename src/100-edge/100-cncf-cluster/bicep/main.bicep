metadata name = 'CNCF Cluster Component'
metadata description = '''Sets up and deploys a script to a VM host that will setup the K3S cluster and optionally cluster nodes,
Arc connect the cluster, Add cluster admins to the cluster, enable workload identity, install extensions for cluster connect and custom locations.'''

extension microsoftGraphV1

import * as core from './types.core.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

/*
  Key Vault Parameters
*/

@description('The name of the Key Vault to save the scripts to.')
param keyVaultName string

@description('The resource group name where the Key Vault is located. Defaults to the current resource group.')
param keyVaultResourceGroupName string = resourceGroup().name

/*
  Cluster Parameters
*/

@description('The resource name for the Arc connected cluster.')
param arcConnectedClusterName string = 'arck-${common.resourcePrefix}-${common.environment}-${common.instance}'

@description('The server virtual machines name.')
@minLength(3)
param clusterServerVirtualMachineName string?

@description('The node virtual machines names.')
param clusterNodeVirtualMachineNames string[]?

@description('Username used for the host machines that will be given kube-config settings on setup. (Otherwise, resource_prefix if it exists as a user)')
param clusterServerHostMachineUsername string = common.resourcePrefix

@description('The IP address for the server for the cluster. (Needed for mult-node cluster)')
param clusterServerIp string?

@description('The token that will be given to the server for the cluster or used by agent nodes.')
param serverToken string?

@description('The Object ID that will be given cluster-admin permissions.')
param clusterAdminOid string?

/*
  Azure Arc Parameters
*/

@description('''
The object id of the Custom Locations Entra ID application for your tenant.
If none is provided, the script will attempt to retrieve this requiring 'Application.Read.All' or 'Directory.Read.All' permissions.
Can be retrieved using:

  ```sh
  az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv
  ```
''')
param customLocationsOid string?

@description('Whether to get Custom Locations Object ID using Azure APIs.')
param shouldGetCustomLocationsOid bool = true

@description('Whether to assign roles for Arc Onboarding.')
param shouldAssignRoles bool = true

@description('Service Principal Object Id used when assigning roles for Arc onboarding.')
param arcOnboardingSpPrincipalId string?

@description('Service Principal Client ID with Kubernetes Cluster - Azure Arc Onboarding permissions.')
param arcOnboardingSpClientId string?

@description('The Service Principal Client Secret for Arc onboarding.')
@secure()
param arcOnboardingSpClientSecret string?

@description('The resource name for the identity used for Arc onboarding.')
param arcOnboardingIdentityName string?

/*
  Arc Configuration Parameters
*/

@description('Whether to add the current user as a cluster admin.')
param shouldAddCurrentUserClusterAdmin bool = true

@description('Whether to enable auto-upgrade for Azure Arc agents.')
param shouldEnableArcAutoUpgrade bool = common.environment != 'prod'

/*
  Deployment Configuration Parameters
*/

@description('Whether to deploy the scripts to the VM.')
param shouldDeployScriptToVm bool = true

@description('Should generate token used by the server.')
param shouldGenerateServerToken bool = false

@description('Should skip login process with Azure CLI on the server.')
param shouldSkipAzCliLogin bool = false

@description('Should skip downloading and installing Azure CLI on the server.')
param shouldSkipInstallingAzCli bool = false

/*
  Variables
*/

var arcOnboardingPrincipalId = arcOnboardingIdentity.?properties.principalId ?? arcOnboardingSpPrincipalId ?? fail('Either arcOnboardingIdentityName or arcOnboardingSpPrincipalId is required')

// Get the token value either from the generated token or the provided parameter
// This is not optimal, but customer can provide their own token via parameter
var clusterServerToken = serverToken ?? (shouldGenerateServerToken
  ? substring('${uniqueString(clusterServerVirtualMachineName ?? 'dev')}-${uniqueString(resourceGroup().id)}', 0, 24)
  : null)

var clusterServerScriptSecretName = ubuntuK3s.outputs.clusterServerScriptSecretName
var clusterNodeScriptSecretName = ubuntuK3s.outputs.clusterNodeScriptSecretName

/*
  Resources
*/

resource arcOnboardingIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' existing = if (!empty(arcOnboardingIdentityName)) {
  name: arcOnboardingIdentityName!
}

resource customLocationsServicePrincipal 'Microsoft.Graph/servicePrincipals@v1.0' existing = if (shouldGetCustomLocationsOid && empty(customLocationsOid)) {
  // The service principal for Custom Locations in tenant
  appId: 'bc313c14-388c-4e7d-a58e-70017303ee3b' // gitleaks:allow
}

/*
  Modules
*/

module ubuntuK3s './modules/ubuntu-k3s.bicep' = {
  name: '${deployment()}-ubuntuK3s'
  scope: resourceGroup(keyVaultResourceGroupName)
  params: {
    common: common
    arcResourceName: arcConnectedClusterName
    arcTenantId: tenant().tenantId
    clusterAdminOid: clusterAdminOid ?? (shouldAddCurrentUserClusterAdmin ? deployer().objectId : null)
    customLocationsOid: customLocationsOid ?? customLocationsServicePrincipal.?id
    shouldEnableArcAutoUpgrade: shouldEnableArcAutoUpgrade
    arcOnboardingSpClientId: arcOnboardingSpClientId
    arcOnboardingSpClientSecret: arcOnboardingSpClientSecret
    clusterServerIp: clusterServerIp ?? ''
    clusterServerToken: clusterServerToken
    shouldSkipAzCliLogin: shouldSkipAzCliLogin
    shouldSkipInstallingAzCli: shouldSkipInstallingAzCli
    clusterServerHostMachineUsername: clusterServerHostMachineUsername
    keyVaultName: keyVaultName
  }
}

/*
  Role Assignments
*/

module roleAssignment './modules/arc-onboarding-role-assignment.bicep' = if (shouldAssignRoles) {
  name: '${deployment()}-arcOnboardingRoleAssignment'
  params: {
    arcOnboardingPrincipalId: arcOnboardingPrincipalId
  }
}

module keyVaultRoleAssignments './modules/key-vault-role-assignment.bicep' = if (shouldAssignRoles) {
  name: '${deployment().name}-keyVaultRoleAssignments'
  scope: resourceGroup(keyVaultResourceGroupName)
  params: {
    keyVaultName: keyVaultName
    arcOnboardingPrincipalId: arcOnboardingPrincipalId
    serverScriptSecretName: clusterServerScriptSecretName
    nodeScriptSecretName: clusterNodeScriptSecretName
  }
}

/*
  Deploy Script
*/

module deployScriptsToVm './modules/deploy-scripts-to-vm.bicep' = if (shouldDeployScriptToVm) {
  name: '${deployment().name}-deployScriptsToVm'
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
output clusterServerScriptSecretShowCommand string = 'az keyvault secret show --name "${clusterServerScriptSecretName}" --vault-name "${keyVaultName}" --query "value" -o tsv > ${clusterServerScriptSecretName}.sh && chmod +x ${clusterServerScriptSecretName}.sh'

@description('The AZ CLI command to get the cluster node script from Key Vault')
output clusterNodeScriptSecretShowCommand string = 'az keyvault secret show --name "${clusterNodeScriptSecretName}" --vault-name "${keyVaultName}" --query "value" -o tsv > ${clusterNodeScriptSecretName}.sh && chmod +x ${clusterNodeScriptSecretName}.sh'

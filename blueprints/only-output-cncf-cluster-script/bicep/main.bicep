metadata name = 'Only Output CNCF Cluster Script Blueprint'
metadata description = 'Generates scripts for Azure IoT Operations CNCF cluster creation without deploying resources.'

import * as core from './types.core.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

@description('Whether to opt-out of telemetry. Set to true to disable telemetry.')
param telemetry_opt_out bool = false

/*
  Azure Arc Parameters
*/

@description('The resource name for the Arc connected cluster.')
param arcConnectedClusterName string = 'arck-${common.resourcePrefix}-${common.environment}-${common.instance}'

@description('The resource name for the identity used for Arc onboarding.')
param arcOnboardingIdentityName string = 'id-${common.resourcePrefix}-arc-${common.environment}-${common.instance}'

@description('Service Principal Client ID with Kubernetes Cluster - Azure Arc Onboarding permissions.')
param arcOnboardingSpClientId string?

@description('The Service Principal Client Secret for Arc onboarding.')
@secure()
param arcOnboardingSpClientSecret string?

@description('Service Principal Object Id used when assigning roles for Arc onboarding.')
param arcOnboardingSpPrincipalId string?

@description('''
The object id of the Custom Locations Entra ID application for your tenant.
Can be retrieved using:

  ```sh
  az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv
  ```
''')
param customLocationsOid string

@description('Whether to enable auto-upgrade for Azure Arc agents.')
param shouldEnableArcAutoUpgrade bool = common.environment != 'prod'

@description('Whether to assign roles for Arc Onboarding.')
param shouldAssignRoles bool = true

/*
  Cluster Configuration Parameters
*/

@description('The Object ID that will be given cluster-admin permissions.')
param clusterAdminOid string?

@description('The User Principal Name that will be given cluster-admin permissions.')
param clusterAdminUpn string?

@description('The names of the VMs for the cluster nodes. (Only needed if wanting this blueprint to deploy the scripts)')
param clusterNodeVirtualMachineNames string[]?

@description('The IP address for the server for the cluster. (Needed for multi-node cluster)')
param clusterServerIp string?

@description('Username used for the host machines that will be given kube-config settings on setup.')
param clusterServerHostMachineUsername string = common.resourcePrefix

@description('The name of the VM for the cluster server. (Only needed if wanting this blueprint to deploy the scripts)')
param clusterServerVirtualMachineName string?

@description('The token that will be given to the server for the cluster or used by agent nodes.')
@secure()
param serverToken string?

@description('Whether to add the current user as a cluster admin.')
param shouldAddCurrentUserClusterAdmin bool = true

/*
  Key Vault Parameters
*/

@description('The name for the deploy user token secret in Key Vault.')
param deployUserTokenSecretName string = 'deploy-user-token'

@description('The name for the K3s token secret in Key Vault.')
param k3sTokenSecretName string = 'k3s-server-token'

@description('The name of the Key Vault to save the scripts to.')
param keyVaultName string = 'kv-${common.resourcePrefix}-${common.environment}-${common.instance}'

@description('The resource group name where the Key Vault is located. Defaults to the current resource group.')
param keyVaultResourceGroupName string = resourceGroup().name

@description('The name for the node script secret in Key Vault.')
param nodeScriptSecretName string = 'cluster-node-ubuntu-k3s'

@description('The name for the server script secret in Key Vault.')
param serverScriptSecretName string = 'cluster-server-ubuntu-k3s'

/*
  Script Deploy Parameters
*/

@description('Whether to deploy the scripts to the VMs. (Only needed if wanting this blueprint to deploy the scripts)')
param shouldDeployScriptToVm bool = false

@description('Should skip login process with Azure CLI on the server.')
param shouldSkipAzCliLogin bool = false

@description('Should skip downloading and installing Azure CLI on the server.')
param shouldSkipInstallingAzCli bool = false

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

module edgeCncfCluster '../../../src/100-edge/100-cncf-cluster/bicep/main.bicep' = {
  name: '${deployment().name}-ecc0'
  params: {
    common: common

    // Azure Arc Parameters
    arcConnectedClusterName: arcConnectedClusterName
    arcOnboardingIdentityName: arcOnboardingIdentityName
    arcOnboardingSpClientId: arcOnboardingSpClientId
    arcOnboardingSpClientSecret: arcOnboardingSpClientSecret
    arcOnboardingSpPrincipalId: arcOnboardingSpPrincipalId
    customLocationsOid: customLocationsOid
    shouldAssignRoles: shouldAssignRoles
    shouldEnableArcAutoUpgrade: shouldEnableArcAutoUpgrade

    // Cluster Configuration Parameters
    clusterAdminOid: clusterAdminOid
    clusterAdminUpn: clusterAdminUpn
    clusterNodeVirtualMachineNames: clusterNodeVirtualMachineNames
    clusterServerHostMachineUsername: clusterServerHostMachineUsername
    clusterServerIp: clusterServerIp
    clusterServerVirtualMachineName: clusterServerVirtualMachineName
    serverToken: serverToken
    shouldAddCurrentUserClusterAdmin: shouldAddCurrentUserClusterAdmin

    // Key Vault Parameters
    deployKeyVaultName: keyVaultName
    deployKeyVaultResourceGroupName: keyVaultResourceGroupName
    deployUserTokenSecretName: deployUserTokenSecretName
    k3sTokenSecretName: k3sTokenSecretName
    nodeScriptSecretName: nodeScriptSecretName
    serverScriptSecretName: serverScriptSecretName

    // Script Deploy Parameters
    shouldDeployScriptToVm: shouldDeployScriptToVm
    shouldSkipAzCliLogin: shouldSkipAzCliLogin
    shouldSkipInstallingAzCli: shouldSkipInstallingAzCli
  }
}

/*
  Outputs
*/

@description('The connected cluster name')
output connectedClusterName string = edgeCncfCluster.outputs.connectedClusterName

@description('The connected cluster resource group name')
output connectedClusterResourceGroupName string = edgeCncfCluster.outputs.connectedClusterResourceGroupName

@description('Azure Arc proxy command for accessing the cluster')
output azureArcProxyCommand string = edgeCncfCluster.outputs.azureArcProxyCommand

@description('The name of the Key Vault secret containing the server script')
output clusterServerScriptSecretName string = edgeCncfCluster.outputs.clusterServerScriptSecretName

@description('The name of the Key Vault secret containing the node script')
output clusterNodeScriptSecretName string = edgeCncfCluster.outputs.clusterNodeScriptSecretName

@description('The AZ CLI command to get the cluster server script from Key Vault')
output clusterServerScriptSecretShowCommand string = edgeCncfCluster.outputs.clusterServerScriptSecretShowCommand

@description('The AZ CLI command to get the cluster node script from Key Vault')
output clusterNodeScriptSecretShowCommand string = edgeCncfCluster.outputs.clusterNodeScriptSecretShowCommand
